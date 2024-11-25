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
    xdg.dataFile."blackbox/schemes/catppuccin-${config.catppuccin.flavor}.json".source =
      pkgs.fetchFromGitHub {
        owner = "catppuccin";
        repo = "tilix";
        rev = "07e53fce36e2162242c8b70f15996841df8f7ce2";
        sha256 = "X8Ks33ELcedyvCA1espbyw4X1gxER6BB8PNxjE6mgk0=";
      }
      + "/themes/catppuccin-${config.catppuccin.flavor}.json";
    dconf.settings = {
      "com/raggesilver/BlackBox" = {
        easy-copy-paste = true;
        font = "JetBrainsMonoNL Nerd Font Mono Bold 12";
        pretty = true;
        terminal-bell = false;
        theme-bold-is-bright = true;
        theme-dark = "Catppuccin Mocha";
      };
    };
  };
}
