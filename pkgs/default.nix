{ inputs, ... }:
{
  imports = [ inputs.flake-parts.flakeModules.easyOverlay ];
  perSystem =
    { config, pkgs, ... }:
    {
      overlayAttrs = {
        inherit (config.packages) firefox-gnome-theme dark-reader stardrop;
      };
      packages = {
        firefox-gnome-theme = pkgs.callPackage ./firefox-gnome-theme/package.nix { };
      };
    };
}
