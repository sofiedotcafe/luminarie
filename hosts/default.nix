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
    azalea = mkSystem {
      name = "azalea";
      hostPlatform = "x86_64-linux";
      inherit modules;
    };
    cedarix = mkSystem {
      name = "cedarix";
      hostPlatform = "aarch64-linux";
      buildPlatform = "x86_64-linux";
      modules = modules ++ [ inputs.nixos-hardware.nixosModules.raspberry-pi-4 ];
    };
  };
}
