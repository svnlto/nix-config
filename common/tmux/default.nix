{ config, pkgs, ... }:

{
  # tmux configuration with Neovim-compatible navigation
  home.file.".tmux.conf".text = ''
    # Terminal settings
    set-option -g default-terminal "screen-256color"
    set-option -ga terminal-overrides ",xterm-256color:Tc"

    # Enable mouse support
    set -g mouse on

    # Remap prefix to Ctrl-a (optional - you can keep default Ctrl-b)
    # set -g prefix C-a
    # unbind C-b
    # bind-key C-a send-prefix

    # Use vim keybindings for pane navigation (matching Neovim exactly)
    bind h select-pane -L
    bind j select-pane -D
    bind k select-pane -U
    bind l select-pane -R

    # Smart pane switching with awareness of Vim splits (vim-tmux-navigator style)
    # Using Ctrl+hjkl to match your Neovim config exactly
    is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
        | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$'"
    bind-key -n 'C-h' if-shell "$is_vim" 'send-keys C-h'  'select-pane -L'
    bind-key -n 'C-j' if-shell "$is_vim" 'send-keys C-j'  'select-pane -D'
    bind-key -n 'C-k' if-shell "$is_vim" 'send-keys C-k'  'select-pane -U'
    bind-key -n 'C-l' if-shell "$is_vim" 'send-keys C-l'  'select-pane -R'

    tmux_version='$(tmux -V | sed -En "s/^tmux ([0-9]+(\\.[0-9]+)?).*/\\1/p")'
    if-shell -b '[ "$(echo "$tmux_version < 3.0" | bc)" = 1 ]' \
        "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\'  'select-pane -l'"
    if-shell -b '[ "$(echo "$tmux_version >= 3.0" | bc)" = 1 ]' \
        "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\\\'  'select-pane -l'"

    bind-key -T copy-mode-vi 'C-h' select-pane -L
    bind-key -T copy-mode-vi 'C-j' select-pane -D
    bind-key -T copy-mode-vi 'C-k' select-pane -U
    bind-key -T copy-mode-vi 'C-l' select-pane -R
    bind-key -T copy-mode-vi 'C-\' select-pane -l

    # Split panes more intuitively (matching common expectations)
    bind | split-window -h -c "#{pane_current_path}"
    bind - split-window -v -c "#{pane_current_path}"
    unbind '"'
    unbind %

    # Pane resizing with vim-style keys
    bind -r H resize-pane -L 5
    bind -r J resize-pane -D 5
    bind -r K resize-pane -U 5
    bind -r L resize-pane -R 5

    # Copy mode with vim keybindings
    setw -g mode-keys vi
    bind-key -T copy-mode-vi 'v' send -X begin-selection
    bind-key -T copy-mode-vi 'y' send -X copy-selection-and-cancel

    # Window navigation
    bind -n S-Left previous-window
    bind -n S-Right next-window

    # Quick pane cycling
    bind -n M-Left select-pane -L
    bind -n M-Right select-pane -R
    bind -n M-Up select-pane -U
    bind -n M-Down select-pane -D

    # Start windows and panes at 1, not 0
    set -g base-index 1
    setw -g pane-base-index 1

    # Renumber windows when one is closed
    set -g renumber-windows on

    # Increase scrollback buffer size
    set -g history-limit 10000

    # Enable activity alerts
    setw -g monitor-activity on
    set -g visual-activity on

    # Don't exit tmux when closing a session
    set -g detach-on-destroy off

    # Theme configuration (matching Catppuccin Mocha from your Neovim config)
    # Status bar
    set -g status-bg "#1e1e2e"
    set -g status-fg "#cdd6f4"
    set -g status-interval 1

    # Window status
    setw -g window-status-current-style "fg=#1e1e2e,bg=#89b4fa,bold"
    setw -g window-status-style "fg=#7f849c,bg=#313244"

    # Pane borders
    set -g pane-border-style "fg=#313244"
    set -g pane-active-border-style "fg=#89b4fa"

    # Message text
    set -g message-style "bg=#f38ba8,fg=#1e1e2e"
    set -g message-command-style "bg=#f38ba8,fg=#1e1e2e"

    # Status bar format
    set -g status-left-length 100
    set -g status-right-length 100
    set -g status-left "#[fg=#1e1e2e,bg=#89b4fa,bold] #S #[fg=#89b4fa,bg=#313244]"
    set -g status-right "#[fg=#7f849c,bg=#313244] %Y-%m-%d #[fg=#cdd6f4]| %H:%M #[fg=#89b4fa,bg=#313244]#[fg=#1e1e2e,bg=#89b4fa,bold] #h "

    # Window status format
    setw -g window-status-format "#[fg=#7f849c,bg=#313244] #I #W "
    setw -g window-status-current-format "#[fg=#313244,bg=#89b4fa]#[fg=#1e1e2e,bg=#89b4fa,bold] #I #W #[fg=#89b4fa,bg=#313244]"

    # Clock mode
    setw -g clock-mode-colour "#89b4fa"
    setw -g clock-mode-style 24
  '';
}
