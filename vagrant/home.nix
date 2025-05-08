{ config, pkgs, username, lib, ... }:

{
  imports = [ ./zsh.nix ./git.nix ];

  nixpkgs.config.allowUnfree = true;

  # Vagrant-specific packages (removed Rust-based tools)
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
    awscli2
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

    # Explicitly disable fish using mkForce to override any imported configs
    fish.enable = lib.mkForce false;

    direnv = {
      enable = true;
      enableZshIntegration = true;
      enableFishIntegration = lib.mkForce false;
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
