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

  # GitHub CLI configuration
  programs.gh = {
    enable = true;
    settings = {
      # Default protocol when cloning repositories
      git_protocol = "ssh";

      # Default editor
      editor = "zed";

      # Prompt for every command
      prompt = "enabled";
    };
  };

  programs.zsh = {
    enable = true;

    enableCompletion = true;
    autosuggestion = sharedZsh.autosuggestionConfig;
    history = sharedZsh.historyConfig;

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
      # Shared ZSH options
      ${sharedZsh.options}

      # Shared completion settings
      ${sharedZsh.completion}

      # Shared key bindings
      ${sharedZsh.keybindings}

      # Shared history options
      ${sharedZsh.historyOptions}

      # Tool initializations (includes environment setup)
      ${sharedZsh.tools}

      # Ensure Oh My Posh is properly initialized
      if command -v oh-my-posh &> /dev/null; then
        eval "$(oh-my-posh --init --shell zsh --config ~/.config/oh-my-posh/default.omp.json)"
      fi
    '';
  };

  # Install Oh My Posh theme
  home.file.".config/oh-my-posh/default.omp.json".source = ../../common/zsh/default.omp.json;
}
