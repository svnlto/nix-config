# This file contains truly shared ZSH configuration that works in both
# nix-darwin and home-manager without modification

# Return a simple attribute set for direct import by other modules
rec {
  # Common shell aliases defined as a regular Nix attribute set
  aliases = {
    # Shell utilities
    reloadcli = "source $HOME/.zshrc";
    c = "clear";

    # Enhanced file operations
    ll =
      "eza --long --header --links --group-directories-first --color-scale --time-style=iso --all";
    lt = "eza --tree --level=2 --group-directories-first";

    # Better defaults
    vim = "nvim";
    cat = "bat";
    tree = "tree -C";

    # Nix utilities (platform-agnostic)
    nix-shell-pure = "nix-shell --pure";
    nix-gc = "nix-collect-garbage -d";
    nix-search = "nix search nixpkgs";
    nix-which = "nix-locate --top-level";

    # System maintenance shortcuts
    nix-health = "nix store verify --all";
    nix-repair = "nix store repair --all";
    nix-clean =
      "echo '🧹 Starting cleanup...' && nix-collect-garbage --delete-older-than 7d && echo '✨ Quick cleanup complete'";
    nix-clean-deep =
      "echo '🧹 Starting deep cleanup...' && nix-collect-garbage -d && nix store optimise && echo '✨ Deep cleanup complete'";
    system-info = "nix-info -m";

    # Quick diagnostics
    check-flake = "nix flake check";
    show-config = "nix show-config";
    list-gens =
      "nix profile list --profile /nix/var/nix/profiles/system 2>/dev/null || echo 'No system profile found'";

    # Update management
    nix-update = "nix flake update";
    nix-check-updates = "nix flake show --json | jq '.inputs'";

    # Development shortcuts
    ports = "sudo lsof -i -P -n | grep LISTEN";
  };

  # Declarative history configuration for home-manager
  historyConfig = {
    size = 10000;
    save = 10000;
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
    bindkey '^r' _atuin_search_widget  # Ctrl+R for atuin history search
    bindkey '\e[A' history-search-backward
    bindkey '\e[B' history-search-forward
  '';

  # Tool initialization commands (now uses shared environment)
  tools = ''
        # Import shared environment setup
        ${(import ../environment.nix).shellEnvironment}

        # Catppuccin Mocha LS_COLORS for eza
        export LS_COLORS="di=38;2;137;180;250:ln=38;2;137;220;235:so=38;2;245;194;231:pi=38;2;249;226;175:ex=38;2;243;139;168:bd=38;2;137;180;250;48;2;49;50;68:cd=38;2;137;180;250;48;2;69;71;90:su=38;2;30;30;46;48;2;243;139;168:sg=38;2;30;30;46;48;2;137;180;250:tw=38;2;30;30;46;48;2;166;227;161:ow=38;2;30;30;46;48;2;249;226;175:*.md=38;2;166;227;161:*.json=38;2;249;226;175:*.nix=38;2;137;180;250:*.lua=38;2;137;220;235:*.yaml=38;2;245;194;231"

        # Simple zoxide initialization
        if command -v zoxide >/dev/null 2>&1; then
          eval "$(zoxide init zsh)"
        fi

        # Simple oh-my-posh initialization
        if command -v oh-my-posh >/dev/null 2>&1; then
          eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/default.omp.json)"
        fi

        # Atuin shell history initialization with vim mode
        if command -v atuin >/dev/null 2>&1; then
          # Create atuin config directory if it doesn't exist
          mkdir -p ~/.config/atuin

          # Create minimal atuin configuration with vim keybindings
          cat > ~/.config/atuin/config.toml << 'EOF'
    # Atuin Configuration - Cross-platform shell history
    keymap_mode = "vim-insert"
    EOF

          # Initialize atuin
          eval "$(atuin init zsh)"
        fi

        # Carapace completion initialization
        if command -v carapace >/dev/null 2>&1; then
          source <(carapace _carapace zsh)
        fi
  '';

  # Custom scripts that need to be sourced in ZSH
  customScripts = ''
    # Load worktree manager (sourced from external file)
    # This will be populated by the scripts module
  '';

  # Module metadata
  meta = {
    description =
      "Shared ZSH configuration for both nix-darwin and home-manager";
  };
}
