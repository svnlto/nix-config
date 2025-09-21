{ config, pkgs, ... }:

{
  # Ghostty terminal configuration
  home.file.".config/ghostty/config".text = ''
    # Theme (matching Zed config)
    theme = Catppuccin Mocha

    # Font configuration (matching Zed config)
    font-family = "Hack Nerd Font"
    font-size = 12
    font-thicken = true
    # Zed uses 1.618 line height (golden ratio) - adjust cell to match
    # Font size 12 * 1.618 = ~19.4, so we need about 7-8 extra pixels
    adjust-cell-height = 7
    adjust-cell-width = -1

    # Window configuration
    window-padding-x = 4
    window-padding-y = 2
    window-decoration = true
    window-theme = dark
    macos-titlebar-style = tabs

    # Cursor - pink and blinking
    cursor-style = block
    cursor-style-blink = true
    cursor-color = FF24C0

    # Shell integration
    shell-integration = zsh
    shell-integration-features = cursor,sudo,title

    # Scrollback
    scrollback-limit = 10000

    # Colors and transparency
    background-opacity = 1.0
    unfocused-split-opacity = 1.0

    # Key bindings (corrected for Ghostty)
    keybind = cmd+t=new_tab
    keybind = cmd+w=close_surface
    keybind = cmd+n=new_window
    keybind = cmd+equal=increase_font_size:1
    keybind = cmd+minus=decrease_font_size:1
    keybind = cmd+zero=reset_font_size
    keybind = cmd+c=copy_to_clipboard
    keybind = cmd+v=paste_from_clipboard

    # Split panes - Disabled in favor of tmux
    # keybind = cmd+d=new_split:right
    # keybind = cmd+shift+d=new_split:down
    # keybind = cmd+shift+a=new_split:left

    # Navigate between splits - Disabled in favor of tmux (use Ctrl+hjkl)
    # keybind = cmd+h=goto_split:left
    # keybind = cmd+j=goto_split:down
    # keybind = cmd+k=goto_split:up
    # keybind = cmd+l=goto_split:right

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

    # Mouse and link handling
    mouse-hide-while-typing = true
    click-repeat-interval = 300

    # Link detection and opening - enables Cmd+click on URLs
    link-url = true

    # Performance
    macos-option-as-alt = true
    confirm-close-surface = false
  '';
}
