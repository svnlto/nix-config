_:

{
  xdg.configFile."sesh/sesh.toml".text = ''
    [default_session]
    startup_command = "tmux split-window -h -l 37% -c '#{pane_current_path}' && tmux split-window -v -l 31% -c '#{pane_current_path}' && tmux send-keys -t 2 'claude' Enter && tmux select-pane -t 1 && nvim"

    [[session]]
    name = "config"
    path = "~/.config/nix"

    [[session]]
    name = "homelab"
    path = "~/Projects/homelab"

    [[session]]
    name = "platform-next"
    path = "~/Projects/msg/platform-next/"

    [[session]]
    name = "kaas-helm-validator"
    path = "~/Projects/msg/kaas-helm-validator/"

    [[session]]
    name = "workstation-configs"
    path = "~/Projects/msg/workstation-configs/"

    [[session]]
    name = "obsidian-vault"
    path = "~/Documents/obsidian-vault/"
  '';
}
