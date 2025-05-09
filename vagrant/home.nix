{ config, pkgs, username, lib, ... }:

{
  imports = [ ./zsh.nix ./git.nix ./aws.nix ./ramdisk.nix ./github.nix ];

  # Explicitly tell home-manager not to manage nix.conf
  xdg.configFile."nix/nix.conf".enable = false;

  # Create and set up the .bin directory for custom scripts
  home.activation.setupBinDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p $HOME/.bin
    chmod 755 $HOME/.bin

    # Generate aliases file for all executable scripts in .bin
    if [ -d "$HOME/.bin" ]; then
      # Create a file that will be sourced by zsh
      ALIAS_FILE="$HOME/.bin_aliases"
      echo "# Auto-generated aliases for scripts in ~/.bin" > "$ALIAS_FILE"
      
      if [ "$(ls -A $HOME/.bin 2>/dev/null)" ]; then
        echo "# Generated on $(date)" >> "$ALIAS_FILE"
        # Make all scripts executable
        chmod +x "$HOME/.bin"/* 2>/dev/null || true
        
        for script in "$HOME/.bin"/*; do
          if [ -f "$script" ] && [ -x "$script" ]; then
            script_name=$(basename "$script" .sh)
            echo "alias $script_name=\"$script\"" >> "$ALIAS_FILE"
          fi
        done
        echo "Auto-generated $(grep -c "^alias" "$ALIAS_FILE") aliases for ~/.bin scripts"
      else
        echo "# No scripts found in ~/.bin" >> "$ALIAS_FILE"
        echo "No scripts found in ~/.bin directory to create aliases for"
      fi
      
      chmod 644 "$ALIAS_FILE"
    fi
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

  # Vagrant-specific packages (removed Rust-based tools)
  home.packages = with pkgs; [
    # Tools needed by zsh configuration
    zoxide
    oh-my-posh
    eza
    gh

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
