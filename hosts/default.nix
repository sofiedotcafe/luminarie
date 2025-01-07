{
  inputs,
  sofLib,
  ...
}:
let
  inherit (sofLib) mkSystem;

  inherit (inputs.lanzaboote.nixosModules) lanzaboote;
  modules = [
    lanzaboote
  ];
in
{
  flake.nixosConfigurations = {
    azalea = mkSystem "azalea" "x86_64-linux" modules;
    cedarix = mkSystem "cedarix" "aarch64-linux" modules;
  };
}
