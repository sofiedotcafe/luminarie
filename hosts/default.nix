{
  inputs,
  sofLib,
  ...
}:
let
  inherit (sofLib) mkSystem;

  nixosModules = with inputs; [
    lanzaboote.nixosModules.lanzaboote
    impermanence.nixosModules.impermanence
    disko.nixosModules.disko
    sops-nix.nixosModules.sops
    nix-topology.nixosModules.default
  ];

  homeModules = with inputs; [
    catppuccin.homeModules.catppuccin
    qt-decorations.homeModules.qt-decorations
    arkenfox.hmModules.arkenfox
  ];
in
{
  flake.nixosConfigurations = {
    azalea = mkSystem {
      name = "azalea";
      hostPlatform = "x86_64-linux";

      inherit nixosModules homeModules;
    };

    olufsen = mkSystem {
      name = "olufsen";
      hostPlatform = "x86_64-linux";

      inherit nixosModules homeModules;
    };

    tailstack = mkSystem {
      name = "tailstack";
      hostPlatform = "x86_64-linux";

      inherit nixosModules;
    };

    cedarix = mkSystem {
      name = "cedarix";
      hostPlatform = "aarch64-linux";

      nixosModules =
        nixosModules
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
