{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.home.desktop;
in
{
  config = mkIf (cfg.gnome.enable && cfg.catppuccin.enable) {
    catppuccin.kvantum.enable = lib.mkForce false;
    qt = {
      enable = true;
      platformTheme.name = "gtk3";
      style = {
        name = with cfg.catppuccin; "catppuccin-${flavor}-${accent}";
        package = pkgs.catppuccin-qt5ct;
      };
    };
  };
}
