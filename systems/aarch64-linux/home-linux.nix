# Generic aarch64-linux Home Manager configuration
# This configuration can be used for any Linux ARM64 environment (VMs, containers, cloud instances)
{ config, pkgs, username ? "user", ... }:

let sharedZsh = import ../../common/zsh/shared.nix;
in {
  imports =
    [ ../../common/home-packages.nix ../../common/claude-code/default.nix ];

  # Home Manager configuration for Linux
  home = {
    username = username;
    homeDirectory = "/home/${username}";
    stateVersion = "24.05"; # Manage this manually for now
  };

  # Base Nix configuration for Linux environments
  nixpkgs.config.allowUnfree = true;
  nix = {
    package = pkgs.nix;
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      use-case-hack = true;
      fallback = true;
    };
  };

  # Enable direnv using home-manager module
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
    config = { global = { hide_env_diff = true; }; };
  };

  # Set direnv log format to be less verbose
  home.sessionVariables = {
    DIRENV_LOG_FORMAT = "";
    EDITOR = "nvim";
    BROWSER = "firefox";
    TERMINAL = "alacritty";
  };

  # GitHub CLI configuration
  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
      editor = "nvim"; # Use nvim on Linux instead of zed
      prompt = "enabled";
    };
  };

  # ZSH configuration for Linux
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

    # Common aliases from shared config plus Linux-specific ones
    shellAliases = sharedZsh.aliases // {
      # Home Manager rebuild commands
      hmswitch =
        "home-manager switch --flake ${config.home.homeDirectory}/.config/nix#linux";
      hm-user =
        "home-manager switch --flake ${config.home.homeDirectory}/.config/nix#$(whoami)";

      # Linux system utilities
      sysinfo = "neofetch";
      meminfo = "free -h";
      cpuinfo = "lscpu";
      diskinfo = "df -h";

      # Package management helpers
      search = "nix search nixpkgs";
      install = "nix profile install nixpkgs#";

      # Docker shortcuts (if available)
      dps = "docker ps";
      dimg = "docker images";
      dlog = "docker logs";

      # Network utilities
      ping = "ping -c 5";
      wget = "wget -c";

      # Linux system update shortcuts
      hm-upgrade =
        "nix flake update ${config.home.homeDirectory}/.config/nix && hmswitch";
      nix-status = ''
        echo '📊 Linux Home Manager Status' && echo '===============================' && echo "System: $(uname -s) $(uname -r)" && echo "User: $(whoami)" && echo "Home: ${config.home.homeDirectory}" && echo "Store size: $(du -sh /nix/store 2>/dev/null | cut -f1 || echo 'Unknown')" && echo "Generations: $(home-manager generations 2>/dev/null | wc -l | xargs || echo 'Unknown')" && echo "Config path: ~/.config/nix" && echo "Git status: $(cd ~/.config/nix && git status --porcelain 2>/dev/null | wc -l | xargs || echo '0') uncommitted changes"'';
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

  # Additional Linux packages for development environments
  home.packages = with pkgs; [
    # System monitoring and utilities
    htop
    neofetch
    curl
    wget

    # Development tools
    docker-compose

    # Text editors (fallbacks)
    nano
    vim
  ];

  # Disable fish if it causes issues (like in the original vagrant config)
  programs.fish.enable = false;
}
