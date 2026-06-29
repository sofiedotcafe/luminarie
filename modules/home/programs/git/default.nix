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

      settings = {
        user = {
          name = "sofiedotcafe";
          email = "sofie.halenius@sofie.cafe";
        };
      };
    };

    programs.gh = {
      enable = true;
      gitCredentialHelper = {
        enable = true;
      };
    };
  };
}
