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

    # Shared aliases plus Ubuntu-specific ones
    shellAliases = sharedZsh.commonAliases // {
      # Ubuntu-specific aliases
      ls = "ls --color=auto";
      update = "sudo apt update && sudo apt upgrade";
      nixswitch =
        "nix run home-manager/master -- switch --flake ~/.config/nix#ubuntu-orbstack";
    };

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
    initExtra = ''
      # Shared history settings
      export HIST_STAMPS="dd/mm/yyyy"
      export HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1

      # Shared locale settings
      ${sharedZsh.localeSettings}

      # Default node.js environment
      export NODE_ENV="dev"

      # Shared ZSH options
      ${sharedZsh.zshOptions}

      # Shared history options
      setopt HIST_EXPIRE_DUPS_FIRST
      setopt EXTENDED_HISTORY
      setopt APPEND_HISTORY
      setopt SHARE_HISTORY

      # Shared completion settings
      ${sharedZsh.completionSettings}

      # Shared key bindings
      ${sharedZsh.keyBindings}

      # Shared tool initialization 
      ${sharedZsh.toolInit}

      # Linuxbrew configuration
      if [ -d "/home/linuxbrew/.linuxbrew" ]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        export HOMEBREW_NO_AUTO_UPDATE=1  # Prevent auto updates to avoid conflicts
        export HOMEBREW_NO_INSTALL_CLEANUP=1  # Prevent automatic cleanup
        
        # Brew-related aliases
        alias brewup='brew update && brew upgrade'
      fi

      # Load NVM if installed
      if [ -d "$HOME/.nvm" ]; then
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
      fi

      # Ubuntu/Linux-specific commands and settings
      if command -v xclip >/dev/null 2>&1; then
        alias copy='xclip -selection clipboard'
        alias paste='xclip -selection clipboard -o'
      fi
    '';
  };

  # Install necessary packages from shared config
  home.packages = with pkgs;
    map (name: builtins.getAttr name pkgs) sharedZsh.commonPackages;
}
