{ inputs, withSystem, ... }:
let
  inherit (inputs.nixpkgs.lib) nixosSystem;
  inherit (inputs.home-manager.lib) homeManagerConfiguration;
in
{
  /*
    Creates a NixOS configuration.

    Type: mkSystem :: string -> string -> list -> attrset

    Args:
      system: The name of the system (e.g., "x86_64-linux").
      arch: The architecture of the system (e.g., "x86_64").
      modules: A list of additional NixOS modules to include.

    Example:
      mkSystem "x86_64-linux" "x86_64" [ ./extra-module.nix ]
  */
  mkSystem =
    system: arch: modules:
    withSystem arch (
      { sofLib, ... }:
      nixosSystem {
        specialArgs = {
          inherit inputs sofLib;
        };
        modules = [
          "${inputs.self}/modules/nixos"
          "${inputs.self}/hosts/${system}"
        ] ++ modules;
      }
    );

  /*
    Creates a Home Manager configuration.

    Type: mkHome :: string -> string -> list -> attrset

    Args:
      user: The name of the user.
      arch: The architecture of the system (e.g., "x86_64").
      modules: A list of additional Home Manager modules to include.

    Example:
      mkHome "sofie" "x86_64" [ ./extra-home-module.nix ]
  */
  mkHome =
    user: arch: modules:
    withSystem arch (
      { pkgs, sofLib, ... }:
      homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          inherit inputs sofLib;
        };
        modules = [
          "${inputs.self}/modules/home"
          "${inputs.self}/home/${user}"
        ] ++ modules;
      }
    );
}
