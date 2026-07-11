{ pkgs }:
rec {
  # Core CLI utilities used daily across all environments
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

  # Development and system-administration tooling
  devPackages = with pkgs; [
    gh
    gh-dash
    lazygit
    direnv
    pipx
    k9s
    home-manager
    htop
    fastfetch
    docker-compose
    shellcheck
    fd
    unzip
    gcc
    tree-sitter
    gnused
    devbox
  ];

  # macOS-only packages
  darwinPackages = with pkgs; [ ];

  # Installed at system level on macOS for proper integration
  darwinSystemPackages = with pkgs; [
    git
    tree
  ];

  # Convenient package combination for user-level packages
  allCommonPackages = corePackages ++ devPackages;
}
