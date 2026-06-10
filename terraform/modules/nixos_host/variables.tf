variable "host" {
  type = string
}

variable "user" {
  type = string
}

variable "hostname" {
  type = string
}

variable "password" {
  type = string
}

variable "flake" {
  type = string
}

variable "keys" {
  type = list(object({
    name  = string
    perms = string
    path  = string
  }))
}

variable "sops_file" {
  type = string
}

variable "config" {
  type = any
}

variable "post-disko-hook" {
  type = string
  default = ""
}