{ pkgs, ... }:
let
  initialPassphrase = "nixos";
  passwordFile = builtins.toString (pkgs.writeText "luks-passphrase" initialPassphrase);
in
{
  fileSystems."/persistent".neededForBoot = true;

  virtualisation.vmVariantWithDisko = {
    virtualisation.fileSystems."/persistent".neededForBoot = true;
  };

  disko.enableConfig = true;
  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/nvme0n1";

      content = {
        type = "gpt";
        partitions = {
          ESP = {
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

          luks = {
            size = "100%";
            content = {
              type = "luks";
              name = "cryptroot";
              inherit passwordFile;

              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
                mountpoint = "/btrfs";

                subvolumes = {
                  "@" = {
                    mountpoint = "/";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };

                  "@persistent" = {
                    mountpoint = "/persistent";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };

                  "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
