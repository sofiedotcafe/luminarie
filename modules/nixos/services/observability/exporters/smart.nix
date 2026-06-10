{ config, lib, ... }:

let
  cfg = config.modules.nixos.services.observability.exporters.smart;
in
{
  options.modules.nixos.services.observability.exporters.smart = {
    enable = lib.mkEnableOption "smartctl exporter";
    port = lib.mkOption {
      type = lib.types.int;
      default = 9633;
    };
    devices = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
  };

  config = lib.mkIf cfg.enable {
    services.prometheus.exporters.smartctl = {
      enable = true;
      port = cfg.port;
      devices = cfg.devices;
    };

    networking.firewall.interfaces."br-cnt".allowedTCPPorts = [
      cfg.port
    ];

    modules.nixos.services.observability.exporters.targets = [
      {
        job_name = "smart";
        static_configs = [
          {
            targets = [
              "${config.modules.nixos.networking.zones.cnt.addr}:${toString cfg.port}"
            ];
            labels = {
              instance = "smart";
            };
          }
        ];
      }
    ];
  };
}
