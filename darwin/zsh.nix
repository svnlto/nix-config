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

  # Configure ZSH specifically with shared settings
  programs.zsh.shellInit = ''
    # Common locale settings
    ${sharedZsh.locale}

    # Set custom history file location
    export HISTFILE=$HOME/.zsh_history
  '';

  # ZSH interactive shell initialization
  programs.zsh.interactiveShellInit = ''
    # Common ZSH options
    ${sharedZsh.options}

    # Common completion settings
    ${sharedZsh.completion}

    # Common key bindings
    ${sharedZsh.keybindings}

    # Common tool initialization
    ${sharedZsh.tools}
  '';

  # Common aliases from shared config plus macOS-specific ones
  environment.shellAliases = sharedZsh.aliases // {
    nixswitch =
      "darwin-rebuild switch --flake ~/.config/nix#${config.networking.hostName}";
  };
}
