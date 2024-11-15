{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.home.desktop.session.cosmic;
in
{
  config = mkIf cfg.enable {
    fonts.fontconfig.enable = true;
    home.packages = with pkgs; [
      (nerdfonts.override {
        fonts = [
          "JetBrainsMono"
          # "FiraCode"
        ];
      })
    ];
  };
}
