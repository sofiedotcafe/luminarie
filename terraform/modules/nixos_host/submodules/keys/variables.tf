variable "keys" {
  type = list(object({
    key  = string
    perms = string
    path = string
  }))
}

variable "host" {}
variable "user" {}
variable "password" {}