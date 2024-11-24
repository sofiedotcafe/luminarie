{
  lib,
  pkgs,
  ...
}:
with lib;
{
  options.modules.home = {
    shell = {
      common.enable = mkEnableOption "common shell tools";
      starship.enable = mkEnableOption "starship";
      fetcher.package = mkOption {
        type = types.package;
        description = ''
          The fetcher package to use.
        '';
        example = pkgs.hyfetch;
        default = pkgs.nitch;
      };
      package = mkOption {
        type = types.package;
        description = ''
          The shell package to use.
        '';
        example = pkgs.bash;
        default = pkgs.zsh;
      };
    };
  };
  imports = [
    ./zsh
    ./starship
    ./common
  ];
}
