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

      config = { ... }: {
        imports = with inputs; [
          nix-topology.nixosModules.default

          systemd-vaultd.nixosModules.vaultAgent
          systemd-vaultd.nixosModules.systemdVaultd
        ];
        system.stateVersion = "26.05";

        networking.firewall = {
          enable = true;
          allowedTCPPorts = [ cfg.port ];
        };

        environment.etc."grafana/dashboards".source = ./dashboards;

        systemd.services.grafana = {
          vault = {
            secrets = {
              "grafana/secret_key" = {
                user = "grafana";
                group = "grafana";
                path = "/run/vault/grafana_secret_key";
                template = ''
                  {{ with secret "kv/data/grafana" }}{{ .Data.data.secret_key }}{{ end }}
                '';
              };
            };

            environmentTemplate = ''
              {{ with secret "kv/data/grafana" }}
              GF_AUTH_GENERIC_OAUTH_CLIENT_ID={{ .Data.data.client_id }}
              GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET={{ .Data.data.client_secret }}
              {{ end }}
            '';
          };
        };

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

            security.secret_key = "$__file{/run/vault/grafana_secret_key}";

            auth = {
              disable_login_form = true;
              oauth_auto_login = true;
            };

            "auth.generic_oauth" = {
              enabled = true;
              name = "authentik";
              scopes = "openid profile email";
              auth_url = "https://noseprint.sofie.cafe/application/o/authorize/";
              token_url = "https://noseprint.sofie.cafe/application/o/token/";
              api_url = "https://noseprint.sofie.cafe/application/o/userinfo/";
              signout_redirect_url = "https://noseprint.sofie.cafe/application/o/grafana/end-session/";
              role_attribute_path = "contains(groups[*], 'authentik Admins') && 'Admin' || contains(groups[*], 'authentik Read-only') && 'Viewer' || contains(groups[*], 'authentik Users') && 'Editor'";
              allow_assign_grafana_admin = true;
            };

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
