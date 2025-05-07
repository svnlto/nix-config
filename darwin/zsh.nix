{ config, lib, pkgs, username, ... }:

{
  # macOS-specific ZSH configuration for nix-darwin
  
  # Create the oh-my-posh theme directory and install our theme
  system.activationScripts.ohmyposhSetup = {
    text = ''
      echo "Setting up Oh My Posh theme..."
      mkdir -p /Users/${username}/.config/oh-my-posh
      cp ${../common/zsh/default.omp.json} /Users/${username}/.config/oh-my-posh/default.omp.json
      chown ${username}:staff /Users/${username}/.config/oh-my-posh/default.omp.json
    '';
  };

  # Enable ZSH
  programs.zsh.enable = true;
  
  # Set up user defaults
  users.users.${username}.shell = pkgs.zsh;

  # Install required packages
  environment.systemPackages = with pkgs; [
    zoxide      # Smart directory navigation
    hstr        # History search
    bat         # Better cat
    eza         # Modern ls replacement
    oh-my-posh  # Prompt theme engine
    tree        # Directory tree view
    neovim      # Modern vim
  ];
  
  # Configure ZSH through environment.shellInit
  environment.shellInit = ''
    # This is loaded for all shells
  '';
  
  # Add macOS-specific ZSH configuration
  environment.loginShell = "zsh";
  
  # Configure ZSH specifically
  programs.zsh.shellInit = ''
    # Where to find the zsh history
    export HISTFILE=$HOME/.zsh_history
    export HIST_SIZE=100000
    export HIST_STAMPS="dd/mm/yyyy"
    export SAVEHIST=100000
    export HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1

    # Locales
    export LANG=en_GB.UTF-8
    export LC_ALL=en_GB.UTF-8

    # default node.js environment
    export NODE_ENV="dev"

    # set up hh colours
    export HSTR_CONFIG=case-sensitive,keywords-matching,hicolor,debug,prompt-bottom,help-on-opposite-side
  '';
  
  # ZSH interactive shell configuration
  programs.zsh.interactiveShellInit = ''
    # History configuration
    setopt hist_reduce_blanks  # remove superfluous blanks from history items
    setopt share_history       # share history between different instances of the shell
    setopt HIST_EXPIRE_DUPS_FIRST
    setopt EXTENDED_HISTORY
    setopt APPEND_HISTORY
    setopt SHARE_HISTORY

    # Directory navigation
    setopt auto_cd             # cd by typing directory name if it's not a command
    setopt correct_all         # autocorrect commands

    # Completion settings
    setopt auto_list           # automatically list choices on ambiguous completion
    setopt auto_menu           # automatically use menu completion
    setopt always_to_end       # move cursor to end if word had one match
    setopt complete_in_word    # allow completion from within a word/phrase
    
    # Completion styling
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
  
  # Common aliases
  environment.shellAliases = {
    # Base aliases
    reloadcli = "source $HOME/.zshrc";
    ll = "eza --long --header --links --group-directories-first --color-scale --time-style=iso --all";
    vim = "nvim";
    t = "terraform";
    c = "clear";
    cat = "bat";
    hh = "hstr";
    tree = "tree -C";
    
    # macOS-specific aliases
    brewup = "brew update && brew upgrade";
    copy = "pbcopy";
    paste = "pbpaste";
    nixswitch = "darwin-rebuild switch --flake ~/.config/nix#${config.networking.hostName}";
  };
}