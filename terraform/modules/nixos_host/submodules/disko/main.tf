data "external" "disko" {
  program = [
    "bash", "-lc",
    <<EOF
      nix build "${var.flake}"#nixosConfigurations.${var.hostname}.config.system.build.diskoScript --no-link --extra-experimental-features "flakes nix-command"
      DISKO_PATH=$(nix path-info "${var.flake}"#nixosConfigurations.${var.hostname}.config.system.build.diskoScript --extra-experimental-features "flakes nix-command")

      jq -n --arg disko_path "$DISKO_PATH" '{disko_path: $disko_path}'
    EOF
  ]
}

resource "null_resource" "run_disko" {
  connection {
    type     = "ssh"
    host     = var.host
    user     = var.user
    password = var.password
    agent    = true
  }

  provisioner "local-exec" {
    command = "nix-copy-closure --to ${var.user}@${var.host} ${data.external.disko.result.disko_path}"
  }

  provisioner "remote-exec" {
    inline = [
      "set -euo pipefail",
      "${data.external.disko.result.disko_path}"
    ]
  }
}
