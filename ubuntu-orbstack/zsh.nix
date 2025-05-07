{ config, lib, pkgs, username, ... }:

{
  # Ubuntu-specific ZSH configuration for home-manager

  # Install Oh My Posh theme
  home.file.".config/oh-my-posh/default.omp.json".source = ../common/zsh/default.omp.json;

  # Home Manager ZSH configuration
  programs.zsh = {
    enable = true;
    
    # Basic zsh options
    enableCompletion = true;
    autosuggestion.enable = true;
    
    # Ubuntu-specific ZSH aliases
    shellAliases = {
      # Base aliases
      reloadcli = "source $HOME/.zshrc";
      ll = "eza --long --header --links --group-directories-first --color-scale --time-style=iso --all";
      vim = "nvim";
      t = "terraform";
      c = "clear";
      cat = "bat";
      hh = "hstr";
      tree = "tree -C";
      
      # Ubuntu-specific aliases
      ls = "ls --color=auto";
      update = "sudo apt update && sudo apt upgrade";
      nixswitch = "nix run home-manager/master -- switch --flake ~/.config/nix#ubuntu-orbstack";
    };
    
    # ZSH history configuration
    history = {
      size = 100000;
      save = 100000;
      path = "$HOME/.zsh_history";
      ignoreAllDups = true;
      share = true;
      extended = true;
    };
    
    # ZSH initialization script (shared + Ubuntu-specific)
    initExtra = ''
      # Where to find the zsh history
      export HIST_STAMPS="dd/mm/yyyy"
      export HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1

      # Locales
      export LANG=en_GB.UTF-8
      export LC_ALL=en_GB.UTF-8

      # default node.js environment
      export NODE_ENV="dev"

      # set up hh colours
      export HSTR_CONFIG=case-sensitive,keywords-matching,hicolor,debug,prompt-bottom,help-on-opposite-side

      # ZSH options
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

      # ZSH styles
      zstyle ':completion:*' menu select # select completions with arrow keys
      zstyle ':completion:*' group-name '' # group results by category
      zstyle ':completion:::::' completer _expand _complete _ignored _approximate # enable approximate matches for completion
      zstyle ':completion:*:default' list-colors ''${(s.:.)LS_COLORS}
      zstyle ':completion:*' accept-exact '*'
      zstyle ':completion:*' use-cache on
      zstyle ':completion:*' cache-path ~/.cache/zsh

      # Key bindings
      bindkey -s "\C-r" "\C-a hstr -- \C-j"
      bindkey '\e[A' history-search-backward
      bindkey '\e[B' history-search-forward

      # Initialize zoxide
      eval "$(zoxide init --cmd cd zsh)"

      # Initialize oh-my-posh
      eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/default.omp.json)"
      
      # Linuxbrew configuration
      if [ -d "/home/linuxbrew/.linuxbrew" ]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        export HOMEBREW_NO_AUTO_UPDATE=1  # Prevent auto updates to avoid conflicts
        export HOMEBREW_NO_INSTALL_CLEANUP=1  # Prevent automatic cleanup
        
        # Brew-related aliases
        alias brewup='brew update && brew upgrade'
      fi
      
      # Load NVM if installed
      if [ -d "$HOME/.nvm" ]; then
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
      fi

      # Ubuntu/Linux-specific commands and settings
      if command -v xclip >/dev/null 2>&1; then
        alias copy='xclip -selection clipboard'
        alias paste='xclip -selection clipboard -o'
      fi
    '';
  };
  
  # Ensure necessary packages are installed
  home.packages = with pkgs; [
    zoxide      # Smart directory navigation
    hstr        # History search
    bat         # Better cat
    eza         # Modern ls replacement
    oh-my-posh  # Prompt theme engine
    tree        # Directory tree view
    neovim      # Modern vim
  ];
}