{
  pkgs,
  ...
}:
{
  environment.persistence."/persistent" = {
    enable = true;
    hideMounts = true;

    directories = [
      "/var/log"
      "/var/lib/bluetooth"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/etc/NetworkManager/system-connections"
      "/etc/nixos"

      {
        directory = "/var/lib/sbctl";
        mode = "0700";
      }

      {
        directory = "/etc/ssh";
        mode = "0700";
      }
    ];

    files = [
      "/etc/machine-id"
      "/var/lib/systemd/random-seed"
    ];

    users.sofie = {
      directories = [
        "Downloads"
        "Music"
        "Pictures"
        "Documents"
        "Videos"

        {
          directory = ".ssh";
          mode = "0700";
        }
        {
          directory = ".local/share/keyrings";
          mode = "0700";
        }
        {
          directory = ".mozilla";
          mode = "0700";
        }

        ".config/dconf"
        ".local/share/direnv"
      ];
    };
  };

  systemd.tmpfiles.rules = [
    "f /var/lib/systemd/random-seed 0600 root root -"
  ];

  boot.initrd.systemd.storePaths = with pkgs; [
    util-linux
    btrfs-progs
    findutils
    coreutils
    gawk
  ];

  boot.initrd.systemd.services.rotate-btrfs-root = {
    enable = true;
    description = "Rotate Btrfs root subvolume and prune root";

    wantedBy = [ "initrd.target" ];
    after = [ "cryptsetup.target" ];

    serviceConfig = {
      Type = "oneshot";
    };

    script = ''
      set -euo pipefail

      mkdir -p /btrfs_tmp
      mount -o subvolid=5 /dev/mapper/cryptroot /btrfs_tmp

      ROOT="/btrfs_tmp/@"

      delete_subvolume_recursively() {
        IFS=$'\n'
        for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
          delete_subvolume_recursively "/btrfs_tmp/$i"
        done
        btrfs subvolume delete "$1"
      }

      if [[ -e "$ROOT" ]]; then
        delete_subvolume_recursively "$ROOT"
      fi

      btrfs subvolume create "$ROOT"
      umount /btrfs_tmp
    '';
  };
}
