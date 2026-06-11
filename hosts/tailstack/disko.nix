{ config, lib, ... }:

let
  inherit (lib) mapAttrsToList flatten filter;

  diskoCfg = config.disko.devices or { };

  luksDevices =
    let
      raw = flatten (
        mapAttrsToList (
          _: disk:
          let
            parts = disk.content.partitions or { };
          in
          mapAttrsToList (_: part: part.content.name or null) parts
        ) (diskoCfg.disk or { })
      );
    in
    filter (x: x != null) raw;

in
{
  boot.zfs.devNodes = "/dev/disk/by-id";
  boot.zfs.forceImportAll = true;
  boot.zfs.forceImportRoot = true;
  boot.kernel.sysctl."vfs.zfs.arc_max" = 224 * 1024 * 1024 * 1024;

  fileSystems."/persistent".neededForBoot = true;

  virtualisation.vmVariantWithDisko = {
    virtualisation.fileSystems."/persistent".neededForBoot = true;
  };

  systemd.units = builtins.listToAttrs (
    map (name: {
      name = "dev-mapper-${name}.device";
      value.text = ''
        [Unit]
        JobTimeoutSec=infinity
      '';
    }) luksDevices
  );

  disko.enableConfig = true;

  disko.devices = {
    disk = {
      usbEsp = {
        type = "disk";
        device = "/dev/disk/by-id/usb-Generic-_USB3.0_CRW_-SD_201404081410-0:0";
        content = {
          type = "gpt";
          partitions.ESP = {
            name = "usb-esp";
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [
                "umask=0077"
                "shortname=winnt"
              ];
            };
          };
        };
      };

      nvme0 = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-eui.0025385a21905a4e";
        content = {
          type = "gpt";
          partitions = {
            swap = {
              name = "swap";
              size = "32G";
              type = "8200";
              content = {
                type = "luks";
                name = "crypt-swap";
                passwordFile = "/run/secrets/zfs_key";
                content.type = "swap";
              };
            };

            rpool = {
              name = "disk-nvme0-rpool";
              size = "100%";
              content = {
                type = "luks";
                name = "crypt-rpool-nvme0";
                passwordFile = "/run/secrets/zfs_key";
                content = {
                  type = "zfs";
                  pool = "rpool";
                };
              };
            };
          };
        };
      };

      nvme1 = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-eui.0025385791b0f60b";
        content = {
          type = "gpt";
          partitions = {
            slog = {
              name = "dpool-slog";
              size = "16G";
              type = "BF08";
              content = {
                type = "zfs";
                pool = "dpool";
              };
            };

            l2arc = {
              name = "dpool-l2arc";
              size = "64G";
              type = "BF08";
              content = {
                type = "zfs";
                pool = "dpool";
              };
            };

            rpool = {
              name = "rpool";
              size = "100%";
              content = {
                type = "luks";
                name = "crypt-rpool-nvme1";
                passwordFile = "/run/secrets/zfs_key";
                content = {
                  type = "zfs";
                  pool = "rpool";
                };
              };
            };
          };
        };
      };

      hdd0 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-ST8000NT001-3LZ101_WWZ21H1Y";
        content = {
          type = "gpt";
          partitions.dpool = {
            name = "disk-hdd0-dpool";
            size = "100%";
            content = {
              type = "luks";
              name = "crypt-dpool-hdd0";
              passwordFile = "/run/secrets/zfs_key";
              content = {
                type = "zfs";
                pool = "dpool";
              };
            };
          };
        };
      };

      hdd1 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-ST8000NT001-3LZ101_WWZ21PC0";
        content = {
          type = "gpt";
          partitions.dpool = {
            name = "disk-hdd1-dpool";
            size = "100%";
            content = {
              type = "luks";
              name = "crypt-dpool-hdd1";
              passwordFile = "/run/secrets/zfs_key";
              content = {
                type = "zfs";
                pool = "dpool";
              };
            };
          };
        };
      };

      hdd2 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-ST8000NT001-3LZ101_WWZB2NP0";
        content = {
          type = "gpt";
          partitions.dpool = {
            name = "disk-hdd2-dpool";
            size = "100%";
            content = {
              type = "luks";
              name = "crypt-dpool-hdd2";
              passwordFile = "/run/secrets/zfs_key";
              content = {
                type = "zfs";
                pool = "dpool";
              };
            };
          };
        };
      };
    };

    zpool = {
      rpool = {
        type = "zpool";
        mode = "mirror";

        rootFsOptions = {
          compression = "zstd";
          atime = "off";
        };

        datasets = {
          "local" = {
            type = "zfs_fs";
            options = {
              compression = "zstd";
              atime = "off";
            };
          };

          "local/root" = {
            type = "zfs_fs";
            mountpoint = "/";
            options = {
              compression = "zstd";
              atime = "off";
            };
          };

          "nix" = {
            type = "zfs_fs";
            mountpoint = "/nix";
            options = {
              compression = "zstd";
              atime = "off";
            };
          };

          "persistent" = {
            type = "zfs_fs";
            mountpoint = "/persistent";
            options = {
              compression = "zstd";
              atime = "off";
            };
          };

          "reserved" = {
            type = "zfs_fs";
            mountpoint = null;
            options = {
              refreservation = "10G";
              compression = "zstd";
              atime = "off";
            };
          };
        };
      };

      dpool = {
        type = "zpool";

        mode = {
          topology = {
            type = "topology";

            vdev = [
              {
                mode = "raidz1";
                members = [
                  "/dev/mapper/crypt-dpool-hdd0"
                  "/dev/mapper/crypt-dpool-hdd1"
                  "/dev/mapper/crypt-dpool-hdd2"
                ];
              }
            ];

            log = [
              {
                members = [
                  "/dev/disk/by-partlabel/disk-nvme1-dpool-slog"
                ];
              }
            ];

            cache = [
              "/dev/disk/by-partlabel/disk-nvme1-dpool-l2arc"
            ];
          };
        };

        rootFsOptions = {
          compression = "zstd";
          atime = "off";
        };

        datasets = {
          "data" = {
            type = "zfs_fs";
            mountpoint = "/data";
            options = {
              compression = "zstd";
              atime = "off";
              mountOptions = [ "nofail" ];
            };
          };

          "backup" = {
            type = "zfs_fs";
            mountpoint = "/backup";
            options = {
              compression = "zstd";
              atime = "off";
              mountOptions = [ "nofail" ];
            };
          };

          "reserved" = {
            type = "zfs_fs";
            mountpoint = null;
            options = {
              refreservation = "10G";
              compression = "zstd";
              atime = "off";
              mountOptions = [ "nofail" ];
            };
          };
        };
      };
    };
  };
}
