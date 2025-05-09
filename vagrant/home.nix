{ config, pkgs, username, lib, ... }:

{
  imports = [ ./zsh.nix ./git.nix ./aws.nix ];

  # Explicitly tell home-manager not to manage nix.conf
  xdg.configFile."nix/nix.conf".enable = false;

  nixpkgs.config.allowUnfree = true;

  # Add to your nix.conf or as nix.settings in configuration
  nix.settings = {
    substituters =
      [ "https://cache.nixos.org" "https://nix-community.cachix.org" ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
    trusted-substituters = true;
  };

  # Vagrant-specific packages (removed Rust-based tools)
  home.packages = with pkgs; [
    # Tools needed by zsh configuration
    zoxide
    oh-my-posh
    eza # Modern ls replacement

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
