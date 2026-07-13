{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  sec = config.modules.nixos.services.security;
  cfg = sec.vault;

  terranix = inputs.terranix.lib;

  domains = rec {
    root = config.modules.nixos.services.traefik.internalDomain;
    subdomain = cfg.subdomain + "." + root;
  };

  mkDevicePki = {
    terraform.required_providers.vault = {
      source = "hashicorp/vault";
      version = ">= 3.0.0";
    };

    provider.vault = {
      address = "https://${domains.subdomain}";
      ca_cert_file = "/var/lib/vault/tls/ca.crt";

      token = ''$\{file ("/run/vault/device-token")}'';
    };

    resource = {
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
        max_ttl = "8760h";

        allow_any_name = true;
        require_cn = false;
        require_sans = true;

        allowed_other_sans = [
          "1.3.6.1.4.1.311.25.1:*" # serial
          "1.3.6.1.4.1.311.25.2:*" # uuid
        ];
      };

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

      vault_generic_endpoint.pcr_baseline = {
        path = "sys/policies/acl/pcr-attestation";
        data = {
          policy = ''
            path "pki/devices/issue/node" {
              capabilities = ["create", "update"]
              allowed_parameters = {
                "pcrs" = {
                  "sha256:0"  = "7CBAAAA7B0E1B04FFF5F58B01836CF8728CBC2B68597E1059319B07EC38704B8"
                  "sha256:1"  = "3D458CFE55CC03EA1F443F1562BEEC8DF51C75E14A9FCF9A7234A13F198E7969"
                  "sha256:2"  = "3D458CFE55CC03EA1F443F1562BEEC8DF51C75E14A9FCF9A7234A13F198E7969"
                  "sha256:3"  = "3D458CFE55CC03EA1F443F1562BEEC8DF51C75E14A9FCF9A7234A13F198E7969"
                  "sha256:4"  = "0865AB2031D364366F4EE8DBDBD47E9B8646D7567CE5C8567855658A26AEB336"
                  "sha256:5"  = "69F35728CD149CD235919789C636E3E2B8FDA4DFCA357531B33BECBFB7D8D3E8"
                  "sha256:7"  = "E0B8031726E68EDE1CFF65DA92479815C17D598CC7A800F7B0C2B9B152E4986E"
                }
              }
            }
          '';
        };
      };

      vault_policy.device_bootstrap = {
        name = "device-bootstrap";
        policy = ''
          path "secret/data/bootstrap/approles/*" {
            capabilities = ["read"]
          }
        '';
      };

      vault_auth_backend.approle = {
        type = "approle";
        path = "approle";
      };
    };
  };

  mkAppModule =
    appName: appCfg:
    let
      v = appCfg.vault or { };
      policies = appCfg.policy or { };

      mkPolicies = lib.mapAttrs (name: text: {
        resource.vault_policy.${name} = {
          name = name;
          policy = text;
        };
      }) policies;

      mkKv =
        kvTree:
        lib.concatMapAttrs (
          ns: nsCfg:
          lib.mapAttrs (name: data: {
            resource.vault_kv_secret_v2."kv_${ns}_${name}" = {
              mount = "secret";
              name = "data/${ns}/${name}";
              data_json = builtins.toJSON data;
            };
          }) nsCfg
        ) kvTree;

      mkTransit =
        transit:
        lib.mapAttrs (name: tcfg: {
          resource.vault_transit_secret_backend_key."transit_${name}" = {
            backend = "transit";
            name = name;
            type = tcfg.type or "rsa-2048";
          };
        }) transit;

      mkAppRole =
        aCfg:
        let
          roleName = "app-${appName}";
        in
        {
          resource.vault_approle_auth_backend_role.${roleName} = {
            backend = "approle";
            role_name = roleName;
            token_policies = aCfg.policies or [ ];
            token_ttl = "1h";
            token_max_ttl = "24h";
          };

          resource.vault_approle_auth_backend_role_secret_id.${roleName} = {
            backend = "approle";
            role_name = roleName;
          };

          resource.vault_kv_secret_v2."bootstrap_${roleName}" = lib.optionalAttrs (aCfg.bootstrap or false) {
            mount = "secret";
            name = "bootstrap/approles/${appName}";
            data_json = ''
              {
                "role_id": "${"\${vault_approle_auth_backend_role.${roleName}.role_id}"}",
                "secret_id": "${"\${vault_approle_auth_backend_role_secret_id.${roleName}.secret_id}"}"
              }
            '';
          };
        };
    in
    {
      resource = lib.foldl' lib.recursiveUpdate { } (
        (lib.attrValues (mkPolicies))
        ++ (lib.attrValues (mkKv (v.kv or { })))
        ++ (lib.attrValues (mkTransit (v.transit or { })))
        ++ (lib.attrValues (mkAppRole (v.approle or { })))
      );
    };

  appModules = lib.mapAttrs mkAppModule cfg.provision;

  terraform = (
    builtins.toFile "terraform" (
      builtins.toJSON (
        terranix.evalTerranixConfiguration {
          system = pkgs.stdenv.hostPlatform.system;
          modules = [
            mkDevicePki
          ]
          ++ (lib.attrValues appModules);
        }
      )
    )
  );

  openbao = pkgs.symlinkJoin {
    name = "openbao";
    paths = [
      (pkgs.writeShellScriptBin "bao" ''
        export VAULT_HSM_PIN=$(cat "$CREDENTIALS_DIRECTORY/vault-pin.cred")
        exec ${pkgs.openbao}/bin/bao "$@"
      '')
    ];
    postBuild = ''
      ln -s $out/bin/bao $out/bin/vault
    '';

    inherit (pkgs.openbao) version meta;
  };
