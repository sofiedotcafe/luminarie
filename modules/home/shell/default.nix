{
  lib,
  pkgs,
  ...
}:
with lib;
{
  options.modules.home = {
    shell = {
      common.enable = mkEnableOption "common shell tools" // {
        default = true;
      };

      zsh.enable = mkEnableOption "zsh";
      starship.enable = mkEnableOption "starship";
      fetcher.package = mkOption {
        type = types.package;
        description = ''
          The fetcher package to use.
        '';
        example = pkgs.hyfetch;
        default = pkgs.nitch;
      };
    };
  };
  imports = [
    ./zsh
    ./starship
    ./common
  ];
}
