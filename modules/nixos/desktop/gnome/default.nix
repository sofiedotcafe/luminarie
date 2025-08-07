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
      displayManager = {
        enable = true;
        gdm.enable = true;
      };
      desktopManager.gnome = {
        enable = true;
        extraGSettingsOverrides = ''
          [org.gnome.mutter]
          experimental-features=['scale-monitor-framebuffer', 'variable-refresh-rate', 'xwayland-native-scaling']
          check-alive-timeout=${
            # Default is 5000ms, but that's bit too small for us.
            lib.gvariant.mkUint32 (15 * 1000)
          }
        '';
        extraGSettingsOverridePackages = [ pkgs.mutter ];
      };
      gnome = {
        tinysparql.enable = true;
        localsearch.enable = true;
      };
      gvfs.enable = true;

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

      printing = {
        enable = true;
        drivers = with pkgs; [ brlaser ];
      };

      avahi = {
        enable = true;
        nssmdns4 = true;
        openFirewall = true;
      };
    };

    environment = {
      systemPackages = with pkgs; [
        amberol
        blackbox-terminal
        cavalier
        papers
        fractal
      ];
      gnome.excludePackages = with pkgs; [
        gnome-console
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
