{ config, lib, ... }:

let
  obs = config.modules.nixos.services.observability;
in
{
  options.modules.nixos.services.observability.exporters = {
    targets = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [
        {
          job_name = "grafana";
          static_configs = [
            {
              targets = [
                "${obs.grafana.address}:${toString obs.grafana.port}"
              ];
              labels = {
                instance = "grafana";
              };
            }
          ];
        }
      ];
    };
  };

  imports = [
    ./node.nix
    ./smart.nix
    ./systemd.nix
    ./zfs.nix
    ./ipmi.nix
  ];
}
