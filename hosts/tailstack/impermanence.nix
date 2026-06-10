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
      "/var/lib/nixos-containers"

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
  };

  systemd.tmpfiles.rules = [
    "f /var/lib/systemd/random-seed 0600 root root -"
  ];

  boot.initrd.systemd.storePaths = with pkgs; [
    zfs
  ];
  boot.initrd.systemd.services.zfs-rotate-root = {
    description = "Rotate ZFS root into boot environment and prune old ones";
    wantedBy = [ "initrd.target" ];
    after = [ "zfs-import.target" ];

    serviceConfig = {
      Type = "oneshot";
    };

    script = ''
      zfs rollback -r rpool/local/root@blanket
    '';
  };
}
