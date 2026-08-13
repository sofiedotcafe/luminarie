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

  domains = rec {
    root = config.modules.nixos.services.traefik.internalDomain;
    subdomain = "${cfg.subdomain}.${root}";
  };

  openbao = pkgs.symlinkJoin {
    name = "openbao";
    paths = [
      (pkgs.writeShellScriptBin "bao" ''
        [ -f "''${CREDENTIALS_DIRECTORY:-}/vault-pin.cred" ] && export VAULT_HSM_PIN=$(< "''${CREDENTIALS_DIRECTORY}/vault-pin.cred")
        exec ${pkgs.openbao}/bin/bao "$@"
      '')
    ];
    postBuild = "ln -s $out/bin/bao $out/bin/vault";
    inherit (pkgs.openbao) version meta;
  };
in
{
  imports = [
    ./client.nix
    ./provision.nix
    ./options.nix
  ];

  config = lib.mkIf cfg.enable {
    modules.nixos.networking.containerInterfaces.vault = {
      zone = "cnt";
      id = 20;
      proxy = {
        enable = true;
        inherit (cfg) port subdomain;
        protocol = "https";
        tls = true;
      };
    };

    security.tpm2.enable = true;
    security.tpm2.pkcs11.enable = true;
    security.tpm2.tctiEnvironment.enable = true;

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
      bindMounts = lib.listToAttrs (
        map
          (
            dev:
            lib.nameValuePair dev {
              hostPath = dev;
              isReadOnly = false;
            }
          )
          [
            "/dev/tpmrm0"
            "/dev/tpm0"
            "/etc/ssl"
          ]
      );

      config = {
        imports = with inputs; [
          nix-topology.nixosModules.default
          systemd-vaultd.nixosModules.vaultAgent
          systemd-vaultd.nixosModules.systemdVaultd
        ];

        system.stateVersion = "26.05";
        security.tpm2 = {
          enable = true;
          pkcs11.enable = true;
          tctiEnvironment.enable = true;
        };

        systemd.services.vault-hsm-bootstrap = {
          description = "Initialize Vault's HSM cryptographic material using TPM-backed secrets and PKCS#11";
          wantedBy = [ "multi-user.target" ];
          before = [ "vault.service" ];
          unitConfig.ConditionPathExists = "!/var/lib/vault/vault-pin.cred";

          path = with pkgs; [
            tpm2-tools
            tpm2-pkcs11
            openssl
            systemd
            coreutils
          ];
          serviceConfig = {
            User = "root";
            Group = "root";
            DeviceAllow = [
              "/dev/tpm0 rw"
              "/dev/tpmrm0 rw"
            ];
            PrivateDevices = lib.mkForce false;
          };

          script = ''
            set -euo pipefail

            TPM2TOOLS_TCTI=device:/dev/tpm0

            umask 077
            mkdir -pm755 /etc/ssl
            mkdir -pm700 /var/lib/vault/{ssl,pkcs11}

            # 1. Generate Root CA inside private vault SSL directory
            openssl req -x509 -newkey rsa:3072 -nodes \
              -keyout /var/lib/vault/ssl/ca.key -out /var/lib/vault/ssl/ca.crt \
              -subj "/CN=Vault-Local-CA" -days 3650

            # 2. Generate Strict Server Certificate inside private vault SSL directory
            openssl req -new -newkey rsa:3072 -nodes \
              -keyout /var/lib/vault/ssl/server.key -out /var/lib/vault/ssl/server.csr \
              -subj "/CN=${domains.subdomain}/OU=Vault-Server" \
              -addext "subjectAltName=DNS:${domains.subdomain},DNS:localhost,IP:127.0.0.1"

            openssl x509 -req -in /var/lib/vault/ssl/server.csr \
              -CA /var/lib/vault/ssl/ca.crt -CAkey /var/lib/vault/ssl/ca.key -CAcreateserial \
              -out /var/lib/vault/ssl/server.crt -days 825 \
              -extfile <(printf "subjectAltName=DNS:${domains.subdomain},DNS:localhost,IP:127.0.0.1\nkeyUsage=digitalSignature,keyEncipherment\nextendedKeyUsage=serverAuth")

            # 3. Generate Strict Client Certificate for shared consumption into /etc/ssl
            openssl req -new -newkey rsa:3072 -nodes \
              -keyout /etc/ssl/node-client.key -out /etc/ssl/node-client.csr \
              -subj "/CN=traefik-client/OU=Internal-Services"

            openssl x509 -req -in /etc/ssl/node-client.csr \
              -CA /var/lib/vault/ssl/ca.crt -CAkey /var/lib/vault/ssl/ca.key -CAcreateserial \
              -out /etc/ssl/node-client.crt -days 825 \
              -extfile <(printf "keyUsage=digitalSignature,keyEncipherment\nextendedKeyUsage=clientAuth")

            # Copy public Root CA to shared directory for trust chains
            cp /var/lib/vault/ssl/ca.crt /etc/ssl/node-ca.crt

            rm -f /var/lib/vault/ssl/*.csr /etc/ssl/*.csr

            chmod 600 /var/lib/vault/ssl/*.key /etc/ssl/*.key
            chmod 644 /var/lib/vault/ssl/*.crt /etc/ssl/*.crt
            chown -R vault:vault /var/lib/vault/ssl /etc/ssl

            PIN="$(tpm2_getrandom 32 | base64 -w0)"
            printf '%s' "$PIN" > /var/lib/vault/vault-pin.raw
            systemd-creds encrypt --name=vault-pin.cred --tpm2-device=/dev/tpmrm0 --tpm2-pcrs=0+1+2+3+4+5+7 /var/lib/vault/vault-pin.raw /var/lib/vault/vault-pin.cred
            rm /var/lib/vault/vault-pin.raw
            chown vault:vault /var/lib/vault/vault-pin.cred

            tpm2_ptool init --path /var/lib/vault/pkcs11
            chown -R vault:vault /var/lib/vault/pkcs11

            SOPIN="$(tpm2_getrandom 16 | base64 -w0)"
            USERPIN="$(systemd-creds decrypt /var/lib/vault/vault-pin.cred)"

            tpm2_ptool addtoken --pid 1 --label vault --sopin "$SOPIN" --userpin "$USERPIN" --path /var/lib/vault/pkcs11
            tpm2_ptool addkey --algorithm rsa2048 --label vault --key-label vault-key --userpin "$USERPIN" --path /var/lib/vault/pkcs11
            tpm2_ptool addkey --algorithm hmac:sha256 --label vault --key-label vault-hmac --userpin "$USERPIN" --path /var/lib/vault/pkcs11
          '';
        };

        systemd.services.vault-operator-init = {
          description = "Initialize Vault operator once health check passes";
          wantedBy = [ "multi-user.target" ];
          after = [ "vault.service" ];
          requires = [ "vault.service" ];
          unitConfig.ConditionPathExists = "!/var/lib/vault/init.json";

          path = with pkgs; [
            curl
            jq
            coreutils
            openbao
            busybox
          ];

          environment = {
            VAULT_ADDR = "https://127.0.0.1:${toString cfg.port}";
            VAULT_CACERT = "/etc/ssl/node-ca.crt";
            VAULT_CLIENT_CERT = "/etc/ssl/node-client.crt";
            VAULT_CLIENT_KEY = "/etc/ssl/node-client.key";
          };

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };

          script = ''
            set -euo pipefail

            until curl --silent --cacert "$VAULT_CACERT" --cert "$VAULT_CLIENT_CERT" --key "$VAULT_CLIENT_KEY" "$VAULT_ADDR/v1/sys/health" >/dev/null 2>&1; do 
              sleep 2
            done

            HTTP_CODE=$(curl --silent --output /dev/null --write-out "%{http_code}" --cacert "$VAULT_CACERT" --cert "$VAULT_CLIENT_CERT" --key "$VAULT_CLIENT_KEY" "$VAULT_ADDR/v1/sys/health")

            # 501 means the server is running but uninitialized
            if [ "$HTTP_CODE" -eq 501 ]; then
              echo "Vault is uninitialized (501). Initializing..."
              umask 077
              vault operator init -format=json > /var/lib/vault/init.json
              chmod 600 /var/lib/vault/init.json
            fi
          '';
        };

        system.activationScripts.vault = {
          supportsDryActivation = true;
          text = ''
            INIT_FILE="/var/lib/vault/init.json"

            if [ -f "$INIT_FILE" ]; then
              ROOT_TOKEN=$(${pkgs.jq}/bin/jq -r '.root_token // "N/A"' "$INIT_FILE")
              UNSEAL_KEY_1=$(${pkgs.jq}/bin/jq -r '.unseal_keys_b64[0] // "N/A"' "$INIT_FILE")

              ${pkgs.gum}/bin/gum style \
                --foreground 196 \
                --border-foreground 196 \
                --border rounded \
                --padding "0 1" \
                "Vault Emergency Credentials" \
                "Root Token:    $ROOT_TOKEN" \
                "Unseal Key 1: $UNSEAL_KEY_1" \
                "" \
                "⚠️ Store these out-of-band securely! You can't access them after this!"

              rm -f "$INIT_FILE"
            fi
          '';
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

        users.groups.tss.members = [ "vault" ];

        services.vault = {
          enable = true;
          package = openbao;
          dev = false;
          address = "0.0.0.0:${toString cfg.port}";
          tlsCertFile = "/var/lib/vault/ssl/server.crt";
          tlsKeyFile = "/var/lib/vault/ssl/server.key";
          storageBackend = "raft";
          storagePath = "/var/lib/vault";
          storageConfig = "node_id = \"vault-node-1\"";
          listenerExtraConfig = ''
            cluster_address = "0.0.0.0:8201"
            tls_disable = 0
            tls_client_ca_file = "/etc/ssl/node-ca.crt"
            tls_require_and_verify_client_cert = "true"
            tls_min_version = "tls12"
          '';
          extraConfig = ''
            api_addr = "https://${domains.subdomain}:8200"
            cluster_addr = "https://${domains.subdomain}:8201"
            ui = true
          '';
        };
      };
    };
  };
}
