_:

{
  xdg.configFile."herdr/config.toml".text = ''
    [keys]
    prefix = "ctrl+a"
    new_workspace = "prefix+n"
    rename_workspace = "prefix+shift+n"
    close_workspace = "prefix+shift+d"
    new_tab = "prefix+c"
    split_vertical = "prefix+v"
    split_horizontal = "prefix+-"
    close_pane = "prefix+x"
    zoom = "prefix+f"
    resize_mode = "prefix+r"
    detach = "prefix+q"
    reload_config = "prefix+shift+r"
    focus_pane_left = "prefix+h"
    focus_pane_down = "prefix+j"
    focus_pane_up = "prefix+k"
    focus_pane_right = "prefix+l"

    [[keys.command]]
    key = "prefix+g"
    type = "pane"
    command = "lazygit"

    [theme]
    name = "terminal"

    [theme.custom]
    panel_bg = "reset"

    [terminal]
    default_shell = "zsh"
    new_cwd = "source"

    [ui]
    mouse_capture = true
    mouse_scroll_lines = 5
    confirm_close = true
    show_agent_labels_on_pane_borders = true

    [ui.toast]
    delivery = "herdr"

    [ui.sound]
    enabled = false
  '';

  programs.zsh.shellAliases = { h = "herdr"; };
}
