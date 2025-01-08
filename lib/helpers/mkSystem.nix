{ inputs, withSystem, ... }:
let
  inherit (inputs.nixpkgs.lib) nixosSystem;
in
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
)
