{ inputs, ... }:
{
  imports = [ inputs.flake-parts.flakeModules.easyOverlay ];
  perSystem =
    {
      system,
      ...
    }:
    {
      overlayAttrs = {
        inherit (inputs.nixpkgs-stable.legacyPackages.${system}) plymouth;
      };
    };
}
