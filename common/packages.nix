{ pkgs }: rec {
  # Core system utilities - essential tools for all environments
  # These packages provide fundamental CLI improvements and are used daily
  corePackages = with pkgs; [
    oh-my-posh # Customizable prompt engine for shell theming
    hstr # Shell history suggest box with search capabilities
    eza # Modern replacement for ls with colors and icons
    zoxide # Smarter cd command that learns your habits
    bat # Cat clone with syntax highlighting and git integration
    nixfmt-classic # Nix code formatter for consistent code style
    diff-so-fancy # Enhanced diff visualization with better formatting
    nerd-fonts.hack # Programming font with icons
  ];

  # Development tools - programming and productivity utilities
  # These tools support software development and system administration
  devPackages = with pkgs; [
    gh # GitHub CLI for repository management
    lazygit # Terminal UI for git commands (LazyVim dependency)
    direnv # Environment variable manager per directory
    ack # Text search tool optimized for source code
    ripgrep # Fast text search (required for Neovim Telescope)
    pipx # Python package installer with isolation
    tmux # Terminal multiplexer for session management
    reattach-to-user-namespace # macOS tmux integration for clipboard/notification access
  ];

  # macOS system-level packages
  # These packages need to be installed at the system level for proper integration
  darwinSystemPackages = with pkgs; [
    git # Version control system (system-level for SSH key integration)
    tree # Directory structure visualization tool
  ];

  # Package selection utility - filters out null packages
  # Useful for conditional package inclusion based on system or user preferences
  selectPackages = category: packages:
    if packages == null then
      [ ]
    else
      builtins.filter (pkg: pkg != null) packages;

  # Convenient package combinations for different use cases
  allCommonPackages = corePackages ++ devPackages;
  allSystemPackages = darwinSystemPackages;

  # Essential packages only (minimal installation)
  essentialPackages = [ pkgs.git pkgs.eza pkgs.bat pkgs.ripgrep ];
}
