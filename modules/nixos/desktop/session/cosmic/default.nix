{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.nixos.desktop.session.cosmic;
in
{
  config = mkIf cfg.enable {
    services = {
      displayManager.cosmic-greeter.enable = true;
      desktopManager.cosmic.enable = true;
    };

    services.system76-scheduler.enable = true;

    environment.systemPackages = with pkgs; [ libnotify ];
  };
}
