resource "null_resource" "rebuild" {
  triggers = {
    config_hash      = sha1(jsonencode(var.config))
    install_complete = var.install_complete
  }

  provisioner "local-exec" {
    command = "nixos-rebuild switch --flake ${var.flake}#${var.hostname} --target-host ${var.user}@${var.host}"
  }
}
