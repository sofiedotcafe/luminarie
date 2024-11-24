{
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.modules.home.programs.vscode;
in
{
  options.modules.home = {
    programs =
      genAttrs
        [
          "vscode"
        ]
        (k: {
          enable = mkEnableOption k;
        });
  };
  config = mkIf cfg.enable { programs.vscode.enable = true; };
}
