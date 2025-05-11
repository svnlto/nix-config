{ config, pkgs, username, lib, ... }:

{
  imports = [
    ../../common/home-packages.nix
    ./zsh.nix
    ./git.nix
    ./aws.nix
    ./user-scripts.nix
    ./ramdisk.nix
    ./github.nix
    ./rclone.nix
  ];

  # Explicitly tell home-manager not to manage nix.conf
  xdg.configFile."nix/nix.conf".enable = false;

  nixpkgs.config.allowUnfree = true;

  # Add to your nix.conf or as nix.settings in configuration
  nix.settings = {
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  # Vagrant-specific packages (in addition to common packages)
  home.packages = with pkgs; [
    # Vagrant-specific development tools
    git
    gnumake
    gcc
    gnused
    gawk

    # Overlays
    nvm
    tfenv
    browser-forward

    # Terraform tools
    terraform-docs
    terraform-ls

    # Node.js tools
    nodePackages.pnpm

    tmux
    htop
    jq
    fzf
    tree
    unzip
    nmap
    docker
    docker-compose
    kubectl
    kubernetes-helm
    wget
    pre-commit
    rclone
    trivy
  ];

  # Program configurations
  programs = {
    neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
    };
  };

  home.file.".ssh/config".text = ''
    Host *
      AddKeysToAgent yes
      Protocol 2
      Compression yes
      ServerAliveInterval 20
      ServerAliveCountMax 10
      TCPKeepAlive yes
      IdentityAgent "~/.ssh/agent.sock"
  '';

  # Required for home-manager
  home.stateVersion = "23.11";
}
