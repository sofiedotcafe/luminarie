{ inputs, withSystem, ... }:
let
  inherit (inputs.home-manager.lib) homeManagerConfiguration;

  mkHomeConfig =
    user: arch:
    withSystem arch (
      { pkgs, ... }:
      homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          inherit inputs;
        };
        modules = [
          inputs.catppuccin.homeManagerModules.catppuccin
          inputs.arkenfox.hmModules.arkenfox
          ../modules/home
          ./${user}
        ];
      }
    );
in
{
  flake.homeConfigurations."sofie@azalea" = mkHomeConfig "sofie" "x86_64-linux";
}
