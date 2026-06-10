resource "null_resource" "deploy_keys" {
  for_each = { for k in var.keys : k.path => k }

  connection {
    type     = "ssh"
    user     = var.user
    host     = var.host
    password = var.password
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p $(dirname ${each.value.path})/"
    ]
  }

  provisioner "file" {
    content     = each.value.key
    destination = each.value.path
  }

  provisioner "remote-exec" {
    inline = [
      "chmod ${each.value.perms} ${each.value.path}"
    ]
  }
}
