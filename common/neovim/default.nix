_:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    # The Lua/LazyVim config doesn't use the Ruby or Python3 providers.
    withRuby = false;
    withPython3 = false;
  };

  home.file.".config/nvim" = {
    source = ./.;
    recursive = true;
  };
}
