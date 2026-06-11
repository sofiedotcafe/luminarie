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
    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };

  config = lib.mkIf cfg.enable {
    system.stateVersion = "26.05";

    modules.nixos.networking.containerInterfaces.authentik = {
      zone = "cnt-dmz";
      id = 10;
      proxy.port = cfg.port;

      proxy = {
        enable = true;
        subdomain = "noseprint";
        tls = true;
      };
    };

    sops.templates."authentik-env".content = ''
      AUTHENTIK_SECRET_KEY="${config.sops.placeholder."authentik/secret_key"}"
      AUTHENTIK_EMAIL__PASSWORD="${config.sops.placeholder."authentik/smtp_key"}"
    '';

    containers.authentik = {
      autoStart = true;

      forwardPorts = [
        {
          containerPort = cfg.port;
          hostPort = cfg.port;
          protocol = "tcp";
        }
      ];

      # Mount the environment file
      bindMounts."${config.sops.templates."authentik-env".path}" = {
        hostPath = config.sops.templates."authentik-env".path;
        isReadOnly = true;
      };

      config = {
        system.stateVersion = "26.05";

        imports = [
          inputs.nix-topology.nixosModules.default
          inputs.authentik-nix.nixosModules.default
        ];

        networking.firewall.allowedTCPPorts = [ cfg.port ];

        services.authentik = {
          enable = true;
          environmentFile = config.sops.templates."authentik-env".path;
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
