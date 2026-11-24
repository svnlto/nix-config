let
  constants = import ../constants.nix;
in
rec {
  aliases = {
    c = "clear";

    ll = "eza --long --header --links --group-directories-first --color-scale --time-style=iso --all --git";
    lt = "eza --tree --level=2 --group-directories-first --git";

    vim = "nvim";
    cat = "bat -p";
    tree = "tree -C";

    nix-clean = "echo '🧹 Starting cleanup...' && nix-collect-garbage --delete-older-than 7d && echo '✨ Quick cleanup complete'";
    nix-clean-deep = "echo '🧹 Starting deep cleanup...' && nix-collect-garbage -d && nix store optimise && echo '✨ Deep cleanup complete'";

    nix-update = "nix flake update";
    nix-check-updates = "nix flake show --json --all-systems | jq '.inputs'";
    nix-upgrade = "nix flake update && nixswitch";

    ports = "sudo lsof -i -P -n | grep LISTEN";

    ghd = "gh-dash";

    k = "kubectl";

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

  historyConfig = {
    size = constants.history.shellHistorySize;
    save = constants.history.shellHistorySize;
    path = "$HOME/.zsh_history";
    ignoreAllDups = true;
    share = true;
    extended = true;
    expireDuplicatesFirst = true;
  };

  autosuggestionConfig = {
    enable = true;
    strategy = [
      "history"
      "completion"
    ];
  };

  # share_history and HIST_EXPIRE_DUPS_FIRST come from historyConfig — don't repeat them.
  historyOptions = ''
    setopt hist_reduce_blanks
    setopt APPEND_HISTORY
  '';

  options = ''
    setopt auto_cd
    setopt auto_list
    setopt auto_menu
    setopt always_to_end
    setopt complete_in_word
  '';

  sessionVariables = {
    DIRENV_LOG_FORMAT = ""; # silences direnv
    K9S_CONFIG_DIR = "$HOME/.config/k9s"; # XDG path on all platforms
    NPM_CONFIG_PREFIX = "$HOME/.npm-global";
    LANG = "en_GB.UTF-8";
    LC_ALL = "en_GB.UTF-8";
    # FZF Catppuccin Mocha theme
    FZF_DEFAULT_OPTS = "--color=bg+:#313244,bg:#1E1E2E,spinner:#F5E0DC,hl:#F38BA8 --color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC --color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8 --color=selected-bg:#45475A --color=border:#6C7086,label:#CDD6F4";
  };

  sessionPath = [
    "$HOME/.local/bin" # pipx-installed Python tools
    "$HOME/.npm-global/bin"
    "$HOME/.bin"
  ];

  completion = ''
    zstyle ":completion:*" menu select
    zstyle ":completion:*" group-name ""
    zstyle ":completion:*:default" list-colors "''${(s.:.)LS_COLORS}"

    zstyle ":completion:*" use-cache on
    zstyle ":completion:*" cache-path ~/.cache/zsh
  '';

  keybindings = ''
    bindkey '\e[A' history-search-backward
    bindkey '\e[B' history-search-forward
  '';

  tools = ''
    # Catppuccin Mocha LS_COLORS for eza
    export LS_COLORS="di=38;2;137;180;250:ln=38;2;137;220;235:so=38;2;245;194;231:pi=38;2;249;226;175:ex=38;2;243;139;168:bd=38;2;137;180;250;48;2;49;50;68:cd=38;2;137;180;250;48;2;69;71;90:su=38;2;30;30;46;48;2;243;139;168:sg=38;2;30;30;46;48;2;137;180;250:tw=38;2;30;30;46;48;2;166;227;161:ow=38;2;30;30;46;48;2;249;226;175:*.md=38;2;166;227;161:*.json=38;2;249;226;175:*.nix=38;2;137;180;250:*.lua=38;2;137;220;235:*.yaml=38;2;245;194;231"

    # Skipped in Claude Code — the cd override confuses the agent
    if command -v zoxide >/dev/null 2>&1 && [[ "$CLAUDECODE" != "1" ]]; then
      eval "$(zoxide init zsh)"
      alias cd=z
    fi

    # Process substitution corrupts the Claude Code shell snapshot
    if command -v fzf >/dev/null 2>&1 && [[ -z "$CLAUDE_CODE_SESSION" ]]; then
      source <(fzf --zsh)
    fi

    if command -v carapace >/dev/null 2>&1 && [[ -z "$CLAUDE_CODE_SESSION" ]]; then
      source <(carapace _carapace zsh)
    fi
  '';

  functions = ''
    # Strips quarantine and ad-hoc re-signs a macOS app
    unquarantine() {
      local target="''${1:?Usage: unquarantine <path or App Name>}"
      if [[ "$target" != */* ]]; then
        target="/Applications/''${target}.app"
      fi
      if [[ ! -e "$target" ]]; then
        echo "Not found: $target" >&2
        return 1
      fi
      xattr -cr "$target" && codesign --force --deep --sign - "$target"
      echo "Unquarantined: $target"
    }
  '';
}
