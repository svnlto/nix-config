{ config, lib, pkgs, username, ... }:

let sharedZsh = import ../../common/zsh/shared.nix;
in {
  # Vagrant-specific ZSH configuration for home-manager

  # Install Oh My Posh theme
  home.file.".config/oh-my-posh/default.omp.json".source =
    ../../common/zsh/default.omp.json;

  # Home Manager ZSH configuration
  programs.zsh = {
    enable = true;

    enableCompletion = true;
    autosuggestion.enable = true;

    # Apply shared aliases explicitly
    shellAliases = sharedZsh.aliases;

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" ];
    };

    history = {
      size = 100000;
      save = 100000;
      path = "$HOME/.zsh_history";
      ignoreAllDups = true;
      share = true;
      extended = true;
    };

    initContent = ''
      # Shared locale settings
      ${sharedZsh.locale}

      # Shared ZSH options
      ${sharedZsh.options}

      # Shared completion settings
      ${sharedZsh.completion}

      # Shared key bindings
      ${sharedZsh.keybindings}

      # Tool initializations
      ${sharedZsh.tools}

      # Alias for AWS commands
      alias awssso="aws sso login"

      # Alias for Terraform commands
      alias t="terraform"

      # Alias for Nix commands
      alias nixswitch="nix run home-manager/master -- switch --flake ~/.config/nix#vagrant"

      # Custom user binaries directory
      export PATH="$HOME/.bin:$PATH"

      # Add npm global bin to PATH for Claude Code
      export PATH="$HOME/.npm-global/bin:$PATH"
      export NPM_CONFIG_PREFIX="$HOME/.npm-global"

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
