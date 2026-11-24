{ pkgs }:
let
  inherit (pkgs) python3Packages;

  copier-template-extensions = python3Packages.buildPythonPackage rec {
    pname = "copier-template-extensions";
    version = "0.3.4";
    format = "wheel";
    src = python3Packages.fetchPypi {
      pname = "copier_template_extensions";
      inherit version format;
      dist = "py3";
      python = "py3";
      hash = "sha256-gcZq3y2/d77fjK+G1ElFSLKUZxzbJ29jcOsRH0Dzizk=";
    };
    # Its only dependency is copier itself, which the wrapping copier env already provides.
    dontCheckRuntimeDeps = true;
  };

  copierWithExtensions = python3Packages.toPythonApplication (
    python3Packages.copier.overridePythonAttrs (old: {
      dependencies = old.dependencies ++ [ copier-template-extensions ];
    })
  );
in
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
    copierWithExtensions
    spec-kit
  ];

  darwinSystemPackages = with pkgs; [
    git
    tree
  ];

  allCommonPackages = corePackages ++ devPackages;
}
