{ config, lib, pkgs, username, ... }:

let
  # Import shared ZSH configuration
  sharedZsh = import ../common/zsh/shared.nix;
in {
  # Home Manager configuration for macOS

  # Ensure home-manager uses the correct home directory
  home.username = username;
  home.homeDirectory = "/Users/${username}";
  home.stateVersion = "23.11";

  # Enable Oh My Zsh with Git plugin
  programs.zsh = {
    enable = true;

    # Enable Oh My Zsh with Git plugin
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" ];

      # Use empty theme since we're using Oh My Posh
      theme = "";
    };

    # Common aliases from shared config plus macOS-specific ones
    shellAliases = sharedZsh.aliases // {
      nixswitch = "darwin-rebuild switch --flake ~/.config/nix#Rick";
    };

    # Additional ZSH initialization
    initExtra = ''
      # Source common settings
      ${sharedZsh.options}
      ${sharedZsh.keybindings}
      ${sharedZsh.tools}

      # Ensure Oh My Posh is properly initialized
      if command -v oh-my-posh &> /dev/null; then
        eval "$(oh-my-posh --init --shell zsh --config ~/.config/oh-my-posh/default.omp.json)"
      fi
    '';
  };

  # Install Oh My Posh theme
  home.file.".config/oh-my-posh/default.omp.json".source =
    ../common/zsh/default.omp.json;
}
