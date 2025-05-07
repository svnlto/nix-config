{ config, lib, pkgs, ... }:

{
  # This file contains the shared zsh configuration that works across all platforms

  # Create the oh-my-posh theme directory and install our theme
  system.activationScripts.ohmyposhSetup = lib.mkIf (pkgs.stdenv.isDarwin) {
    text = ''
      echo "Setting up Oh My Posh theme..."
      mkdir -p ~/.config/oh-my-posh
      cp ${./default.omp.json} ~/.config/oh-my-posh/default.omp.json
    '';
  };

  # For home-manager systems (Linux)
  home.file = lib.mkIf (!pkgs.stdenv.isDarwin) {
    ".config/oh-my-posh/default.omp.json".source = ./default.omp.json;
  };

  programs.zsh = {
    enable = true;
    
    # Basic zsh options
    enableCompletion = true;
    autosuggestion.enable = true;
    
    # Shared aliases across all platforms
    shellAliases = {
      reloadcli = "source $HOME/.zshrc";
      ll = "eza --long --header --links --group-directories-first --color-scale --time-style=iso --all";
      vim = "nvim";
      t = "terraform";
      c = "clear";
      cat = "bat";
      hh = "hstr";
      tree = "tree -C";
    };

    # Shared zshrc configuration
    initExtra = ''
      # Where to find the zsh history
      export HISTFILE=''${HOME}/.zsh_history
      export HIST_SIZE=100000
      export HIST_STAMPS="dd/mm/yyyy"
      export SAVEHIST=100000
      export HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1

      # Locales
      export LANG=en_GB.UTF-8
      export LC_ALL=en_GB.UTF-8

      # set up hh colours
      export HSTR_CONFIG=case-sensitive,keywords-matching,hicolor,debug,prompt-bottom,help-on-opposite-side

      autoload -Uz compinit
      typeset -i updated_at=$(date +'%j' -r ~/.zcompdump 2>/dev/null || stat -f '%Sm' -t '%j' ~/.zcompdump 2>/dev/null)
      if [ $(date +'%j') != $updated_at ]; then
        compinit -i
      else
        compinit -C -i
      fi

      zmodload -i zsh/complist

      setopt hist_reduce_blanks # remove superfluous blanks from history items
      setopt share_history # share history between different instances of the shell

      setopt auto_cd # cd by typing directory name if it's not a command
      setopt correct_all # autocorrect commands

      setopt auto_list # automatically list choices on ambiguous completion
      setopt auto_menu # automatically use menu completion
      setopt always_to_end # move cursor to end if word had one match
      setopt complete_in_word # allow completion from within a word/phrase

      setopt HIST_EXPIRE_DUPS_FIRST
      setopt EXTENDED_HISTORY
      setopt APPEND_HISTORY
      setopt SHARE_HISTORY

      zstyle ':completion:*' menu select # select completions with arrow keys
      zstyle ':completion:*' group-name '' # group results by category
      zstyle ':completion:::::' completer _expand _complete _ignored _approximate # enable approximate matches for completion
      zstyle ':completion:*:default' list-colors ''${(s.:.)LS_COLORS}
      zstyle ':completion:*' accept-exact '*'

      # Cache expensive completions
      zstyle ':completion:*' use-cache on
      zstyle ':completion:*' cache-path ~/.cache/zsh

      # Key bindings
      bindkey -s "\C-r" "\C-a hstr -- \C-j"
      bindkey '\e[A' history-search-backward
      bindkey '\e[B' history-search-forward

      # Initialize zoxide
      eval "$(zoxide init --cmd cd zsh)"

      # Initialize oh-my-posh (conditionally for non-Apple Terminal)
      if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
        eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/default.omp.json)"
      fi
    '';

    # Ensure zsh packages are installed
    plugins = [];
  };

  # Ensure necessary packages are installed
  environment.systemPackages = with pkgs; [
    zoxide      # Smart directory navigation
    hstr        # History search
    bat         # Better cat
    eza         # Modern ls replacement
    oh-my-posh  # Prompt theme engine
    tree        # Directory tree view
  ];
}