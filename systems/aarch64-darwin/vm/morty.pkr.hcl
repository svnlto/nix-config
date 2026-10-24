// Builds the `morty-work` golden image: a plain Zscaler appliance (NOT
// nix-managed). Packer's tart plugin owns clone -> boot -> SSH -> provision ->
// shutdown -> artifact -> cleanup-on-failure. Provisioning is bootstrap.sh
// (installs ZCC + guest agent + firewall + operator key on the stock base).
//
// Driven by `just build-work-vm <operator_pub> [force]`.

packer {
  required_plugins {
    tart = {
      version = "1.21.0"
      source  = "github.com/cirruslabs/tart"
    }
  }
}

variable "operator_pub" {
  type        = string
  description = "Path to the operator SSH public key to authorize on the VM"
}

variable "base" {
  type    = string
  // Immutable digest captured from the base clone (2026-10-24).
  default = "ghcr.io/cirruslabs/macos-sequoia-base@sha256:eee659985b01e4df2a6c0754bd8d25e54969933c43fdcd4edef8bea337b3d354"
}

source "tart-cli" "morty" {
  vm_base_name = var.base
  vm_name      = "morty-work"
  cpu_count    = 4
  memory_gb    = 8
  disk_size_gb = 80

  // admin/admin is the cirruslabs base default; it stays (local VM).
  ssh_username = "admin"
  ssh_password = "admin"
  ssh_timeout  = "300s"
  headless     = true
  // The tart builder stops the VM itself after provisioning; no shutdown_command.
}

build {
  sources = ["source.tart-cli.morty"]

  provisioner "file" {
    source      = var.operator_pub
    destination = "/tmp/operator.pub"
  }

  provisioner "file" {
    source      = "systems/aarch64-darwin/vm/bootstrap.sh"
    destination = "/tmp/bootstrap.sh"
  }

  provisioner "shell" {
    inline = ["sudo -n bash /tmp/bootstrap.sh"]
  }
}
