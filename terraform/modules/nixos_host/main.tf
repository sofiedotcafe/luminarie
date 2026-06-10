locals {
  config_hash = sha1(jsonencode(var.config))
}

module "key_secrets" {
  source    = "./submodules/sops"
  sops_file = var.sops_file

  providers = {
    sops = sops
  }
}

module "keys" {
  source   = "./submodules/keys"
  host     = var.host
  user     = var.user
  password = var.password

  keys = [
    for k in var.keys : {
      key   = module.key_secrets.secrets[k.name]
      perms = k.perms
      path  = k.path
    }
  ]

  depends_on = [module.key_secrets]
}

module "disko" {
  source   = "./submodules/disko"
  host     = var.host
  user     = var.user
  flake    = var.flake
  hostname = var.hostname
  password = var.password

  depends_on = [module.keys]
}

module "keys-mount" {
  source   = "./submodules/keys/mount"
  host     = var.host
  user     = var.user
  password = var.password

  keys = [
    for k in var.keys : {
      key   = module.key_secrets.secrets[k.name]
      perms = k.perms
      path  = k.path
    }
  ]

  depends_on = [module.key_secrets, module.disko]
}

module "bootstrap" {
  source          = "./submodules/bootstrap"
  host            = var.host
  password        = var.password
  user            = var.user
  flake           = var.flake
  hostname        = var.hostname
  config_hash     = local.config_hash
  post-disko-hook = var.post-disko-hook

  depends_on = [module.key_secrets, module.disko, module.keys-mount]
}

resource "null_resource" "install_counter" {
  depends_on = [
    module.disko,
    module.keys,
    module.keys-mount,
    module.bootstrap
  ]

  triggers = {
    install_complete = timestamp()
  }
}

module "rebuild" {
  source = "./submodules/rebuild"

  host             = var.host
  user             = var.user
  password         = var.password
  flake            = var.flake
  hostname         = var.hostname
  config           = var.config
  install_complete = null_resource.install_counter.triggers.install_complete
}
