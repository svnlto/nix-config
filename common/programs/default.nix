{ config, pkgs, ... }:

let sharedZsh = import ../zsh/shared.nix;
in {
  # Shared program configurations that are identical across platforms

  # Direnv configuration - development environment management
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
    # Reduce verbosity
    config = { global = { hide_env_diff = true; }; };
  };

  # GitHub CLI configuration
  programs.gh = {
    enable = true;
    settings = {
      # Default protocol when cloning repositories
      git_protocol = "ssh";

      # Default editor
      editor = "nvim";

      # Prompt for every command
      prompt = "enabled";
    };
  };

  # Base ZSH configuration (platform-specific aliases added separately)
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion = sharedZsh.autosuggestionConfig;
    history = sharedZsh.historyConfig;

    # Common aliases - platform-specific aliases merged separately
    shellAliases = sharedZsh.aliases;

    initContent = ''
      ${sharedZsh.tools}
      ${sharedZsh.historyOptions}
      ${sharedZsh.options}
      ${sharedZsh.completion}
      ${sharedZsh.keybindings}

      # Load Oh My Posh if available
      if command -v oh-my-posh &> /dev/null; then
        eval "$(oh-my-posh --init --shell zsh --config ~/.config/oh-my-posh/default.omp.json)"
      fi
    '';
  };
}
