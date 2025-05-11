packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.5"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "aws_region" {
  type    = string
  default = "ap-southeast-1"
}

variable "instance_type" {
  type    = string
  default = "t4a.micro"
}

variable "ami_name" {
  type    = string
  default = "nix-ec2-{{timestamp}}"
}

variable "ssh_username" {
  type    = string
  default = "ubuntu"
}

variable "aws_profile" {
  type    = string
  default = "default"
  description = "AWS profile to use for authentication"
}

source "amazon-ebs" "nixos" {
  ami_name        = var.ami_name
  profile         = var.aws_profile
  instance_type   = var.instance_type
  region          = var.aws_region

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-24.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"] # Canonical
  }

  ssh_username = var.ssh_username

  tags = {
    Name        = "NixOS Environment"
    Environment = "Development"
    Provisioner = "Packer"
  }
}

build {
  name    = "nix-environment"
  sources = ["source.amazon-ebs.nixos"]

  # Install Nix package manager
  provisioner "shell" {
    inline = [
      "sudo mkdir -p /etc/nix",
      "echo 'build-users-group =' | sudo tee /etc/nix/nix.conf",
      "echo 'experimental-features = nix-command flakes' | sudo tee -a /etc/nix/nix.conf",
      "curl -L https://nixos.org/nix/install | sh -s -- --daemon --yes",
      "source /etc/profile.d/nix.sh"
    ]
  }

  # Clone your configuration
  provisioner "shell" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install -y git",
      "mkdir -p ~/.config",
      "git clone https://github.com/svnlto/nix-config.git ~/.config/nix"
    ]
  }

  # Set up home-manager with your configuration
  provisioner "shell" {
    inline = [
      ". /etc/profile.d/nix.sh",
      "nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager",
      "nix-channel --update",
      "export NIX_PATH=$HOME/.nix-defexpr/channels:/nix/var/nix/profiles/per-user/root/channels${NIX_PATH:+:$NIX_PATH}",
      "cd ~/.config/nix",
      # do this once we have a working nix config for EC2
      #"nix --experimental-features 'nix-command flakes' run home-manager/master -- switch --flake .#ec2"
    ]
  }

  # Install any additional packages or configurations
  provisioner "file" {
    source      = "../common/zsh/default.omp.json"
    destination = "/home/${var.ssh_username}/.config/oh-my-posh/default.omp.json"
  }

  # Install Oh My Posh for Zsh
  provisioner "shell" {
    inline = [
      "sudo apt-get install -y zsh",
      "chsh -s $(which zsh)",
      "curl -s https://ohmyposh.dev/install.sh | bash -s -- --shell zsh"
    ]
  }

  # Final cleanup
  provisioner "shell" {
    inline = [
      "sudo apt-get clean",
      "sudo rm -rf /var/lib/apt/lists/*"
    ]
  }
}
