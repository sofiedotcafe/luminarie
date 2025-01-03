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
    catppuccin.kvantum.enable = true;
    qt = {
      enable = true;
      platformTheme.name = "kvantum";
      style.name = "kvantum";
    };
  };
}
