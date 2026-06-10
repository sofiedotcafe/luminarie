{
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.modules.home.programs.git;
in
{
  options.modules.home = {
    programs.git.enable = mkEnableOption "git";
  };
  config = mkIf cfg.enable {
    programs.git = {
      enable = true;

      userName = "sofiedotcafe";
      userEmail = "sofie.halenius@sofie.cafe";
    };
  };
}
