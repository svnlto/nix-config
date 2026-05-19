{ pkgs }:
let
  herdr = pkgs.stdenv.mkDerivation rec {
    pname = "herdr";
    version = "0.5.10";

    src = pkgs.fetchurl {
      url = let
        platform = {
          "aarch64-darwin" = "macos-aarch64";
          "aarch64-linux" = "linux-aarch64";
          "x86_64-linux" = "linux-x86_64";
        }.${pkgs.stdenv.hostPlatform.system};
      in "https://github.com/ogulcancelik/herdr/releases/download/v${version}/herdr-${platform}";
      sha256 = {
        "aarch64-darwin" =
          "0l9dwlpp2q62p7242rg4g0qz4g022c46cacclddfpd1mr0w7zal4";
        "aarch64-linux" =
          "1f999cbd0clcdxglybw2alppfns1ms6vj3g85lnidl2lrnk64bcp";
        "x86_64-linux" = "0k7xcmq979dzim204akfwjjgnlnsh6fh0ylpf974fnyq97wi8p7l";
      }.${pkgs.stdenv.hostPlatform.system};
    };

    dontUnpack = true;

    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/herdr
      chmod +x $out/bin/herdr
    '';
  };
in rec {
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
    k9s
    home-manager
    htop
    neofetch
    docker-compose
    shellcheck
    fd
    unzip
    gcc
    tree-sitter
    gnused
    devbox
  ];

  # macOS-specific packages
  # These packages only work on macOS
  darwinPackages = with pkgs; [ ];

  # macOS system-level packages
  # These packages need to be installed at the system level for proper integration
  darwinSystemPackages = with pkgs; [ git tree ];

  # Convenient package combination for user-level packages
  allCommonPackages = corePackages ++ devPackages ++ [ herdr ];
}
