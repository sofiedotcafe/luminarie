{ inputs, withSystem, ... }:
let
  inherit (inputs.home-manager.lib) homeManagerConfiguration;
in
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
)
