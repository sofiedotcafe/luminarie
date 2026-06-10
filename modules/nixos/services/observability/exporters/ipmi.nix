{ config, lib, pkgs, ... }:

let
  cfg = config.modules.nixos.services.observability.exporters.ipmi;

  ipmiConfig = pkgs.writeText "ipmi-local.yml" ''
    modules:
      default:
        driver: "KCS"
        collectors:
          - bmc
          - chassis
          - ipmi
          - dcmi
  '';
in
{
  options.modules.nixos.services.observability.exporters.ipmi = {
    enable = lib.mkEnableOption "IPMI exporter";

    port = lib.mkOption {
      type = lib.types.int;
      default = 9290;
      description = "Port for the IPMI exporter.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.prometheus.exporters.ipmi = {
      enable = true;
      port = cfg.port;
      configFile = ipmiConfig;
    };

    services.udev.extraRules = ''
      KERNEL=="ipmi*", MODE="0660", GROUP="${config.services.prometheus.exporters.ipmi.group}"
    '';

    systemd.services.prometheus-ipmi-exporter.serviceConfig = {
      AmbientCapabilities = [ "CAP_SYS_ADMIN" "CAP_SYS_RAWIO" ];
      CapabilityBoundingSet = [ "CAP_SYS_ADMIN" "CAP_SYS_RAWIO" ];
      PrivateDevices = false;
    };


    networking.firewall.interfaces."br-cnt".allowedTCPPorts = [
      cfg.port
    ];

    modules.nixos.services.observability.exporters.targets = [
      {
        job_name = "ipmi";
        static_configs = [
          {
            targets = [
              "${config.modules.nixos.networking.zones.cnt.addr}:${toString cfg.port}"
            ];
            labels = {
              instance = "ipmi";
            };
          }
        ];
      }
    ];
  };
}
