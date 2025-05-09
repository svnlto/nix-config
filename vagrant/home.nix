{ config, pkgs, username, lib, ... }:

{
  imports = [ 
    ../common/home-packages.nix
    ./zsh.nix 
    ./git.nix 
    ./aws.nix 
    ./ramdisk.nix 
    ./github.nix 
  ];

  # Explicitly tell home-manager not to manage nix.conf
  xdg.configFile."nix/nix.conf".enable = false;

  # Create and set up the .bin directory for custom scripts
  home.activation.setupBinDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    CONFIG_BIN_DIR="$HOME/.config/nix/vagrant/.bin"
    TARGET_BIN_DIR="$HOME/.bin"
    ALIAS_FILE="$HOME/.bin_aliases"

    mkdir -p "$TARGET_BIN_DIR"

    if [ -d "$CONFIG_BIN_DIR" ]; then
      cp -f "$CONFIG_BIN_DIR"/* "$TARGET_BIN_DIR/" 2>/dev/null || true
      chmod +x "$TARGET_BIN_DIR"/* 2>/dev/null || true
    fi

    echo "# Auto-generated aliases for scripts in ~/.bin" > "$ALIAS_FILE"
    for script in "$TARGET_BIN_DIR"/*; do
      [ -x "$script" ] && echo "alias $(basename "$script" .sh)=\"$script\"" >> "$ALIAS_FILE"
    done
  '';

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
