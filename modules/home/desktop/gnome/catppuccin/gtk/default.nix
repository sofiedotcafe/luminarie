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
  config = mkIf (cfg.gnome.enable && cfg.catppuccin.enable) {
    gtk.enable = true;
    home.pointerCursor = {
      gtk.enable = true;
      size = 24;
    };
    catppuccin = {
      gtk = {
        enable = true;
        icon.enable = true;
        gnomeShellTheme = true;
      };
      cursors.enable = true;
    };
  };
}
