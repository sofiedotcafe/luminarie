{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.home.shell.common;
in
{
  config = mkIf cfg.enable {
    home.shellAliases = {
      ls = "${getExe pkgs.lsd}";
      rm = "${pkgs.trash-cli}/bin/trash-put";
    };

    home.packages = with pkgs; [
      coreutils
      fd
      file
      fzf
      gh
      git
      gnugrep
      lsd
      nitch
      ripgrep-all
      trash-cli
      zip
      unzip
    ];
  };
}
