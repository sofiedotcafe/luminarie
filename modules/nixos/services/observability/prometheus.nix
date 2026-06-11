{
  config,
  lib,
  inputs,
  ...
}:

let
  obs = config.modules.nixos.services.observability;
  cfg = obs.prometheus;
in
{
  options.modules.nixos.services.observability.prometheus = {
    enable = lib.mkEnableOption "Prometheus";

    address = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default = config.modules.nixos.networking.containerInterfaces.prometheus.address;
    };

    port = lib.mkOption {
      type = lib.types.int;
      default = 9090;
    };
  };

  config = lib.mkIf cfg.enable {
    modules.nixos.networking.containerInterfaces.prometheus = {
      zone = "cnt";
      id = 31;
      proxy = {
        enable = true;
        port = cfg.port;
        subdomain = "diary";
        tls = true;
      };
    };

    containers.prometheus = {
      autoStart = true;

      forwardPorts = [
        {
          containerPort = cfg.port;
          hostPort = cfg.port;
          protocol = "tcp";
        }
      ];

      config = {
        imports = [ inputs.nix-topology.nixosModules.default ];
        system.stateVersion = "26.05";

        networking.firewall = {
          enable = true;
          allowedTCPPorts = [ cfg.port ];
        };

        services.prometheus = {
          enable = true;
          scrapeConfigs = obs.exporters.targets;
        };
      };
    };

    modules.nixos.services.observability.grafana.datasources = [
      {
        name = "Prometheus";
        type = "prometheus";
        access = "proxy";
        url = "http://${obs.prometheus.address}:${toString obs.prometheus.port}";
        isDefault = true;
      }
    ];
  };
}
