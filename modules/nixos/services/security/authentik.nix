{
  config,
  lib,
  inputs,
  ...
}:

let
  cfg = config.modules.nixos.services.security.authentik;
in
{
  options.modules.nixos.services.security.authentik = {
    enable = lib.mkEnableOption "Authentik IdP";

    port = lib.mkOption {
      type = lib.types.int;
      default = 9000;
    };

    email = lib.mkOption {
      type = lib.types.submodule {
        options = {
          host = lib.mkOption {
            type = lib.types.str;
            description = "SMTP server hostname";
          };

          port = lib.mkOption {
            type = lib.types.int;
            default = 587;
            description = "SMTP server port";
          };

          username = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "SMTP login username";
          };

          from = lib.mkOption {
            type = lib.types.str;
            description = "Email address used as the sender";
          };
        };
      };
      default = { };
      description = "Minimal SMTP configuration for Authentik";
    };
  };

  config = lib.mkIf cfg.enable {
    modules.nixos.networking.containerInterfaces.authentik = {
      zone = "cnt-dmz";
      id = 10;

      proxy = {
        enable = true;
        port = cfg.port;
        subdomain = "noseprint";
        tls = true;
      };
    };

    # Use client module abstraction for Vault Agent + systemd-vaultd setup
    modules.nixos.services.security.vault.client = {
      enable = true;
      traefik = false;

      services.authentik = {
        environmentTemplate = ''
          {{ with secret "secret/data/authentik/bootstrap" }}
          AUTHENTIK_SECRET_KEY={{ .Data.data.secret_key }}
          AUTHENTIK_BOOTSTRAP_TOKEN={{ .Data.data.bootstrap_token }}
          {{ end }}
          {{ with secret "kv/data/authentik" }}
          AUTHENTIK_EMAIL__PASSWORD={{ .Data.data.smtp_key }}
          {{ end }}
        '';
      };
    };

    containers.authentik = {
      autoStart = true;

      forwardPorts = [
        {
          containerPort = cfg.port;
          hostPort = cfg.port;
          protocol = "tcp";
        }
      ];

      config = { ... }: {
        system.stateVersion = "26.05";

        imports = with inputs; [
          nix-topology.nixosModules.default
          systemd-vaultd.nixosModules.vaultAgent
          systemd-vaultd.nixosModules.systemdVaultd
          authentik-nix.nixosModules.default
        ];

        networking.firewall.allowedTCPPorts = [ cfg.port ];

        services.authentik = {
          enable = true;
          settings = {
            email = {
              inherit (cfg.email)
                host
                port
                username
                from
                ;
              use_tls = true;
              use_ssl = false;
            };
            disable_startup_analytics = true;
            avatars = "initials";
          };
        };
      };
    };
  };
}
