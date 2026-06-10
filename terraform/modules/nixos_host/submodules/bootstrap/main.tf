data "external" "system" {
  count = var.host == "localhost" ? 0 : 1

  program = [
    "bash", "-lc",
<<EOF
set -euo pipefail
nix build ${var.flake}#nixosConfigurations.${var.hostname}.config.system.build.toplevel --no-link --extra-experimental-features "flakes nix-command"
SYSTEM_PATH=$(nix path-info ${var.flake}#nixosConfigurations.${var.hostname}.config.system.build.toplevel)
jq -n --arg system_path "$SYSTEM_PATH" '{system_path: $system_path}'
EOF
  ]
}

resource "null_resource" "enroll-boot-keys" {
  connection {
    type     = "ssh"
    host     = var.host
    user     = var.user
    password = var.password
    agent    = true
  }

  provisioner "remote-exec" {
    inline = concat([
<<EOF
chattr -i /sys/firmware/efi/efivars/*

nix-shell -p sbctl --run 'sbctl create-keys'
nohup sh -c "nix-shell -p sbctl --run 'sbctl enroll-keys --microsoft'" \
  > >(cat) 2> >(cat >&2) </dev/null

mkdir -p /mnt/var/lib/sbctl
if ! mountpoint -q /mnt/var/lib/sbctl; then
  mount --rbind /var/lib/sbctl /mnt/var/lib/sbctl
fi

cp -a /var/lib/sbctl/* /mnt/var/lib/sbctl/

DEVICES="$(lsblk -o NAME,FSTYPE -nr | awk '$2=="crypto_LUKS"{print "/dev/"$1}')"

if [ -n "$DEVICES" ]; then
  for dev in $DEVICES; do
    echo "[TPM] Processing device: $dev"
    systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 \
      --unlock-key-file /run/secrets/disks/disko_key "$dev"
    wait
  done
fi

EOF
], var.post-disko-hook != "" ? [var.post-disko-hook] : [])
  }
}

resource "null_resource" "bootstrap" {
  depends_on = [null_resource.enroll-boot-keys]

  connection {
    type     = "ssh"
    host     = var.host
    user     = var.user
    password = var.password
    agent    = true
  }

  provisioner "local-exec" {
    command = (
      var.host == "localhost"
        ? "echo 'Skipping nix-copy-closure on localhost'"
        : "set -euo pipefail; nix-copy-closure --to ${var.user}@${var.host} ${data.external.system[0].result.system_path}"
    )
  }

  provisioner "remote-exec" {
    inline = [
      var.host == "localhost"
        ? "git config --global --add safe.directory '${var.flake}' && nixos-install --no-root-password --root /mnt --flake '${var.flake}'#${var.hostname}"
        : "nixos-install --no-root-password --root /mnt --system ${data.external.system[0].result.system_path}"
    ]
  }
}

