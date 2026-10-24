// Builds the `morty-work` golden image: a Zscaler-only appliance VM.
// Packer's tart plugin owns clone -> boot -> SSH -> provision -> shutdown ->
// artifact -> cleanup-on-failure. Provisioning content lives in bootstrap.sh.
//
// Driven by `just build-work-vm <rev> <operator_pub> [force]`, which pins the
// provisioner script to a git commit and runs `packer init && packer build`.
// The real build is gated on the Phase 0 spike passing and on the `#morty`
// flake host existing.

packer {
  required_plugins {
    tart = {
      version = "1.21.0"
      source  = "github.com/cirruslabs/tart"
    }
  }
}

variable "rev" {
  type        = string
  description = "Git commit the provisioner clones/switches to"
}

variable "bootstrap" {
  type        = string
  description = "Path to bootstrap.sh extracted at <rev>"
}

variable "operator_pub" {
  type        = string
  description = "Path to the operator SSH public key to authorize for svenlito"
}

variable "base" {
  type    = string
  // Immutable digest captured from the Phase 0 spike clone (2026-10-24).
  default = "ghcr.io/cirruslabs/macos-sequoia-base@sha256:eee659985b01e4df2a6c0754bd8d25e54969933c43fdcd4edef8bea337b3d354"
}

source "tart-cli" "morty" {
  vm_base_name = var.base
  vm_name      = "morty-work"
  cpu_count    = 4
  memory_gb    = 8
  disk_size_gb = 80

  // admin/admin is the cirruslabs base default; it is the build communicator and
  // must survive the build (the first-boot daemon removes it on the daily clone).
  ssh_username = "admin"
  ssh_password = "admin"
  ssh_timeout  = "300s"
  headless     = true

  shutdown_command = "sudo shutdown -h now"
}

build {
  sources = ["source.tart-cli.morty"]

  provisioner "file" {
    source      = var.operator_pub
    destination = "/tmp/operator.pub"
  }

  provisioner "file" {
    source      = var.bootstrap
    destination = "/tmp/bootstrap.sh"
  }

  provisioner "shell" {
    inline = ["sudo -n env REV=${var.rev} bash /tmp/bootstrap.sh"]
  }
}
