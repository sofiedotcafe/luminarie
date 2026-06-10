{
  config,
  lib,
  modulesPath,
  pkgs,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 8 * 1024;
    }
  ];

  boot = {
    initrd = {
      systemd.enable = true;

      availableKernelModules = [
        "ahci"
        "xhci_pci"

        "thunderbolt"
        "nvme"

        "usbhid"
        "usb_storage"
        "sd_mod"

        "aesni_intel"
        "cryptd"

        "tpm"
        "tpm_tis"
        "tpm_crb"
      ];

      kernelModules = [
        "dm-snapshot"
      ];
    };
    loader = {
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
      systemd-boot = {
        enable = lib.mkForce false;
        consoleMode = "max";
      };
      timeout = 3;
    };

    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };
    plymouth.enable = true;
  };

  environment.systemPackages = [
    pkgs.sbctl
    pkgs.git
  ];

  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  networking.useDHCP = lib.mkDefault true;
  networking.networkmanager.enable = true;
}
