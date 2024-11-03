{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.home.desktop.session.gnome;
  extensions = with pkgs.gnomeExtensions; [
    appindicator
    blur-my-shell
    clipboard-history
    rounded-window-corners-reborn
    tiling-shell
    user-avatar-in-quick-settings
  ];
in
{
  config = mkIf cfg.enable {
    home.packages = extensions;
    dconf = {
      enable = true;
      settings = {
        "org/gnome/shell" = {
          disable-user-extensions = false;
          enabled-extensions = map (ext: ext.extensionUuid) extensions;
        };

        # Configure individual extensions
        # "org/gnome/shell/extensions/blur-my-shell" = {
        #   brightness = 0.75;
        #   noise-amount = 0;
        # };
      };
    };
  };
}
