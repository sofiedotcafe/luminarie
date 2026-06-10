{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.modules.nixos.services.observability.loki;
in
{
  options.modules.nixos.services.observability.loki = {
    enable = lib.mkEnableOption "Loki log database";

    address = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default = config.modules.nixos.networking.containerInterfaces.loki.address;
    };

    port = lib.mkOption {
      type = lib.types.int;
      default = 3100;
    };
  };

  config = lib.mkIf cfg.enable {

    modules.nixos.networking.containerInterfaces.loki = {
      zone = "cnt";
      id = 6;
      proxy = {
        enable = true;
        port = cfg.port;
        subdomain = "logs";
        tls = true;
      };
    };

    containers.loki = {
      autoStart = true;

      forwardPorts = [
        { containerPort = cfg.port; hostPort = cfg.port; protocol = "tcp"; }
      ];

      config = {
        imports = [ inputs.nix-topology.nixosModules.default ];
        system.stateVersion = "26.05";

        networking.firewall.allowedTCPPorts = [ cfg.port ];

        services.loki = {
          enable = true;

          configuration = {
            server.http_listen_port = cfg.port;
            server.http_listen_address = "0.0.0.0";
            auth_enabled = false;

            ingester.lifecycler = {
              address = "127.0.0.1";
              ring.kvstore.store = "inmemory";
            };

            limits_config = {
              allow_structured_metadata = true;
            };

            common = {
              replication_factor = 1;
            };

            compactor = {
              working_directory = "/var/lib/loki/compactor";
            };

            schema_config.configs = [{
              from = "2024-01-01";
              store = "tsdb";
              object_store = "filesystem";
              schema = "v13";
              index = {
                prefix = "index_";
                period = "24h";
              };
            }];

            storage_config = {
              tsdb_shipper = {
                active_index_directory = "/var/lib/loki/tsdb-index";
                cache_location = "/var/lib/loki/tsdb-cache";
              };

              filesystem = {
                directory = "/var/lib/loki/chunks";
              };
            };
          };
        };
      };
    };

    modules.nixos.services.observability.grafana.datasources = [
      {
        name = "Loki";
        type = "loki";
        access = "proxy";
        url = "http://${cfg.address}:${toString cfg.port}";
      }
    ];
  };
}
