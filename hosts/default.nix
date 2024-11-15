{ inputs, withSystem, ... }:
let
  inherit (inputs.nixpkgs.lib) nixosSystem;
in
{
  flake.nixosConfigurations = {
    aisu = withSystem "x86_64-linux" (
      _:
      nixosSystem {
        specialArgs = {
          inherit inputs;
        };
        modules = [
          inputs.nixos-cosmic.nixosModules.default
          inputs.lanzaboote.nixosModules.lanzaboote
          ../modules/nixos
          ./aisu
        ];
      }
    );
  };
}
