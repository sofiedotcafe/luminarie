{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.home.shell;
in
{
  config = mkIf cfg.zsh.enable {
    programs = {
      zsh = {
        enable = true;
        initContent = getExe cfg.fetcher.package;

        syntaxHighlighting.enable = true;
        autosuggestion.enable = true;
        oh-my-zsh = {
          enable = true;
          plugins = [ "git" ];
        };
      };

      direnv = {
        enable = true;
        enableZshIntegration = true;
        nix-direnv.enable = true;
      };
    };
  };
}
