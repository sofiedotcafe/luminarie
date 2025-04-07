{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.home.desktop.gnome;
  inherit (config.modules.home.desktop) catppuccin;
in
{
  config = mkIf (cfg.enable && catppuccin.enable) {
    catppuccin.kvantum.enable = lib.mkForce false;
    qt = {
      enable = true;
      platformTheme.name = "gtk3";
      style = {
        name = with catppuccin; "catppuccin-${flavor}-${accent}";
        package = pkgs.catppuccin-qt5ct;
      };
    };
  };
}
