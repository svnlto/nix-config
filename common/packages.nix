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

  # Package selection utility - filters out null packages
  # Useful for conditional package inclusion based on system or user preferences
  selectPackages = packages:
    if packages == null then
      [ ]
    else
      builtins.filter (pkg: pkg != null) packages;

  # Convenient package combinations for different use cases
  allCommonPackages = corePackages ++ devPackages;
  allSystemPackages = darwinSystemPackages;
}
