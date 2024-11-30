{ inputs, ... }:
{
  imports = [ inputs.flake-parts.flakeModules.easyOverlay ];
  perSystem =
    {
      pkgs,
      ...
    }:
    {
      overlayAttrs = {
        gdm = pkgs.gdm.overrideAttrs (oldAttrs: rec {
          patches = oldAttrs.patches or [ ] ++ [ ./patches/gdm-vt-allocation-race-condition-fix.patch ];
        });
      };
    };
}
