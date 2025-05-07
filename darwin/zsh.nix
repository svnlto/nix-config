{ config, lib, pkgs, username, ... }:

let
  # Import shared ZSH configuration
  sharedZsh = import ../common/zsh/shared.nix;
in {
  # macOS-specific ZSH configuration for nix-darwin

  # Create the oh-my-posh theme directory and install our theme
  system.activationScripts.ohmyposhSetup = {
    text = ''
      echo "Setting up Oh My Posh theme..."
      mkdir -p /Users/${username}/.config/oh-my-posh
      cp ${
        ../common/zsh/default.omp.json
      } /Users/${username}/.config/oh-my-posh/default.omp.json
      chown ${username}:staff /Users/${username}/.config/oh-my-posh/default.omp.json
    '';
  };

  # Enable ZSH
  programs.zsh.enable = true;

  # Install required packages from shared config
  environment.systemPackages = with pkgs;
    map (name: builtins.getAttr name pkgs) sharedZsh.packages;

  # Configure ZSH through environment.shellInit
  environment.shellInit = ''
    # This is loaded for all shells
  '';

  # Configure ZSH specifically with shared settings
  programs.zsh.shellInit = ''
    # Common history settings
    ${sharedZsh.history}

    # Common locale settings
    ${sharedZsh.locale}

    # default node.js environment
    export NODE_ENV="dev"
  '';

  # ZSH interactive shell configuration with shared settings
  programs.zsh.interactiveShellInit = ''
    # Common history options are in shellInit

    # Common ZSH options
    ${sharedZsh.options}

    # Common completion settings
    ${sharedZsh.completion}

    # Common key bindings
    ${sharedZsh.keybindings}

    # Common tool initialization
    ${sharedZsh.tools}

    # macOS-specific settings
    if command -v pbcopy >/dev/null 2>&1; then
      alias copy='pbcopy'
      alias paste='pbpaste'
    fi
  '';

  # Common aliases from shared config plus macOS-specific ones
  environment.shellAliases = sharedZsh.aliases // {
    # macOS-specific aliases
    brewup = "brew update && brew upgrade";
    nixswitch =
      "darwin-rebuild switch --flake ~/.config/nix#${config.networking.hostName}";
  };
}
