{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.home.desktop.catppuccin;
in
{
  config = mkIf cfg.enable {
    catppuccin = {
      enable = true;
      autoEnable = false;
      inherit (cfg) flavor accent;
    };
  };
}
