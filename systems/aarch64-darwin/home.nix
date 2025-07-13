{
  config,
  pkgs,
  username,
  lib,
  ...
}:

let
  sharedZsh = import ../../common/zsh/shared.nix;
in
{
  imports = [
    ../../common/home-packages.nix
    ../../common/claude-code/default.nix
  ];

  # Home Manager configuration for macOS
  home = {
    username = username;
    homeDirectory = "/Users/${username}";
    stateVersion = "23.11";
  };

  # Enable direnv using home-manager module
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;

    # Reduce verbosity
    config = {
      global = {
        hide_env_diff = true;
      };
    };
  };

  # Set direnv log format to be less verbose
  home.sessionVariables = {
    DIRENV_LOG_FORMAT = "";
  };

  programs.zsh = {
    enable = true;

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" ];
      theme = "";
    };

    # Common aliases from shared config plus macOS-specific ones
    shellAliases = sharedZsh.aliases // {
      nixswitch = "darwin-rebuild switch --flake ~/.config/nix#rick";
    };

    # Additional ZSH initialization
    initContent = ''
      # Source common settings
      ${sharedZsh.options}
      ${sharedZsh.keybindings}
      ${sharedZsh.tools}

      # Add npm global bin to PATH
      export PATH="$HOME/.npm-global/bin:$PATH"
      export NPM_CONFIG_PREFIX="$HOME/.npm-global"

      # Ensure Oh My Posh is properly initialized
      if command -v oh-my-posh &> /dev/null; then
        eval "$(oh-my-posh --init --shell zsh --config ~/.config/oh-my-posh/default.omp.json)"
      fi
    '';
  };

  # Install Oh My Posh theme
  home.file.".config/oh-my-posh/default.omp.json".source = ../../common/zsh/default.omp.json;
}
