{
  inputs,
  sofLib,
  ...
}:
let
  inherit (sofLib) mkSystem;

  modules = with inputs; [
    lanzaboote.nixosModules.lanzaboote
    lix.nixosModules.default
  ];
in
{
  flake.nixosConfigurations = {
    azalea = mkSystem "azalea" "x86_64-linux" modules;
    cedarix = mkSystem "cedarix" "aarch64-linux" (
      modules ++ [ inputs.nixos-hardware.nixosModules.raspberry-pi-4 ]
    );
  };
}
