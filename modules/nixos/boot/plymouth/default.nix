{ lib, config, ... }:
with lib;
let
  cfg = config.modules.nixos.boot.plymouth;
in
{
  options.modules.nixos = {
    boot = {
      plymouth.enable = mkEnableOption "systemd";
    };
  };
  config = mkIf cfg.enable {
    boot = {
      plymouth.enable = true;
    };
  };
}
