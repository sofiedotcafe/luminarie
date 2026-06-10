{ inputs, withSystem, ... }:
let
  inherit (inputs.nixpkgs.lib) nixosSystem;
in
{
  /*
    Creates a NixOS configuration.

    Type: mkSystem :: {
      name: string,
      hostPlatform: string,
      buildPlatform?: string,
      nixosModules?: list,
      homeModules?: list
    } -> attrset

    Args:
      name:
        The system name (e.g., "laptop").

      hostPlatform:
        The target platform string (e.g., "x86_64-linux").

      buildPlatform:
        (Optional) The build platform string.
        Defaults to hostPlatform.

      nixosModules:
        A list of additional NixOS modules to include in the system
        configuration. These are appended to the system’s module list.

      homeModules:
        A list of Home Manager modules that will be applied to *all*
        Home Manager users on this system via `home-manager.sharedModules`.

    Example:
      mkSystem {
        name = "laptop";
        hostPlatform = "x86_64-linux";

        nixosModules = [
          ./extra-nixos-module.nix
        ];

        homeModules = [
          ./extra-home-module.nix
        ];
      }
  */
  mkSystem =
    {
      name,
      hostPlatform,
      buildPlatform ? hostPlatform,
      nixosModules ? [ ],
      homeModules ? [ ],
    }:
    withSystem hostPlatform (
      { sofLib, ... }:
      nixosSystem {
        specialArgs = {
          inherit inputs sofLib;
        };

        modules = [
          {
            nixpkgs = {
              inherit hostPlatform buildPlatform;
            };
          }

          "${inputs.self}/modules/nixos"
          "${inputs.self}/hosts/${name}"

          inputs.home-manager.nixosModules.home-manager

          {
            home-manager = {
              # useGlobalPkgs = true;
              useUserPackages = true;

              extraSpecialArgs = { inherit inputs sofLib; };

              sharedModules = [
                "${inputs.self}/modules/home"
              ]
              ++ homeModules;
            };
          }
        ]
        ++ nixosModules;
      }
    );
}
