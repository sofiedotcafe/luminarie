{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.home.programs.vscode;
in
{
  options.modules.home = {
    programs.vscode.enable = mkEnableOption "vscode";
  };
  config = mkIf cfg.enable { home.packages = with pkgs; [ vscode ]; };
}
