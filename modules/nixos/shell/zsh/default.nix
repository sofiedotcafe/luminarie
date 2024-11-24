{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.nixos.shell;
in
{
  config = mkIf (cfg.package == pkgs.zsh) {
    environment.shells = with pkgs; [ zsh ];
    programs.zsh.enable = true;
  };
}
