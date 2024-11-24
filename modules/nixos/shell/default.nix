{ lib, pkgs, ... }:
with lib;
{
  options.modules.nixos = {
    shell = {
      package = mkOption {
        type = types.package;
        default = pkgs.zsh;
        description = ''
          Select the shell you want to use.
        '';
        example = pkgs.zsh;
      };
    };
  };
  imports = [ ./zsh ];
}
