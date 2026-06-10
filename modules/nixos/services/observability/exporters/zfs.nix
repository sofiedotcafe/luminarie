{ config, lib, ... }:

let
  cfg = config.modules.nixos.services.observability.exporters.zfs;
  obs = config.modules.nixos.services.observability;
in
{
  options.modules.nixos.services.observability.exporters.zfs = {
    enable = lib.mkEnableOption "ZFS exporter";
    port = lib.mkOption {
      type = lib.types.int;
      default = 9134;
    };
  };

  config = lib.mkIf cfg.enable {
    services.prometheus.exporters.zfs = {
      enable = true;
      port = cfg.port;
    };

    networking.firewall.interfaces."br-cnt".allowedTCPPorts = [
      cfg.port
    ];

    modules.nixos.services.observability.exporters.targets = [
      {
        job_name = "zfs";
        static_configs = [
          {
            targets = [
              "${config.modules.nixos.networking.zones.cnt.addr}:${toString cfg.port}"
            ];
            labels = {
              instance = "zfs";
            };
          }
        ];
      }
    ];
  };
}
