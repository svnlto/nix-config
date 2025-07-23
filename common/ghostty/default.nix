{ config, pkgs, ... }:

{
  # Ghostty terminal configuration
  home.file.".config/ghostty/config".text = ''
    # Theme (matching Zed config)
    theme = catppuccin-mocha

    # Font configuration (matching Zed config)
    font-family = "Hack Nerd Font"
    font-size = 12
    font-thicken = true

    # Window configuration
    window-padding-x = 10
    window-padding-y = 10
    window-decoration = true
    window-theme = dark
    macos-titlebar-style = tabs

    # Cursor
    cursor-style = block
    cursor-style-blink = false

    # Shell integration
    shell-integration = zsh
    shell-integration-features = cursor,sudo,title

    # Scrollback
    scrollback-limit = 10000

    # Colors and transparency
    background-opacity = 0.95
    unfocused-split-opacity = 0.7

    # Key bindings (corrected for Ghostty)
    keybind = cmd+t=new_tab
    keybind = cmd+w=close_surface
    keybind = cmd+n=new_window
    keybind = cmd+equal=increase_font_size:1
    keybind = cmd+minus=decrease_font_size:1
    keybind = cmd+zero=reset_font_size
    keybind = cmd+c=copy_to_clipboard
    keybind = cmd+v=paste_from_clipboard

    # Split panes
    keybind = cmd+d=new_split:right
    keybind = cmd+shift+d=new_split:down

    # Tab navigation
    keybind = cmd+1=goto_tab:1
    keybind = cmd+2=goto_tab:2
    keybind = cmd+3=goto_tab:3
    keybind = cmd+4=goto_tab:4
    keybind = cmd+5=goto_tab:5
    keybind = cmd+6=goto_tab:6
    keybind = cmd+7=goto_tab:7
    keybind = cmd+8=goto_tab:8
    keybind = cmd+9=goto_tab:9

    # Performance
    macos-option-as-alt = true
    confirm-close-surface = false
  '';
}
