# This file contains truly shared ZSH configuration that works in both
# nix-darwin and home-manager without modification

# Return a simple attribute set for direct import by other modules
rec {
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

  # Common packages needed for ZSH setup on both platforms
  packages = [
    "zoxide" # Smart directory navigation
    "hstr" # History search
    "bat" # Better cat
    "eza" # Modern ls replacement
    "oh-my-posh" # Prompt theme engine
    "tree" # Directory tree view
  ];

  # Common ZSH history settings
  history = ''
    # History configuration
    export HISTFILE=$HOME/.zsh_history
    export HIST_SIZE=100000
    export HIST_STAMPS="dd/mm/yyyy"
    export SAVEHIST=100000
    export HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1

    # History options
    setopt hist_reduce_blanks  # remove superfluous blanks from history items
    setopt share_history       # share history between different instances of the shell
    setopt HIST_EXPIRE_DUPS_FIRST
    setopt EXTENDED_HISTORY
    setopt APPEND_HISTORY
    setopt SHARE_HISTORY
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
    # Completion styling - using double quotes for nix string compatibility
    zstyle ":completion:*" menu select # select completions with arrow keys
    zstyle ":completion:*" group-name "" # group results by category
    zstyle ":completion:::::" completer _expand _complete _ignored _approximate # enable approximate matches
    zstyle ":completion:*:default" list-colors "''${(s.:.)LS_COLORS}"
    zstyle ":completion:*" accept-exact "*"

    # Cache expensive completions
    zstyle ":completion:*" use-cache on
    zstyle ":completion:*" cache-path ~/.cache/zsh
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
    # Initialize zoxide
    eval "$(zoxide init --cmd cd zsh)"

    # Initialize oh-my-posh (conditionally for non-Apple Terminal)
    if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
      eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/default.omp.json)"
    fi

    # HSTR colors
    export HSTR_CONFIG=case-sensitive,keywords-matching,hicolor,debug,prompt-bottom,help-on-opposite-side
  '';

  # Module metadata
  meta = {
    description =
      "Shared ZSH configuration for both nix-darwin and home-manager";
  };
}
