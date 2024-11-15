{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.home.desktop;
in
{
  config = mkIf (cfg.session.gnome.enable && cfg.catppuccin.enable) {
    catppuccin.pointerCursor.enable = true;
    home.pointerCursor = {
      gtk.enable = true;
      size = 24;
    };
    gtk = {
      enable = true;
      catppuccin = {
        enable = true;
        icon.enable = true;
        gnomeShellTheme = true;
      };
    };
  };
}
