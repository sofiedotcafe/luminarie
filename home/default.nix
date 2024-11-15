{ inputs, withSystem, ... }:
let
  inherit (inputs.home-manager.lib) homeManagerConfiguration;
in
{
  flake.homeConfigurations."jh-devv@aisu" = withSystem "x86_64-linux" (
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
        ./jh-devv
      ];
    }
  );
}
