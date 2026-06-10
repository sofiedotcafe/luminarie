resource "null_resource" "keys_mount" {
  for_each = { for k in var.keys : k.path => k }

  connection {
    type     = "ssh"
    user     = var.user
    host     = var.host
    password = var.password
  }

  provisioner "remote-exec" {
    inline = [
      # Source path on the live system
      "KEY_PATH=\"${each.value.path}\"",

      # /etc/ssh → /mnt/etc/ssh
      "SRC_DIR=\"$(dirname \"$KEY_PATH\")\"",
      "FILE_NAME=\"$(basename \"$KEY_PATH\")\"",
      "DST_DIR=\"/mnt$SRC_DIR\"",
      "DST_FILE=\"$DST_DIR/$FILE_NAME\"",

      # Ensure directory exists inside /mnt
      "mkdir -p \"$DST_DIR\"",

      # Ensure the target file exists before bind-mount
      "touch \"$DST_FILE\"",

      # Bind-mount the real key into the target filesystem
      "mount --bind \"$KEY_PATH\" \"$DST_FILE\"",

      # Apply permissions inside /mnt
      "chmod ${each.value.perms} \"$DST_FILE\""
    ]
  }
}

