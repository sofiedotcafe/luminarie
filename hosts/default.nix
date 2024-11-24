{ inputs, withSystem, ... }:
let
  inherit (inputs.nixpkgs.lib) nixosSystem;

  mkSystem =
    system: arch:
    withSystem arch (
      _:
      nixosSystem {
        specialArgs = {
          inherit inputs;
        };
        modules = [
          inputs.lanzaboote.nixosModules.lanzaboote
          ../modules/nixos
          ./${system}
        ];
      }
    );
in
{
  flake.nixosConfigurations = {
    azalea = mkSystem "azalea" "x86_64-linux";
    cedarix = mkSystem "cedarix" "aarch64-linux";
  };
}
