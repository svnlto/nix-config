_:

{
  # Neovim program configuration
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  # Neovim configuration files - copy entire directory structure
  home.file.".config/nvim" = {
    source = ./.;
    recursive = true;
  };
}
