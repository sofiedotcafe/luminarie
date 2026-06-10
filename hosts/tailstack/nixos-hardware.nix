{
  config,
  lib,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot = {
    initrd = {
      systemd.enable = true;

      availableKernelModules = [
        "ahci"
        "xhci_pci"
        "ehci_pci"

        "nvme"
        "mpt3sas"

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
    kernelParams = [ "nomodeset" ];
  };

  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
