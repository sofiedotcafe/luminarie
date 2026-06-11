{
  config,
  lib,
  inputs,
  ...
}:

let
  obs = config.modules.nixos.services.observability;
  cfg = obs.grafana;
in
{
  options.modules.nixos.services.observability.grafana = {
    enable = lib.mkEnableOption "Grafana";

    address = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default = config.modules.nixos.networking.containerInterfaces.grafana.address;
    };

    port = lib.mkOption {
      type = lib.types.int;
      default = 3000;
    };

    datasources = lib.mkOption {
      default = [ ];
    };
  };

  config = lib.mkIf cfg.enable {
    modules.nixos.networking.containerInterfaces.grafana = {
      zone = "cnt";
      id = 30;
      proxy = {
        enable = true;
        port = cfg.port;
        subdomain = "vet";
        tls = true;
      };
    };

    containers.grafana = {
      autoStart = true;

      forwardPorts = [
        {
          containerPort = cfg.port;
          hostPort = cfg.port;
          protocol = "tcp";
        }
      ];

      # Secrets
      bindMounts.${config.sops.secrets."grafana/secret_key".path} = {
        hostPath = config.sops.secrets."grafana/secret_key".path;
        isReadOnly = false;
      };
      bindMounts.${config.sops.secrets."grafana/client_secret".path} = {
        hostPath = config.sops.secrets."grafana/client_secret".path;
        isReadOnly = false;
      };

      config = {
        imports = [ inputs.nix-topology.nixosModules.default ];
        system.stateVersion = "26.05";

        systemd.tmpfiles.rules = [
          "d /run/secrets/grafana 0750 root grafana -"
          "f /run/secrets/grafana/secret_key 0440 root grafana -"
          "f /run/secrets/grafana/client_secret 0440 root grafana -"
        ];

        networking.firewall = {
          enable = true;
          allowedTCPPorts = [ cfg.port ];
        };

        environment.etc."grafana/dashboards".source = ./dashboards;

        services.grafana = {
          enable = true;

          provision = {
            enable = true;

            datasources.settings.datasources = cfg.datasources;

            dashboards.settings.providers = [
              {
                name = "dashboards";
                orgId = 1;
                folder = "";
                type = "file";
                disableDeletion = true;
                options = {
                  path = "/etc/grafana/dashboards";
                  foldersFromFilesStructure = true;
                };
              }
            ];
          };

          settings = {
            server = {
              http_addr = "0.0.0.0";
              root_url = "https://vet.cage.sofie.cafe";
              http_port = cfg.port;
            };

            auth = {
              disable_login_form = true;
              oauth_auto_login = true;
            };

            "auth.generic_oauth" = {
              enabled = true;
              name = "authentik";
              client_id = "lK1vwONl2oMoIMGYjuEY7GwhaxDOBAcGenvchK9J";
              client_secret = "$__file{${config.sops.secrets."grafana/client_secret".path}}";
              scopes = "openid profile email";
              auth_url = "https://noseprint.sofie.cafe/application/o/authorize/";
              token_url = "https://noseprint.sofie.cafe/application/o/token/";
              api_url = "https://noseprint.sofie.cafe/application/o/userinfo/";
              signout_redirect_url = "https://noseprint.sofie.cafe/application/o/grafana/end-session/";
              role_attribute_path = "contains(groups[*], 'authentik Admins') && 'Admin' || contains(groups[*], 'authentik Read-only') && 'Viewer' || contains(groups[*], 'authentik Users') && 'Editor'";
              allow_assign_grafana_admin = true;
            };

            security.secret_key = "$__file{${config.sops.secrets."grafana/secret_key".path}}";

            users = {
              auto_assign_org = true;
              auto_assign_org_id = 1;
            };
          };
        };
      };
    };
  };
}
