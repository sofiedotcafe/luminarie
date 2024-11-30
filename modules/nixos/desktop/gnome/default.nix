{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.nixos.desktop.gnome;
in
{
  options.modules.nixos.desktop = {
    gnome.enable = mkEnableOption "gnome";
  };
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

      # https://github.com/NixOS/nixpkgs/issues/195936
      sessionVariables.GST_PLUGIN_SYSTEM_PATH_1_0 = lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" (
        with pkgs.gst_all_1;
        [
          gst-plugins-good
          gst-plugins-bad
          gst-plugins-ugly
          gst-libav
        ]
      );
    };
  };
}
