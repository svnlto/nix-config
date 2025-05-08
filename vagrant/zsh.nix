{ config, lib, pkgs, username, ... }:

let
  # Import shared ZSH configuration
  sharedZsh = import ../common/zsh/shared.nix;
in {
  # Vagrant-specific ZSH configuration for home-manager

  # Install Oh My Posh theme
  home.file.".config/oh-my-posh/default.omp.json".source =
    ../common/zsh/default.omp.json;

  # Home Manager ZSH configuration
  programs.zsh = {
    enable = true;

    # Basic zsh options
    enableCompletion = true;
    autosuggestion.enable = true;

    # Enable Oh My Zsh
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" ];
    };

    shellAliases = sharedZsh.aliases // {
      nixswitch =
        "nix run home-manager/master -- switch --flake ~/.config/nix#vagrant";
    };

    # ZSH history configuration - aligned with the shared settings
    history = {
      size = 100000;
      save = 100000;
      path = "$HOME/.zsh_history";
      ignoreAllDups = true;
      share = true;
      extended = true;
    };

    # ZSH initialization script (shared + Vagrant-specific)
    initContent = ''
      # Shared locale settings
      ${sharedZsh.locale}

      # Default node.js environment
      export NODE_ENV="dev"

      # Set browser variables for VSCode SSH sessions
      export BROWSER="browser-forward"
      export GH_BROWSER="browser-forward"

      # Shared ZSH options
      ${sharedZsh.options}

      # Shared completion settings
      ${sharedZsh.completion}

      # Shared key bindings
      ${sharedZsh.keybindings}

      # Tool initializations
      ${sharedZsh.tools}

      # NVM setup - simplified to avoid redundancy
      export NVM_DIR="$HOME/.nvm"
      mkdir -p "$NVM_DIR"

      # Initialize NVM from the Nix overlay location
      source "${pkgs.nvm}/share/nvm/nvm.sh"
      source "${pkgs.nvm}/share/nvm/bash_completion"
    '';
  };
}
