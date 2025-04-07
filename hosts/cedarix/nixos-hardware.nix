{
  lib,
  modulesPath,
  pkgs,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/sd-card/sd-image-aarch64.nix")
    (modulesPath + "/profiles/minimal.nix")
  ];

  disabledModules = [ "profiles/base.nix" ];

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

  environment.systemPackages = with pkgs; [
    libraspberrypi
    raspberrypi-eeprom
  ];

  boot.blacklistedKernelModules = [ "brcmfmac" ]; # Disable built-in WiFi

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 90;
  };

  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
  sdImage.compressImage = false;

  system.stateVersion = "23.05";
}
