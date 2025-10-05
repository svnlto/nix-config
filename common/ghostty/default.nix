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

    window-theme = dark
    window-padding-x = 2
    window-padding-y = 0
    window-decoration = true
    macos-window-buttons = hidden
    macos-titlebar-style = transparent
    macos-titlebar-proxy-icon = hidden

    cursor-style = block
    cursor-style-blink = true
    cursor-color = "#ff00ff"

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