in
{
  options.modules.nixos.services.security.vault = {
    enable = lib.mkEnableOption "Vault server";

    address = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default = config.modules.nixos.networking.containerInterfaces.vault.address;
    };

    port = lib.mkOption {
      type = lib.types.int;
      default = 8200;
    };

    subdomain = lib.mkOption {
      type = lib.types.str;
      default = "collar";
    };

    provision = lib.mkOption {
      type = lib.types.attrsOf lib.types.attrs;
      default = { };
      description = "Per-application Vault provisioning (policies, KV, transit, AppRoles, bootstrap).";
    };
  };

  config = lib.mkIf cfg.enable {
    modules.nixos.networking.containerInterfaces.vault = {
      zone = "cnt";
      id = 20;
      proxy = {
        enable = true;
        port = cfg.port;
        subdomain = cfg.subdomain;
        tls = true;
      };
    };

    security.tpm2.enable = true;

    containers.vault = {
      autoStart = true;

      forwardPorts = [
        {
          containerPort = cfg.port;
          hostPort = cfg.port;
          protocol = "tcp";
        }
      ];

      allowedDevices = [
        {
          node = "/dev/tpmrm0";
          modifier = "rwm";
        }
        {
          node = "/dev/tpm0";
          modifier = "rwm";
        }
      ];

      bindMounts."/dev/tpmrm0" = {
        hostPath = "/dev/tpmrm0";
        isReadOnly = false;
      };

      bindMounts."/dev/tpm0" = {
        hostPath = "/dev/tpm0";
        isReadOnly = false;
      };

      config = {
        imports = with inputs; [
          nix-topology.nixosModules.default
          systemd-vaultd.nixosModules.vaultAgent
          systemd-vaultd.nixosModules.systemdVaultd
        ];

        system.stateVersion = "26.05";

        security.tpm2.enable = true;
        security.tpm2.pkcs11.enable = true;
        security.tpm2.tctiEnvironment.enable = true;

        systemd.services.vault-hsm-bootstrap = {
          description = "Initialize Vault's HSM cryptographic material using TPM-backed secrets and PKCS#11";
          wantedBy = [ "multi-user.target" ];
          before = [ "vault.service" ];

          unitConfig.ConditionPathExists = "!/var/lib/vault/vault-pin.cred";

          script = ''
            set -euo pipefail
            umask 077

            mkdir -pm700 /var/lib/vault
            mkdir -pm700 /var/lib/vault/tls
            mkdir -pm700 /var/lib/vault/pkcs11

            openssl req -x509 -newkey rsa:3072 -nodes \
              -keyout /var/lib/vault/tls/ca.key \
              -out /var/lib/vault/tls/ca.crt \
              -subj "/CN=Vault-Local-CA" \
              -days 3650

            openssl req -new -newkey rsa:3072 -nodes \
              -keyout /var/lib/vault/tls/server.key \
              -out /var/lib/vault/tls/server.csr \
              -subj "/CN=${domains.subdomain}" \
              -addext "subjectAltName=DNS:${domains.subdomain}"

            openssl x509 -req \
              -in /var/lib/vault/tls/server.csr \
              -CA /var/lib/vault/tls/ca.crt \
              -CAkey /var/lib/vault/tls/ca.key \
              -CAcreateserial \
              -out /var/lib/vault/tls/server.crt \
              -days 825 \
              -extfile <(printf "subjectAltName=DNS:${domains.subdomain}\nkeyUsage=digitalSignature,keyEncipherment\nextendedKeyUsage=serverAuth")

            chmod 600 /var/lib/vault/tls/server.key /var/lib/vault/tls/ca.key
            chmod 644 /var/lib/vault/tls/server.crt /var/lib/vault/tls/ca.crt
            chown -R vault:vault /var/lib/vault/tls/*

            PIN="$(tpm2_getrandom 32 | base64 -w0)"
            printf '%s' "$PIN" > /var/lib/vault/vault-pin.raw

            systemd-creds encrypt \
              --name=vault-pin.cred \
              --tpm2-device=/dev/tpmrm0 \
              --tpm2-pcrs=0+1+2+3+4+5+7 \
              /var/lib/vault/vault-pin.raw \
              /var/lib/vault/vault-pin.cred

            rm /var/lib/vault/vault-pin.raw
            chmod 600 /var/lib/vault/vault-pin.cred
            chown vault:vault /var/lib/vault/vault-pin.cred

            tpm2_ptool init --path /var/lib/vault/pkcs11
            chown -R vault:vault /var/lib/vault/pkcs11

            SOPIN="$(tpm2_getrandom 16 | base64 -w0)"
            USERPIN="$(systemd-creds decrypt /var/lib/vault/vault-pin.cred)"

            tpm2_ptool addtoken \
              --pid 1 \
              --label vault \
              --sopin "$SOPIN" \
              --userpin "$USERPIN" \
              --path /var/lib/vault/pkcs11

            tpm2_ptool addkey \
              --algorithm rsa2048 \
              --label vault \
              --key-label vault-key \
              --userpin "$USERPIN" \
              --path /var/lib/vault/pkcs11

            tpm2_ptool addkey \
              --algorithm hmac:sha256 \
              --label vault \
              --key-label vault-hmac \
              --userpin "$USERPIN" \
              --path /var/lib/vault/pkcs11
          '';

          serviceConfig = {
            User = "root";
            Group = "root";

            DeviceAllow = [
              "/dev/tpm0 rw"
              "/dev/tpmrm0 rw"
            ];
            PrivateDevices = lib.mkForce false;
          };

          path = [
            pkgs.tpm2-tools
            pkgs.tpm2-pkcs11
            pkgs.openssl
            pkgs.systemd
            pkgs.coreutils
          ];
        };

        systemd.services.vault = {
          after = [ "vault-hsm-bootstrap.service" ];
          requires = [ "vault-hsm-bootstrap.service" ];

          serviceConfig = {
            LoadCredentialEncrypted = "vault-pin.cred:/var/lib/vault/vault-pin.cred";

            DeviceAllow = [
              "/dev/tpm0 rw"
              "/dev/tpmrm0 rw"
            ];
            PrivateDevices = lib.mkForce false;
          };

          environment = {
            VAULT_SEAL_TYPE = "pkcs11";
            VAULT_HSM_LIB = "${
              pkgs.tpm2-pkcs11-esapi.overrideAttrs (old: {
                patches = old.patches ++ [ ./tpm2-pkcs11-infineon-rsa-pss-saltlen.patch ];
              })
            }/lib/libtpm2_pkcs11.so";
            VAULT_HSM_SLOT = "1";
            VAULT_HSM_TOKEN_LABEL = "vault";
            VAULT_HSM_KEY_LABEL = "vault-key";
            VAULT_HSM_HMAC_KEY_LABEL = "vault-hmac";
            TPM2_PKCS11_STORE = "/var/lib/vault/pkcs11";
          };
        };

        users.groups.tss = {
          members = [ "vault" ];
        };

        services.vault = {
          enable = true;
          package = openbao;

          dev = false;

          address = "0.0.0.0:${toString cfg.port}";
          tlsCertFile = "/var/lib/vault/tls/server.crt";
          tlsKeyFile = "/var/lib/vault/tls/server.key";

          listenerExtraConfig = ''
            cluster_address = "0.0.0.0:8201"

            tls_disable = 0
            tls_client_ca_file = "/var/lib/vault/tls/ca.crt"
            tls_require_and_verify_client_cert = "true"
            tls_min_version = "tls12"
          '';

          storageBackend = "raft";
          storagePath = "/var/lib/vault";
          storageConfig = ''
            node_id = "vault-node-1"
          '';

          extraConfig = ''
            api_addr      = "https://${domains.subdomain}:8200"
            cluster_addr  = "https://${domains.subdomain}:8201"

            ui = true
          '';
        };

        systemd.services.vault-terraform-apply = {
          description = "Apply Vault Terraform provisioning";
          after = [ "vault.service" ];
          wants = [ "vault.service" ];

          serviceConfig = {
            Type = "oneshot";

            StateDirectory = "vault/terraform";
            WorkingDirectory = "/var/lib/vault/terraform";

            ExecStart = ''
              mkdir -p state configs              
              cp -u ${terraform} /var/lib/vault/terraform/configs/

              export VAULT_ADDR="https://${domains.subdomain}"
              export VAULT_CACERT="/var/lib/vault/tls/ca.crt"
              export VAULT_TOKEN="$(cat /run/vault/device-token)"

              tofu -chdir=configs \
                init -input=false -backend-config="path=../state/terraform.tfstate"

              tofu -chdir=configs \
                apply -auto-approve
            '';
          };

          path = with pkgs; [
            pkgs.coreutils
            pkgs.opentofu
          ];

          wantedBy = [ "multi-user.target" ];
        };

        services.vault-agent = {
          instances.device = {
            package = openbao;
            settings = {
              vault.address = "https://${domains.subdomain}";

              auto_auth.method = [
                {
                  type = "cert";
                  config = {
                    cert_file = "/etc/ssl/node.crt";
                    key_file = "/etc/ssl/node.key";
                    ca_cert_file = "/etc/ssl/ca.crt";
                  };
                }
              ];

              auto_auth.sink = [
                {
                  type = "file";
                  config.path = "/run/vault/device-token";
                }
              ];
            };
          };
        };
      };
    };
  };
}
