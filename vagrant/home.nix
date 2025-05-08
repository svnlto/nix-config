{ config, pkgs, username, ... }:

{
  imports = [ ./zsh.nix ./git.nix ];

  nixpkgs.config.allowUnfree = true;

  # Common and Vagrant-specific packages
  home.packages = with pkgs; [
    # Common CLI utilities (from common)
    oh-my-posh
    hstr
    eza
    ack
    zoxide
    bat
    gh
    nixfmt-classic
    diff-so-fancy

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

    # System utilities
    tmux
    htop
    ripgrep
    fd
    jq
    fzf
    tree
    unzip
    nmap
    awscli2
    docker
    docker-compose
    kubectl
    kubernetes-helm
    wget
    pre-commit
  ];

  # Program configurations
  programs = {
    neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
    };

    tmux = {
      enable = true;
      shortcut = "a";
      terminal = "screen-256color";
      escapeTime = 0;
      historyLimit = 50000;
    };

    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
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
