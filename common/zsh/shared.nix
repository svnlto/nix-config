# This file contains truly shared ZSH configuration that works in both
# nix-darwin and home-manager without modification

# Return a simple attribute set for direct import by other modules
rec {
  # Add a profiling block at the top of your configuration
  profiling = ''
    # Uncomment to enable profiling
    # zmodload zsh/zprof
  '';

  # Common shell aliases defined as a regular Nix attribute set
  aliases = {
    reloadcli = "source $HOME/.zshrc";
    ll =
      "eza --long --header --links --group-directories-first --color-scale --time-style=iso --all";
    vim = "nvim";
    c = "clear";
    cat = "bat";
    hh = "hstr";
    tree = "tree -C";
  };

  # Common ZSH history settings
  history = ''
    # History configuration
    export HISTFILE=$HOME/.zsh_history
    export HIST_SIZE=10000       # Reduced from 100000
    export HIST_STAMPS="dd/mm/yyyy"
    export SAVEHIST=10000        # Reduced from 100000
    export HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1

    # History options - keep only what you need
    setopt hist_reduce_blanks
    setopt share_history
    setopt HIST_EXPIRE_DUPS_FIRST
    setopt APPEND_HISTORY
    
    # Remove EXTENDED_HISTORY if you don't need timestamps
    # Removed duplicate SHARE_HISTORY
  '';

  # Common locale settings
  locale = ''
    # Locales
    export LANG=en_GB.UTF-8
    export LC_ALL=en_GB.UTF-8
  '';

  # Common ZSH option settings
  options = ''
    # Directory navigation
    setopt auto_cd             # cd by typing directory name if it's not a command
    setopt correct_all         # autocorrect commands

    # Completion settings
    setopt auto_list           # automatically list choices on ambiguous completion
    setopt auto_menu           # automatically use menu completion
    setopt always_to_end       # move cursor to end if word had one match
    setopt complete_in_word    # allow completion from within a word/phrase
  '';

  # Common ZSH completion styling
  completion = ''
    # Simplified completion styling
    zstyle ":completion:*" menu select
    zstyle ":completion:*" group-name ""
    zstyle ":completion:*:default" list-colors "''${(s.:.)LS_COLORS}"
    
    # More efficient cache settings
    zstyle ":completion:*" use-cache on
    zstyle ":completion:*" cache-path ~/.cache/zsh
    
    # Speed up by avoiding approximate matches
    # Removed: zstyle ":completion:::::" completer _expand _complete _ignored _approximate
  '';

  # Common key bindings
  keybindings = ''
    # Key bindings
    bindkey -s "\C-r" "\C-a hstr -- \C-j"
    bindkey '\e[A' history-search-backward
    bindkey '\e[B' history-search-forward
  '';

  # Tool initialization commands
  tools = ''
    # Lazy-load zoxide
    zoxide_init() {
      eval "$(zoxide init --cmd cd zsh)"
      unfunction zoxide_init
    }
    zoxide() { zoxide_init; zoxide "$@" }
    cd() { zoxide_init; cd "$@" }

    # Lazy-load oh-my-posh
    omp_init() {
      eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/default.omp.json)"
      unfunction omp_init
    }
    precmd_functions+=(omp_init)
    
    # HSTR colors - only needed when hstr is actually used
    hstr() {
      export HSTR_CONFIG=case-sensitive,keywords-matching,hicolor,debug,prompt-bottom,help-on-opposite-side
      command hstr "$@"
    }
  '';

  # Add another block at the end
  profilingEnd = ''
    # Uncomment to display profiling results
    # if [[ "$PROFILE_STARTUP" == true ]]; then
    #   zprof
    # fi
  '';

  # Module metadata
  meta = {
    description =
      "Shared ZSH configuration for both nix-darwin and home-manager";
  };
}
