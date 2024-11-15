{ config, lib, ... }:
with lib;
let
  cfg = config.modules.home.programs.kitty;
in
{
  options.modules.home = {
    programs =
      genAttrs
        [
          "kitty"
        ]
        (k: {
          enable = mkEnableOption k;
        });
  };
  config = mkIf cfg.enable {
    programs.kitty = {
      enable = true;

      shellIntegration.enableZshIntegration = true;

      font.name = "JetBrainsMono Nerd Font";
    };
  };
}
