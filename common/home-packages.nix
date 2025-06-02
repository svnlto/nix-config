{ pkgs, ... }:

{
  # Common packages for all platforms (user-level)
  home.packages = with pkgs; [
    # CLI utilities
    oh-my-posh
    hstr
    eza
    ack
    zoxide
    bat
    direnv

    # Development tools
    gh
    nixfmt-classic
    diff-so-fancy
  ];
}
