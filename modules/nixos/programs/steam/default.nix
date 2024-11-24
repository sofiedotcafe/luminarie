{ config, lib, ... }:
with lib;
let
  cfg = config.modules.nixos.programs.steam;
in
{
  options.modules.nixos = {
    programs = genAttrs [ "steam" ] (k: {
      enable = mkEnableOption k;
    });
  };
  config = mkIf cfg.enable {
    programs = {
      steam.enable = true;
      gamemode.enable = true;
    };
  };
}
