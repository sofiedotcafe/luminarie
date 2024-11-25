{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.nixos.desktop.session.gnome;
in
{
  config = mkIf cfg.enable {
    services = {
      displayManager.enable = true;
      xserver = {
        displayManager.gdm.enable = true;
        desktopManager.gnome.enable = true;
      };
      gnome = {
        tinysparql.enable = true;
        localsearch.enable = true;
      };
      pipewire = {
        enable = true;
        alsa.enable = true;
        pulse.enable = true;
      };

      system76-scheduler.enable = true;
    };

    security.rtkit.enable = true;

    environment = {
      systemPackages = with pkgs; [
        blackbox-terminal
        fractal
        libnotify
      ];
      gnome.excludePackages = with pkgs; [
        gnome-maps
        gnome-tour
        gnome-connections
        gnome-console
        epiphany
        geary
        snapshot
        evince
      ];
    };
  };
}
