{ inputs, withSystem, ... }:
let
  inherit (inputs.nixpkgs.lib) nixosSystem;
  inherit (inputs.home-manager.lib) homeManagerConfiguration;
in
{
  /*
    Creates a NixOS configuration.

    Type: mkSystem :: {
      name: string,
      hostPlatform: string,
      buildPlatform?: string,
      modules?: list
    } -> attrset

    Args:
      name: The system name (e.g., "laptop").
      hostPlatform: The target platform string (e.g., "x86_64-linux").
      buildPlatform: (Optional) The build platform string. Defaults to hostPlatform.
      modules: Extra NixOS modules to include.

    Example:
      mkSystem {
        name = "laptop";
        hostPlatform = "x86_64-linux";
        modules = [ ./extra.nix ];
      }
  */
  mkSystem =
    {
      name,
      hostPlatform,
      buildPlatform ? hostPlatform,
      modules ? [ ],
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
        ] ++ modules;
      }
    );

  /*
    Creates a Home Manager configuration.

    Type: mkHome :: {
      name: string,
      system: string,
      modules?: list
    } -> attrset

    Args:
      name: The username (e.g., "sofie").
      system: The system architecture (e.g., "x86_64-linux").
      modules: A list of additional Home Manager modules.

    Example:
      mkHome {
        name = "sofie";
        system = "x86_64-linux";
        modules = [ ./extra-home.nix ];
      }
  */
  mkHome =
    {
      name,
      system,
      modules ? [ ],
    }:
    withSystem system (
      { pkgs, sofLib, ... }:
      homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          inherit inputs sofLib;
        };
        modules = [
          "${inputs.self}/modules/home"
          "${inputs.self}/home/${name}"
        ] ++ modules;
      }
    );
}
