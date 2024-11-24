{ lib, config, ... }:
with lib;
let
  cfg = config.modules.nixos.boot.systemd;
in
{
  options.modules.nixos = {
    boot = {
      systemd.enable = mkEnableOption "systemd";
    };
  };
  config = mkIf cfg.enable {
    boot = {
      loader = {
        efi = {
          canTouchEfiVariables = true;
          efiSysMountPoint = "/boot";
        };
        systemd-boot = {
          enable = true;
          consoleMode = "max";
        };
        timeout = 3;
      };
    };
  };
}
