{
  config,
  lib,
  modulesPath,
  ...
}:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot = {
    kernelModules = [ "kvm-amd" ];

    initrd = {
      systemd = {
        enable = true;

        units."dev-mapper-vg\\x2droot.device".text = ''
          [Unit]
          JobTimeoutSec=infinity
        '';
      };

      availableKernelModules = [
        "ahci"
        "xhci_pci"
        "thunderbolt"
        "nvme"
        "usbhid"
        "usb_storage"

        "aesni_intel"
        "cryptd"
      ];

      kernelModules = [ "dm-snapshot" ];

      luks.devices = {
        root = {
          device = "/dev/disk/by-uuid/b040ecb2-e127-4405-a351-4afd09da334b";
          preLVM = true;
        };
      };
    };

    kernel.sysctl = {
      "vm.max_map_count" = 16777216;
      "fs.file-max" = 524288;
    };
  };

  fileSystems = {
    "/" = {
      device = "/dev/mapper/vg-root";
      fsType = "btrfs";
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/9D64-EA9A";
      fsType = "vfat";
    };
  };

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 16 * 1024;
    }
  ];

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
