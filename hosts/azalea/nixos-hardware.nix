{
  config,
  lib,
  modulesPath,
  pkgs,
  ...
}:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    kernelModules = [ "kvm-amd" ];

    kernelPatches = [
      {
        name = "mt7922-func-ctrl-fix";
        patch = pkgs.fetchpatch {
          url = "https://lore.kernel.org/linux-mediatek/20260514-bluetooh-fix-mt7922-v1-1-499c878af1e5@zohomail.in/raw";
          hash = "sha256-JHUGOYK4Wk3VIIl3nM73YYe+odrTOf5tcLg7ZjGRYGs=";
        };
      }
    ];

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
      size = 32 * 1024;
    }
  ];

  boot = {
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

  services.fwupd.enable = true;

  environment.systemPackages = [
    pkgs.git
    pkgs.sbctl

  ];

  hardware = {
    graphics.extraPackages = with pkgs; [
      rocmPackages.clr.icd
    ];
    enableRedistributableFirmware = true;
    cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  };

  networking.useDHCP = lib.mkDefault true;
  networking.networkmanager.enable = true;

}
