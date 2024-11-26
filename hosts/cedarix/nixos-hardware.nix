{
  pkgs,
  lib,
  inputs,
  modulesPath,
  ...
}:
{
  imports = [
    (inputs.nixos-hardware + "/raspberry-pi/4")
    (modulesPath + "/installer/sd-card/sd-image-aarch64.nix")
  ];

  nixpkgs.overlays = [
    (prev: super: {
      makeModulesClosure = x: super.makeModulesClosure (x // { allowMissing = true; });
      klipper-firmware = prev.klipper-firmware.overrideAttrs (_: {
        installPhase = ''
          mkdir -p $out
          cp ./.config $out/config
          cp -r out/* $out
        '';
      });
    })
  ];

  hardware.raspberry-pi."4" = {
    apply-overlays-dtmerge.enable = true;
    fkms-3d.enable = true;
  };

  environment.systemPackages = with pkgs; [
    libraspberrypi
    raspberrypi-eeprom
  ];

  networking = {
    useDHCP = lib.mkDefault true;
    networkmanager = {
      enable = true;
      wifi.powersave = false;
    };
  };

  security.polkit.enable = true;
  services.openssh.enable = true;

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

  system.stateVersion = "23.05";
}
