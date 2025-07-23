{ ... }:

{
  # Neovim program configuration
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  # Neovim configuration files
  home.file.".config/nvim/init.lua".source = ./init.lua;
}
