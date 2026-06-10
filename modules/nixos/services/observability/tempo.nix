{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.modules.nixos.services.observability.tempo;
in
{
  options.modules.nixos.services.observability.tempo = {
    enable = lib.mkEnableOption "Tempo trace database";

    address = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default = config.modules.nixos.networking.containerInterfaces.tempo.address;
    };

    port = lib.mkOption {
      type = lib.types.int;
      default = 3200;
    };

    otlpPort = lib.mkOption {
      type = lib.types.int;
      default = 4317;
    };
  };

  config = lib.mkIf cfg.enable {

    modules.nixos.networking.containerInterfaces.tempo = {
      zone = "cnt";
      id = 7;
      proxy = {
        enable = true;
        port = cfg.port;
        subdomain = "traces";
        tls = true;
      };
    };

    containers.tempo = {
      autoStart = true;

      forwardPorts = [
        { containerPort = cfg.port; hostPort = cfg.port; protocol = "tcp"; }
        { containerPort = cfg.otlpPort; hostPort = cfg.otlpPort; protocol = "tcp"; }
      ];

      config = {
        imports = [ inputs.nix-topology.nixosModules.default ];
        system.stateVersion = "26.05";

        networking.firewall.allowedTCPPorts = [ cfg.port cfg.otlpPort ];

        services.tempo = {
          enable = true;

          settings = {
            server.http_listen_port = cfg.port;

            distributor = {
              receivers = {
                otlp = {
                  protocols.grpc.endpoint = "0.0.0.0:${toString cfg.otlpPort}";
                };
              };
            };

            ingester = {
              max_block_bytes = 100000000;   # 100MB
              max_block_duration = "5m";
            };

            querier = { };
            query_frontend = { };
            compactor = { };

            # -----------------------------
            # Storage
            # -----------------------------
            storage = {
              trace = {
                backend = "local";
                local.path = "/var/lib/tempo/traces";
              };
              trace.wal = {
                path = "/var/lib/tempo/wal";
              };
            };

            # -----------------------------
            # Metrics generator
            # -----------------------------
            metrics_generator = {
              ring.kvstore.store = "memberlist";
              storage.path = "/var/lib/tempo/metrics-generator";

              processor.span_metrics = {
                dimensions = [
                  "service.name"
                  "span.name"
                  "status.code"
                ];
              };
            };

            # -----------------------------
            # Memberlist (for metrics-generator ring)
            # -----------------------------
            memberlist = {
              join_members = [ "127.0.0.1" ];
            };
          };
        };
      };
    };

    # Prometheus scrapes Tempo on the main HTTP port (/metrics)
    modules.nixos.services.observability.exporters.targets = [
      {
        job_name = "tempo";
        static_configs = [
          {
            targets = [
              "${cfg.address}:${toString cfg.port}"
            ];
            labels = {
              instance = "tempo";
            };
          }
        ];
      }
    ];

    modules.nixos.services.observability.grafana.datasources = [
      {
        name = "Tempo";
        type = "tempo";
        access = "proxy";
        url = "http://${cfg.address}:${toString cfg.port}";

        jsonData = {
          tracesToLogs = {
            datasourceUid = "loki";
          };
          serviceMap = {
            datasourceUid = "prometheus";
          };
        };
      }
    ];
  };
}
