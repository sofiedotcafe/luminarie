{ inputs, withSystem, ... }:
let
  inherit (inputs.nixpkgs.lib) nixosSystem;

  modules = [
    inputs.lanzaboote.nixosModules.lanzaboote
  ];

  mkSystem =
    system: arch: modules:
    withSystem arch (
      _:
      nixosSystem {
        specialArgs = {
          inherit inputs;
        };
        modules = [
          ../modules/nixos
          ./${system}
        ] ++ modules;
      }
    );
in
{
  flake.nixosConfigurations = {
    azalea = mkSystem "azalea" "x86_64-linux" modules;
    cedarix = mkSystem "cedarix" "aarch64-linux" modules;
  };
}
