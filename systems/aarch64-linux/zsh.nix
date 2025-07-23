{
  config,
  lib,
  pkgs,
  username,
  ...
}:

let
  sharedZsh = import ../../common/zsh/shared.nix;
in
{
  # Vagrant-specific ZSH configuration for home-manager

  # Install Oh My Posh theme
  home.file.".config/oh-my-posh/default.omp.json".source = ../../common/zsh/default.omp.json;

  # Home Manager ZSH configuration
  programs.zsh = {
    enable = true;

    enableCompletion = true;
    autosuggestion = sharedZsh.autosuggestionConfig;

    # Apply shared aliases explicitly
    shellAliases = sharedZsh.aliases;

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" ];
    };

    history = sharedZsh.historyConfig;

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

      # Platform-specific aliases
      alias awssso="aws sso login"
      alias t="terraform"
      alias nixswitch="nix run home-manager/master -- switch --flake ~/.config/nix#vagrant"

      # Source auto-generated aliases if the file exists
      if [ -f "$HOME/.bin_aliases" ]; then
        source "$HOME/.bin_aliases"
      fi

      # Ensure direnv is properly initialized
      if command -v direnv &> /dev/null; then
        eval "$(direnv hook zsh)"
      fi
    '';
  };
}
