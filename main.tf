terraform {
  required_providers {
    contabo = {
      source  = "contabo/contabo"
      version = ">= 0.1.25"
    }
  }
}

provider "contabo" {
  oauth2_client_id     = var.contabo_client_id
  oauth2_client_secret = var.contabo_client_secret
  oauth2_user          = var.contabo_user
  oauth2_pass          = var.contabo_pass
}

data "contabo_image" "ubuntu_23_10" {
  id = "84b3b568-d7c9-48a4-9c07-2e328598caec"
}

resource "contabo_secret" "ssh_public_key" {
  name  = "veritas@veritas-m1-pro"
  type  = "ssh"
  value = <<EOF
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICrfs2dvR3gQxhvtdU6ERB9ZY6Lo+6KN4p4d0Iy676Bm veritas@veritas-m1-pro
  EOF
}

resource "contabo_instance" "next_cloud" {
  existing_instance_id = "201678959"
  cancel_date          = null
  display_name         = "Next Cloud Server"
  product_id           = "V51"
  ssh_keys             = [contabo_secret.ssh_public_key.id]
  region               = "EU"
  image_id             = data.contabo_image.ubuntu_23_10.id
}

locals {
  ipv4 = contabo_instance.next_cloud.ip_config[0].v4[0].ip
}

module "install" {
  source             = "github.com/nix-community/nixos-anywhere//terraform/install"
  target_user        = "admin"
  target_host        = local.ipv4
  instance_id        = local.ipv4
  debug_logging      = true
  build_on_remote    = true
  flake              = ".#next-cloud"
  extra_files_script = "extra_files_script.sh"
}

resource "null_resource" "nixos-rebuild" {
  depends_on = [
    module.install
  ]
  triggers = {
    flake_nix_sha         = "${sha1(file("flake.nix"))}"
    flake_lock_sha        = "${sha1(file("flake.lock"))}"
    configuration_nix_sha = "${sha1(file("configuration.nix"))}"
  }
  provisioner "local-exec" {
    environment = {
      NIX_SSHOPTS                = "-oStrictHostKeyChecking=accept-new "
      NIXOS_SWITCH_USE_DIRTY_ENV = "1"
    }
    command = <<EOF
        nixos-rebuild switch --fast --flake .#next-cloud --target-host root@${local.ipv4} --build-host root@${local.ipv4}
    EOF
  }
}
