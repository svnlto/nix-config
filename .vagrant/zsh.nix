{ config, lib, pkgs, username, ... }:

let
  # Import shared ZSH configuration
  sharedZsh = import ../common/zsh/shared.nix;
in {
  # Ubuntu-specific ZSH configuration for home-manager

  # Install Oh My Posh theme
  home.file.".config/oh-my-posh/default.omp.json".source =
    ../common/zsh/default.omp.json;

  # Home Manager ZSH configuration
  programs.zsh = {
    enable = true;

    # Basic zsh options
    enableCompletion = true;
    autosuggestion.enable = true;

    shellAliases = sharedZsh.aliases;

    # ZSH history configuration
    history = {
      size = 100000;
      save = 100000;
      path = "$HOME/.zsh_history";
      ignoreAllDups = true;
      share = true;
      extended = true;
    };

    # ZSH initialization script (shared + Ubuntu-specific)
    # Using initContent instead of deprecated initExtra
    initContent = ''
      # Shared history settings
      export HIST_STAMPS="dd/mm/yyyy"
      export HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1

      # Shared locale settings
      ${sharedZsh.locale}

      # Default node.js environment
      export NODE_ENV="dev"

      # Shared ZSH options
      ${sharedZsh.options}

      # Shared history options
      setopt HIST_EXPIRE_DUPS_FIRST
      setopt EXTENDED_HISTORY
      setopt SHARE_HISTORY

      # Shared completion settings
      ${sharedZsh.completion}

      # Shared key bindings
      ${sharedZsh.keybindings}

      # Tool initializations
      ${sharedZsh.tools}

      # NVM setup
      export NVM_DIR="$HOME/.nvm"
      if [ -d "$NVM_DIR" ]; then
        # Create .nvm directory if it doesn't exist
        mkdir -p "$NVM_DIR"
      fi

      # Initialize NVM from the Nix overlay location
      if [ -e "${pkgs.nvm}/share/nvm/nvm.sh" ]; then
        source "${pkgs.nvm}/share/nvm/nvm.sh"
        source "${pkgs.nvm}/share/nvm/bash_completion"
      fi
    '';
  };

  # Ubuntu-specific packages (removing duplicated packages)
  home.packages = with pkgs;
    [
      # Ubuntu-specific packages
      # Note: We're not using sharedZsh.packages here to avoid duplication
      # as these packages are already included in common configuration
    ];
}
