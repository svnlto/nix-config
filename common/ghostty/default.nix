{ config, pkgs, ... }:

{
  # Ghostty terminal configuration
  home.file.".config/ghostty/config".text = ''
    theme = Catppuccin Mocha

    font-family = "Hack Nerd Font"
    font-size = 12
    font-thicken = true
    adjust-cell-height = 7
    adjust-cell-width = -1

    window-padding-x = 2
    window-padding-y = 0
    window-decoration = false
    window-theme = dark
    macos-titlebar-style = hidden

    cursor-style = block
    cursor-style-blink = true

    shell-integration = zsh
    shell-integration-features = cursor,sudo,title

    scrollback-limit = 50000

    mouse-hide-while-typing = true
    click-repeat-interval = 300

    link-url = true

    macos-option-as-alt = true
    confirm-close-surface = false
  '';
}
