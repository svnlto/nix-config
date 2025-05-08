{ config, pkgs, lib, ... }:

{
  # Development tools directly installed via Nix (no Linuxbrew)
  home.packages = with pkgs; [
    # Core development tools
    git
    gnumake
    gcc
    gnused
    gawk

    # Terraform tools
    terraform-docs
    terraform-ls
    tfenv # Using our overlay

    # Node.js tools
    nvm # Using our overlay

    # Additional useful tools
    kubectl
    kubernetes-helm
    tree
    wget
    jq

    # Development utilities
    pre-commit
  ];

  # Set up direnv integration
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };
}
