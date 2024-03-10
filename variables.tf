variable "contabo_client_id" {
  type = string
}

variable "contabo_client_secret" {
  type = string
}

variable "contabo_user" {
  type = string
}

variable "contabo_pass" {
  type = string
}

variable "nixos_version" {
  type    = string
  default = "23.11"
}

variable "nixos_system" {
  type    = string
  default = "x86_64-linux"
}
