{
  config,
  lib,
  provisionSchemas ? config.modules.nixos.services.security.vault.provision,
  ...
}:

let
  cfg = config.modules.nixos.services.security.vault;
  domains = rec {
    root = config.modules.nixos.services.traefik.internalDomain;
    subdomain = "${cfg.subdomain}.${root}";
  };

  mkOAuthApp =
    appName: appCfg:
    let
      clientSecretKey = "${appName}_secret_key";
    in
    {
      resource = {
        random_password = {
          "${clientSecretKey}" = {
            length = 32;
            special = false;
          };
        };

        authentik_provider_oauth2 = {
          "${appName}" = {
            name = appName;
            client_id = appName;
            redirect_uris = appCfg.oauth.redirect_uris;
          };
        };

        authentik_application = {
          "${appName}" = {
            name = appCfg.oauth.name or appName;
            slug = appName;
            protocol_provider = "\${authentik_provider_oauth2.${appName}.id}";
          };
        };

        vault_kv_secret_v2 = {
          "${appName}" = {
            mount = "secret";
            name = "data/${appName}";
            data_json = builtins.toJSON {
              client_id = "\${authentik_provider_oauth2.${appName}.client_id}";
              client_secret = "\${authentik_provider_oauth2.${appName}.client_secret}";
              secret_key = "\${random_password.${clientSecretKey}.result}";
            };
          };
        };
      };
    };

  oauthApps = lib.foldl' lib.recursiveUpdate { } [
    (mkOAuthApp {
      appName = "grafana";
      slug = "grafana";
      redirectUris = [ "https://vet.cage.${domains.root}/login/generic_oauth" ];
    })
  ];

  basePki = {
    terraform.required_providers = {
      vault = {
        source = "hashicorp/vault";
        version = ">= 3.0.0";
      };
      authentik = {
        source = "goauthentik/authentik";
        version = ">= 2024.1.0";
      };
      random = {
        source = "hashicorp/random";
        version = ">= 3.0.0";
      };
    };

    data = {
      vault_kv_secret_v2 = {
        authentik_bootstrap = {
          mount = "secret";
          name = "data/authentik/bootstrap";
        };
      };
    };

    provider = {
      vault = {
        address = "https://${domains.subdomain}";
        ca_cert_file = "/var/lib/vault/tls/ca.crt";

        client_auth = {
          cert_file = "/var/lib/vault/tls/node.crt";
          key_file = "/var/lib/vault/tls/node.key";
        };
      };

      authentik = {
        url = "https://noseprint.${domains.root}";
        token = "\${data.vault_kv_secret_v2.authentik_bootstrap.data[\"bootstrap_token\"]}";
      };
    };

    resource = lib.foldl' lib.recursiveUpdate { } [
      {
        vault_mount.pki_devices = {
          path = "pki/devices";
          type = "pki";
          description = "PKI for TPM-bound device certificates";
          max_lease_ttl_seconds = 31536000;
        };

        vault_pki_secret_backend_root_cert.pki_devices_root = {
          backend = "pki/devices";
          type = "internal";
          common_name = "devices-ca";
          ttl = "87600h";
        };

        vault_pki_secret_backend_role.pki_devices_node_role = {
          backend = "pki/devices";
          name = "node";
          allowed_organizational_units = [ "TPM-BOUND" ];
          key_type = "rsa";
          key_bits = 2048;
          max_ttl = "876h";
          allow_any_name = true;
          require_cn = false;
          require_sans = true;
          allowed_other_sans = [
            "1.3.6.1.4.1.311.25.1:*"
            "1.3.6.1.4.1.311.25.2:*"
          ];
        };

        # Wrap block definitions properly inside the auth backend type
        vault_auth_backend.cert = {
          type = "cert";
          path = "cert";
        };

        vault_cert_auth_backend_role.devices = {
          name = "devices";
          backend = "cert";
          certificate = "\${vault_pki_secret_backend_root_cert.pki_devices_root.certificate}";
          allowed_organizational_units = [ "TPM-BOUND" ];
          token_policies = [ "device-bootstrap" ];
          token_ttl = "1h";
          token_max_ttl = "24h";
        };

        vault_pki_secret_backend_config_urls.devices = {
          backend = "pki";
          issuing_certificates = [ "http://${domains.subdomain}:8200/v1/pki/ca" ];
          crl_distribution_points = [ "http://${domains.subdomain}:8200/v1/pki/crl" ];
          ocsp_servers = [ "http://${domains.subdomain}:8200/v1/pki/ocsp" ];
        };
      }
      oauthApps
    ];
  };

  mkAppModule = appName: appCfg: {
    resource = lib.foldl' lib.recursiveUpdate { } [
      # Fix policies: resource.vault_policy.<name>
      (lib.mapAttrs' (
        name: policy:
        lib.nameValuePair "vault_policy" {
          ${name} = { inherit name policy; };
        }
      ) (appCfg.policy or { }))

      # Fix KV secrets: resource.vault_kv_secret_v2.<name>
      (lib.concatMapAttrs (
        ns: secrets:
        lib.mapAttrs' (
          name: data:
          lib.nameValuePair "vault_kv_secret_v2" {
            "kv_${ns}_${name}" = {
              mount = "secret";
              name = "data/${ns}/${name}";
              data_json = builtins.toJSON data;
            };
          }
        ) secrets
      ) (appCfg.vault.kv or { }))

      # Fix AppRole and Bootstrap secrets
      (
        let
          roleName = "app-${appName}";
        in
        {
          vault_approle_auth_backend_role = {
            "${roleName}" = {
              backend = "approle";
              role_name = roleName;
              token_policies = appCfg.vault.approle.policies or [ ];
              token_ttl = "1h";
              token_max_ttl = "24h";
            };
          };
          vault_approle_auth_backend_role_secret_id = {
            "${roleName}" = {
              backend = "approle";
              role_name = roleName;
            };
          };
        }
        // lib.optionalAttrs (appCfg.vault.approle.bootstrap or false) {
          vault_kv_secret_v2 = {
            "bootstrap_${roleName}" = {
              mount = "secret";
              name = "bootstrap/approles/${appName}";
              data_json = ''{"role_id": "${"\${vault_approle_auth_backend_role.${roleName}.role_id}"}", "secret_id": "${"\${vault_approle_auth_backend_role_secret_id.${roleName}.secret_id}"}"}'';
            };
          };
        }
      )
    ];
  };

  appModules = lib.mapAttrsToList mkAppModule provisionSchemas;
in
lib.foldl' lib.recursiveUpdate basePki appModules
