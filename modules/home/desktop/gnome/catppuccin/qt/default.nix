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
    catppuccin.kvantum.enable = true;
    qt = {
      enable = true;
      platformTheme.name = "kvantum";
      style.name = "kvantum";
      decoration.name = "catppuccin";
    };
  };
}
