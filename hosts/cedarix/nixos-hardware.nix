{
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
    (_: prev: {
      makeModulesClosure = x: prev.makeModulesClosure (x // { allowMissing = true; });
      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (_: python-prev: {
          dbus-next = python-prev.dbus-next.overridePythonAttrs (_: {
            doCheck = false;
          });
        })
      ];
    })
  ];

  hardware.raspberry-pi."4" = {
    apply-overlays-dtmerge.enable = true;
    fkms-3d.enable = true;
  };

  networking = {
    useDHCP = lib.mkDefault true;
    networkmanager = {
      enable = true;
      wifi.powersave = false;
    };
  };

  services.openssh.enable = true;

  boot.supportedFilesystems.zfs = lib.mkForce false;
  sdImage.compressImage = false;

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

  system.stateVersion = "23.05";
}
