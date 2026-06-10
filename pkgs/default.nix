{ inputs, ... }:
{
  imports = [ inputs.flake-parts.flakeModules.easyOverlay ];
  perSystem =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      packages = lib.packagesFromDirectoryRecursive {
        inherit (pkgs) callPackage;
        directory = ./by-name;
      };
    in
    {
      inherit packages;
      overlayAttrs = config.packages;
    };
}
