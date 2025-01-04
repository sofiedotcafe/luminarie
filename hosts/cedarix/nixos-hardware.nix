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

  # hardware.deviceTree = {
  #  enable = true;
  #  overlays = map (dtsFile: {
  #    name = lib.removeSuffix ".dts" (builtins.baseNameOf dtsFile);
  #    inherit dtsFile;
  #  }) (lib.filesystem.listFilesRecursive ./firmware/overlays);
  # };

  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_latest;

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
