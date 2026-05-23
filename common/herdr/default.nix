_:

{
  xdg.configFile."herdr/config.toml".text = ''
    [keys]
    prefix = "ctrl+a"
    new_workspace = "n"
    rename_workspace = "shift+n"
    close_workspace = "shift+d"
    new_tab = "c"
    split_vertical = "v"
    split_horizontal = "-"
    close_pane = "x"
    zoom = "f"
    resize_mode = "r"
    detach = "q"
    reload_config = "R"
    focus_pane_left = "ctrl+h"
    focus_pane_down = "ctrl+j"
    focus_pane_up = "ctrl+k"
    focus_pane_right = "ctrl+l"

    [[keys.command]]
    key = "g"
    type = "pane"
    command = "lazygit"

    [theme]
    name = "catppuccin"

    [theme.custom]
    accent = "#313244"
    panel_bg = "reset"

    [ui]
    mouse_capture = true
    confirm_close = true
    show_agent_labels_on_pane_borders = true

    [ui.toast]
    delivery = "herdr"

    [ui.sound]
    enabled = false
  '';

  programs.zsh.shellAliases = { h = "herdr"; };
}
