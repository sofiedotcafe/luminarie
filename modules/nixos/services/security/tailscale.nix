{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:

let
  cfg = config.modules.nixos.services.security.tailscale;
in
{
  options.modules.nixos.services.security.tailscale = {
    enable = lib.mkEnableOption "Tailscale and Headscale";

    headscale = {
      domain = lib.mkOption {
        type = lib.types.str;
        default = "sofie.cafe";
      };

      port = lib.mkOption {
        type = lib.types.int;
        default = 8080;
      };

      dataDir = lib.mkOption {
        type = lib.types.path;
        default = "/var/lib/headscale";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d ${cfg.headscale.dataDir} 0750 root root -"
    ];

    modules.nixos.networking.containerInterfaces.headscale = {
      zone = "cnt-dmz";
      id = 11;
      proxy = {
        enable = true;
        subdomain = "tail";
        port = cfg.headscale.port;
        tls = true;
      };
    };

    modules.nixos.services.security.vault.client = {
      enable = true;
      traefik = false;

      services.headscale = {
        environmentTemplate = ''
          {{ with secret "kv/data/headscale" }}
          HEADSCALE_OIDC_CLIENT_SECRET={{ .Data.data.oidc_client_secret }}
          {{ end }}
        '';
      };

      services.tailscale-key-sync = {
        template = ''
          {{ with secret "kv/data/headscale/tailscale-key" }}
          {{ .Data.data | toJSON }}
          {{ end }}
        '';
        secrets.secret_key = { };
      };
    };

    containers.headscale = {
      autoStart = true;

      config = { ... }: {
        imports = with inputs; [
          nix-topology.nixosModules.default
          systemd-vaultd.nixosModules.vaultAgent
          systemd-vaultd.nixosModules.systemdVaultd
        ];
        system.stateVersion = "26.05";

        systemd.tmpfiles.rules = [
          "d ${cfg.headscale.dataDir} 0750 headscale headscale -"
        ];

        networking.firewall.allowedTCPPorts = [ cfg.headscale.port ];

        services.headscale = {
          enable = true;

          settings = {
            server_url = "https://tail.${cfg.headscale.domain}";
            listen_addr = "0.0.0.0:${toString cfg.headscale.port}";

            database = {
              type = "sqlite";
              sqlite = {
                path = "${cfg.headscale.dataDir}/db.sqlite";
              };
            };

            dns.magic_dns = false;
            dns.nameservers.global = [ config.modules.nixos.networking.zones.svc.gateway ];

            oidc = {
              issuer = "https://noseprint.sofie.cafe/application/o/headscale/";
              client_id = "HAuAwiKwBqE8VZfIZnptkJ8arghphUTYQFDKs0yn";
              client_secret_path = "/dev/null";

              scope = [
                "openid"
                "profile"
                "email"
                "groups"
              ];
              allowed_groups = [
                "authentik Admins"
              ];

              pkce.enable = true;
            };
          };
        };

        systemd.services.headscale-register-vault-key = {
          description = "Generate Headscale Preauthkey and Push to Vault";
          wantedBy = [ "multi-user.target" ];
          after = [ "headscale.service" ];
          requires = [ "headscale.service" ];

          path = with pkgs; [
            headscale
            curl
            jq
          ];

          script = ''
            # Wait for Headscale socket/service to be ready
            until headscale ping >/dev/null 2>&1; do
              sleep 2
            done

            # Generate reusable preauthkey
            KEY=$(headscale preauthkeys create --user default --reusable --expiration 365d --output json | jq -r '.key')

            # Retrieve local Vault agent token (or AppRole token)
            VAULT_TOKEN=$(cat /run/vault/token 2>/dev/null || echo "")

            if [ -n "$KEY" ] && [ -n "$VAULT_TOKEN" ]; then
              curl -s --request POST \
                --header "X-Vault-Token: $VAULT_TOKEN" \
                --data "{\"data\": {\"secret_key\": \"$KEY\"}}" \
                http://127.0.0.1:8200/v1/kv/data/headscale/tailscale-key
            fi
          '';

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
        };
      };
    };

    systemd.services.tailscale-key-sync = {
      description = "Fetch Tailscale auth key from Vault for service startup";
      wantedBy = [ "tailscaled.service" ];
      before = [ "tailscaled.service" ];

      script = ''
        mkdir -p /run/tailscale
        cp "$CREDENTIALS_DIRECTORY/secret_key" /run/tailscale/authkey
        chmod 600 /run/tailscale/authkey
      '';

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
    };

    services.tailscale = {
      enable = true;

      authKeyFile = "/run/tailscale/authkey";
      openFirewall = true;

      extraUpFlags = [
        "--login-server=https://tail.${cfg.headscale.domain}"
        "--accept-dns=false"
        "--advertise-exit-node"
        "--advertise-routes=10.0.0.0/28,10.0.1.0/28"
      ];
    };

    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = true;
      "net.ipv6.conf.all.forwarding" = true;
    };
  };
}
