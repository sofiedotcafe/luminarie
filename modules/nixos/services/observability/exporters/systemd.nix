{ config, lib, ... }:

let
  cfg = config.modules.nixos.services.observability.exporters.systemd;
in
{
  options.modules.nixos.services.observability.exporters.systemd = {
    enable = lib.mkEnableOption "systemd exporter";
    port = lib.mkOption {
      type = lib.types.int;
      default = 9558;
    };
  };

  config = lib.mkIf cfg.enable {
    services.prometheus.exporters.systemd = {
      enable = true;
      port = cfg.port;
    };

    networking.firewall.interfaces."br-cnt".allowedTCPPorts = [
      cfg.port
    ];

    modules.nixos.services.observability.exporters.targets = [
      {
        job_name = "systemd";
        static_configs = [
          {
            targets = [
              "${config.modules.nixos.networking.zones.cnt.addr}:${toString cfg.port}"
            ];
            labels = {
              instance = "systemd";
            };
          }
        ];
      }
    ];
  };
}
