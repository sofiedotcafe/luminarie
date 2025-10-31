{
  inputs,
  sofLib,
  ...
}:
let
  inherit (sofLib) mkSystem;

  modules = with inputs; [
    lanzaboote.nixosModules.lanzaboote
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
      modules =
        modules
        ++ (
          with inputs;
          with nixos-raspberrypi.nixosModules;
          [
            {
              disabledModules = [ "system/boot/loader/raspberrypi.nix" ];
            }

            raspberry-pi-4.base
            raspberry-pi-4.display-vc4
            nixos-raspberrypi.lib.inject-overlays
          ]
        );
    };
  };
}
