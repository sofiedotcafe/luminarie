{ config, pkgs, lib, inputs, modulesPath, ... }:
{
  imports = [
    (inputs.nixos-hardware + "/raspberry-pi/4")
    (modulesPath + "/installer/sd-card/sd-image-raspberrypi.nix")
  ];

  nixpkgs.overlays = [
    (final: super: {
    makeModulesClosure = x:
      super.makeModulesClosure (x // { allowMissing = true; });
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

  security.polkit.enable = true;
  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

  system.stateVersion = "23.05";
}
