_:

{
  # Neovim program configuration
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    # 26.05 flipped these defaults to false; adopt them — the Lua/LazyVim
    # config doesn't use the Ruby or Python3 providers.
    withRuby = false;
    withPython3 = false;
  };

  # Neovim configuration files - copy entire directory structure
  home.file.".config/nvim" = {
    source = ./.;
    recursive = true;
  };
}
