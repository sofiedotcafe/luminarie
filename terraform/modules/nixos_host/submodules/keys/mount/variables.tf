variable "host" {
  type = string
}

variable "user" {
  type = string
}

variable "password" {
  type = string
}

variable "keys" {
  type = list(object({
    key   = string
    perms = string
    path  = string
  }))
}
