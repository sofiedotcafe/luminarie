terraform {
  required_providers {
    sops = {
      source = "carlpett/sops"
    }
  }
}

data "sops_file" "secrets" {
  source_file = var.sops_file
}

locals {
  secrets = data.sops_file.secrets.data
}

output "secrets" {
  value     = local.secrets
  sensitive = true
}
