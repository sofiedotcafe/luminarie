{
  pkgs,
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
    qt = {
      enable = true;
      platformTheme.name = "kvantum";
      style = {
        package = pkgs.catppuccin-kvantum.override {
          variant = config.catppuccin.flavor;
          inherit (config.catppuccin) accent;
        };
        name = "kvantum";
      };
    };

    home.packages = with pkgs; [
      qt6Packages.qtstyleplugin-kvantum
      libsForQt5.qtstyleplugin-kvantum
    ];

    xdg.configFile."Kvantum/kvantum.kvconfig".source =
      with config.catppuccin;
      (pkgs.formats.ini { }).generate "kvantum.kvconfig" {
        General.theme = "catppuccin-${flavor}-${accent}";
      };
  };
}
