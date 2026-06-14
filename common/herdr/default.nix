{ config, ... }:

{
  xdg.configFile."herdr/config.toml".source =
    config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/.config/nix/common/herdr/config.toml";

  programs.zsh.shellAliases = { h = "herdr"; };
}
