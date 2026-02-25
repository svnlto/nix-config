# This file contains truly shared ZSH configuration that works in both
# nix-darwin and home-manager without modification

# Return a simple attribute set for direct import by other modules
rec {
  aliases = {
    # Shell utilities
    c = "clear";

    # Enhanced file operations
    ll =
      "eza --long --header --links --group-directories-first --color-scale --time-style=iso --all --git";
    lt = "eza --tree --level=2 --group-directories-first --git";

    # Better defaults
    vim = "nvim";
    cat = "bat";
    tree = "tree -C";
    # System maintenance shortcuts
    nix-clean =
      "echo '🧹 Starting cleanup...' && nix-collect-garbage --delete-older-than 7d && echo '✨ Quick cleanup complete'";
    nix-clean-deep =
      "echo '🧹 Starting deep cleanup...' && nix-collect-garbage -d && nix store optimise && echo '✨ Deep cleanup complete'";

    # Update management
    nix-update = "nix flake update";
    nix-check-updates = "nix flake show --json --all-systems | jq '.inputs'";

    # Development shortcuts
    ports = "sudo lsof -i -P -n | grep LISTEN";

    # GitHub tools
    ghd = "gh-dash";

    # Kubernetes tools
    k = "kubectl";

    # Git aliases
    gst = "git status";
    gco = "git checkout";
    gcb = "git checkout -b";
    gb = "git branch";
    gp = "git push";
    gl = "git pull";
    ga = "git add";
    gaa = "git add --all";
    gc = "git commit";
    gcm = "git commit -m";
    gca = "git commit --amend";
    gd = "git diff";
    gds = "git diff --staged";
    glog = "git log --oneline --decorate --graph";
    gloga = "git log --oneline --decorate --graph --all";
    gm = "git merge";
    grb = "git rebase";
  };

  # Declarative history configuration for home-manager
  historyConfig = {
    size = 50000;
    save = 50000;
    path = "$HOME/.zsh_history";
    ignoreAllDups = true;
    ignoreDups = true;
    share = true;
    extended = true;
    expireDuplicatesFirst = true;
  };

  # ZSH autosuggestion configuration
  autosuggestionConfig = {
    enable = true;
    strategy = [ "history" "completion" ];
  };

  # History options for shell initialization (setopt commands)
  historyOptions = ''
    # History options - keep only what you need
    setopt hist_reduce_blanks
    setopt share_history
    setopt HIST_EXPIRE_DUPS_FIRST
    setopt APPEND_HISTORY
  '';

  # Common ZSH option settings
  options = ''
    # Directory navigation
    setopt auto_cd             # cd by typing directory name if it's not a command

    # Completion settings
    setopt auto_list           # automatically list choices on ambiguous completion
    setopt auto_menu           # automatically use menu completion
    setopt always_to_end       # move cursor to end if word had one match
    setopt complete_in_word    # allow completion from within a word/phrase
  '';

  # Common session variables
  sessionVariables = {
    DIRENV_LOG_FORMAT = ""; # Make direnv less verbose
    K9S_CONFIG_DIR = "$HOME/.config/k9s"; # Use XDG path on all platforms
    NPM_CONFIG_PREFIX = "$HOME/.npm-global"; # NPM global packages location
    LANG = "en_GB.UTF-8"; # Locale settings
    LC_ALL = "en_GB.UTF-8";
    # FZF Catppuccin Mocha theme
    FZF_DEFAULT_OPTS =
      "--color=bg+:#313244,bg:#1E1E2E,spinner:#F5E0DC,hl:#F38BA8 --color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC --color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8 --color=selected-bg:#45475A --color=border:#6C7086,label:#CDD6F4";
  };

  # Common session paths
  sessionPath = [
    "$HOME/.local/bin" # pipx-installed Python tools
    "$HOME/.npm-global/bin" # NPM global packages
    "$HOME/.bin" # User custom binaries
  ];

  # Common ZSH completion styling
  completion = ''
    # Simplified completion styling
    zstyle ":completion:*" menu select
    zstyle ":completion:*" group-name ""
    zstyle ":completion:*:default" list-colors "''${(s.:.)LS_COLORS}"

    # More efficient cache settings
    zstyle ":completion:*" use-cache on
    zstyle ":completion:*" cache-path ~/.cache/zsh
  '';

  # Common key bindings
  keybindings = ''
    # Key bindings
    bindkey '\e[A' history-search-backward
    bindkey '\e[B' history-search-forward
  '';

  # Tool initialization commands
  tools = ''
    # Catppuccin Mocha LS_COLORS for eza
    export LS_COLORS="di=38;2;137;180;250:ln=38;2;137;220;235:so=38;2;245;194;231:pi=38;2;249;226;175:ex=38;2;243;139;168:bd=38;2;137;180;250;48;2;49;50;68:cd=38;2;137;180;250;48;2;69;71;90:su=38;2;30;30;46;48;2;243;139;168:sg=38;2;30;30;46;48;2;137;180;250:tw=38;2;30;30;46;48;2;166;227;161:ow=38;2;30;30;46;48;2;249;226;175:*.md=38;2;166;227;161:*.json=38;2;249;226;175:*.nix=38;2;137;180;250:*.lua=38;2;137;220;235:*.yaml=38;2;245;194;231"

    # Zoxide initialization (skip in Claude Code to avoid cd override issues)
    if command -v zoxide >/dev/null 2>&1 && [[ "$CLAUDECODE" != "1" ]]; then
      eval "$(zoxide init zsh)"
      alias cd=z
    fi

    # FZF shell integration for history search and file finding
    # Skip process substitution in Claude Code to avoid snapshot corruption
    if command -v fzf >/dev/null 2>&1 && [[ -z "$CLAUDE_CODE_SESSION" ]]; then
      source <(fzf --zsh)
    fi

    # Carapace completion initialization
    if command -v carapace >/dev/null 2>&1 && [[ -z "$CLAUDE_CODE_SESSION" ]]; then
      source <(carapace _carapace zsh)
    fi
  '';
}
