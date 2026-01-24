{ pkgs }: rec {
  # Core system utilities - essential tools for all environments
  # These packages provide fundamental CLI improvements and are used daily
  corePackages = with pkgs; [
    oh-my-posh
    eza
    zoxide
    bat
    nixfmt-classic
    diff-so-fancy
    nerd-fonts.hack
    carapace
    ack
    ripgrep
    fzf
    curl
    wget
  ];

  # Development tools - programming and productivity utilities
  # These tools support software development and system administration
  devPackages = with pkgs; [
    gh
    gh-dash
    lazygit
    direnv
    pipx
    tmux
    tmuxinator
    k9s
    home-manager
    htop
    neofetch
    docker-compose
    shellcheck
  ];

  # macOS-specific packages
  # These packages only work on macOS
  darwinPackages = with pkgs;
    [
      reattach-to-user-namespace # macOS tmux integration for clipboard/notification access
    ];

  # macOS system-level packages
  # These packages need to be installed at the system level for proper integration
  darwinSystemPackages = with pkgs; [ git tree ];

  # Convenient package combination for user-level packages
  allCommonPackages = corePackages ++ devPackages;
}
