{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.home.desktop.gnome;
  inherit (config.modules.home.desktop) catppuccin;
in
{
  config = mkIf (cfg.enable && catppuccin.enable) {
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
