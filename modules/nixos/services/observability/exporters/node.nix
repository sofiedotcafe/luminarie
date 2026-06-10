{ config, lib, ... }:

let
  cfg = config.modules.nixos.services.observability.exporters.node;
in
{
  options.modules.nixos.services.observability.exporters.node = {
    enable = lib.mkEnableOption "Node exporter";
    port = lib.mkOption {
      type = lib.types.int;
      default = 9100;
    };
  };

  config = lib.mkIf cfg.enable {
    services.prometheus.exporters.node = {
      enable = true;
      port = cfg.port;
    };

    networking.firewall.interfaces."br-cnt".allowedTCPPorts = [
      cfg.port
    ];

    modules.nixos.services.observability.exporters.targets = [
      {
        job_name = "node";
        static_configs = [
          {
            targets = [
              "${config.modules.nixos.networking.zones.cnt.addr}:${toString cfg.port}"
            ];
            labels = {
              instance = "node";
            };
          }
        ];
      }
    ];
  };
}
