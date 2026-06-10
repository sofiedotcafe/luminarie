data "external" "git_root" {
  program = [
    "bash",
    "-lc",
    "git rev-parse --show-toplevel | jq -R '{root: .}'"
  ]
}

module "tailstack" {
  source = "../../modules/nixos_host"

  host       = "10.0.0.2"
  user       = "root"
  password   = "nixos"

  post-disko-hook = "zfs snapshot rpool/local/root@blanket"

  sops_file = "${data.external.git_root.result.root}/secrets/tailstack.yaml"

  hostname  = "tailstack"
  flake = "${data.external.git_root.result.root}"

  providers = { sops = sops }

  keys = [
    {
      name  = "users.root.password_hash"
      perms = "0600"
      path  = "/run/secrets/users/root/password_hash"
    },
    {
      name  = "disks.disko_key"
      perms = "0600"
      path  = "/run/secrets/disks/disko_key"
    },
    {
      name  = "ssh.ssh_host_ed25519_key"
      perms = "0600"
      path  = "/etc/ssh/ssh_host_ed25519_key"
    },
    {
      name  = "ssh.ssh_host_ed25519_key.pub"
      perms = "0644"
      path  = "/etc/ssh/ssh_host_ed25519_key.pub"
    }
  ]

  config = {
    flake = "github:sofiedotcafe/luminarie/staging"
  }
}
