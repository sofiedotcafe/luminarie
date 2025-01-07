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
        desktopManager.gnome = {
          enable = true;
          extraGSettingsOverridePackages = [ pkgs.mutter ];
          extraGSettingsOverrides = ''
            [org.gnome.mutter]
            experimental-features=['scale-monitor-framebuffer', 'variable-refresh-rate', 'xwayland-native-scaling']
          '';
        };
      };
      gnome = {
        tinysparql.enable = true;
        localsearch.enable = true;
      };
      pipewire = {
        enable = true;
        pulse.enable = true;
        jack.enable = true;

        alsa = {
          enable = true;
          support32Bit = true;
        };
      };

      system76-scheduler.enable = true;
    };

    i18n.inputMethod = {
      enable = true;
      type = "ibus";
    };

    environment = {
      systemPackages = with pkgs; [
        amberol
        blackbox-terminal
        cavalier
        fractal
      ];
      gnome.excludePackages = with pkgs; [
        gnome-connections
        gnome-console
        gnome-tour
        gnome-maps
        gnome-music
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
