{ config, pkgs, username, lib, ... }:

let sharedZsh = import ../../common/zsh/shared.nix;
in {
  imports = [
    ../../common/home-packages.nix
    ../../common/claude-code/default.nix
    ../../common/lazygit/default.nix
    ../../common/scripts/default.nix
  ];

  # Home Manager configuration for macOS
  home = {
    username = username;
    homeDirectory = "/Users/${username}";
    stateVersion = "24.05"; # Manage this manually for now
  };

  # Enable direnv using home-manager module
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;

    # Reduce verbosity
    config = { global = { hide_env_diff = true; }; };
  };

  # Set direnv log format to be less verbose
  home.sessionVariables = { DIRENV_LOG_FORMAT = ""; };

  # GitHub CLI configuration
  programs.gh = {
    enable = true;
    settings = {
      # Default protocol when cloning repositories
      git_protocol = "ssh";

      # Default editor
      editor = "zed";

      # Prompt for every command
      prompt = "enabled";
    };
  };

  programs.zsh = {
    enable = true;

    enableCompletion = true;
    autosuggestion = sharedZsh.autosuggestionConfig;
    history = sharedZsh.historyConfig;

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" ];
      theme = "";
    };

    # Common aliases from shared config plus macOS-specific ones
    shellAliases = sharedZsh.aliases // {
      # macOS system rebuild (auto-detects hostname)
      nixswitch =
        "sudo darwin-rebuild switch --flake ${config.home.homeDirectory}/.config/nix#$(scutil --get LocalHostName)";
      darwin-rebuild =
        "sudo darwin-rebuild switch --flake ${config.home.homeDirectory}/.config/nix#$(scutil --get LocalHostName)";

      # macOS-specific utilities
      flushdns =
        "sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder";
      showfiles =
        "defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder";
      hidefiles =
        "defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder";

      # Homebrew shortcuts (if using nix-homebrew)
      brewup = "brew update && brew upgrade";
      brewclean = "brew cleanup";

      # macOS system update shortcuts
      nix-upgrade =
        "nix flake update ${config.home.homeDirectory}/.config/nix && nixswitch";
      nix-upgrade-clean =
        "nix flake update ${config.home.homeDirectory}/.config/nix && CLEANUP_ON_REBUILD=true nixswitch";
      nix-status = ''
        echo '📊 macOS Nix Configuration Status' && echo '==================================' && echo "System: $(sw_vers -productName) $(sw_vers -productVersion)" && echo "Hostname: $(scutil --get LocalHostName)" && echo "Last build: $(stat -f '%Sm' -t '%Y-%m-%d %H:%M:%S' /run/current-system 2>/dev/null || echo 'Unknown')" && echo "Store size: $(du -sh /nix/store 2>/dev/null | cut -f1 || echo 'Unknown')" && echo "Generations: $(darwin-rebuild --list-generations 2>/dev/null | wc -l | xargs || echo 'Unknown')" && echo "Config path: ~/.config/nix" && echo "Git status: $(cd ~/.config/nix && git status --porcelain | wc -l | xargs) uncommitted changes"'';
      nix-backup =
        "sudo nix-env --profile /nix/var/nix/profiles/system --list-generations | tail -1";

      # Manual cleanup commands (more efficient than automatic)
      nix-cleanup-quick =
        "echo '🧹 Quick cleanup...' && nix-collect-garbage --delete-older-than 7d";
      nix-cleanup-deep =
        "echo '🧹 Deep cleanup...' && nix-collect-garbage --delete-older-than 30d && nix store optimise";
      nix-cleanup-aggressive =
        "echo '⚠️  Aggressive cleanup (keeps only current generation)...' && nix-collect-garbage -d && nix store optimise";
    };

    # Additional ZSH initialization
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

      # Ensure Oh My Posh is properly initialized
      if command -v oh-my-posh &> /dev/null; then
        eval "$(oh-my-posh --init --shell zsh --config ~/.config/oh-my-posh/default.omp.json)"
      fi

    '';
  };

  # Install Oh My Posh theme
  home.file.".config/oh-my-posh/default.omp.json".source =
    ../../common/zsh/default.omp.json;
}
