{ pkgs }:
rec {
  corePackages = with pkgs; [
    oh-my-posh
    eza
    zoxide
    bat
    nixfmt
    diff-so-fancy
    nerd-fonts.hack
    carapace
    ack
    ripgrep
    fzf
    curl
    wget
    nodejs_26
  ];

  devPackages = with pkgs; [
    gh
    gh-dash
    glab
    lazygit
    lazyjj
    jjui
    direnv
    # pipx's test suite is broken on nixpkgs 26.05 — skip until a backport lands.
    (pipx.overridePythonAttrs (_: {
      doCheck = false;
    }))
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

  darwinPackages = with pkgs; [ ];

  darwinSystemPackages = with pkgs; [
    git
    tree
  ];

  allCommonPackages = corePackages ++ devPackages;
}
