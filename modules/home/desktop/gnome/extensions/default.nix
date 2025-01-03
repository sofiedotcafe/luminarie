{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.home.desktop.gnome;
  extensions = with pkgs.gnomeExtensions; [
    appindicator
    blur-my-shell
    tiling-shell
    clipboard-history
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

        "org/gnome/shell/extensions/blur-my-shell/applications" = {
          blur = true;
          dynamic-opacity = true;
          enable-all = true;
          opacity = 225;
        };
      };
    };
  };
}
