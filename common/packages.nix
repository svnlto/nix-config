{ pkgs }:
rec {
  # Core CLI utilities shared across all platforms
  corePackages = with pkgs; [
    oh-my-posh
    hstr
    eza
    zoxide
    bat
    nixfmt-classic
    diff-so-fancy
    # Fonts to match Zed config
    (nerdfonts.override { fonts = [ "Hack" ]; })
  ];

  # Development tools for user environments
  devPackages = with pkgs; [
    gh
    direnv
    ack
  ];

  # macOS system-level packages (things that need to be at system level)
  darwinSystemPackages = with pkgs; [
    git # Needed at system level for SSH integration
    tree # System-level tool
  ];

  # All common packages combined for home-manager
  allCommonPackages = corePackages ++ devPackages;

  # All packages for system level (includes system-specific ones)
  allSystemPackages = darwinSystemPackages;
}
