{ config, pkgs, ... }:

{
  # Install TPM (Tmux Plugin Manager)
  home.file.".tmux/plugins/tpm" = {
    source = pkgs.fetchFromGitHub {
      owner = "tmux-plugins";
      repo = "tpm";
      rev = "v3.1.0";
      sha256 = "sha256-CeI9Wq6tHqV68woE11lIY4cLoNY8XWyXyMHTDmFKJKI=";
    };
    recursive = true;
  };

  # Merged tmux configuration combining productivity features with Neovim-compatible navigation
  home.file.".tmux.conf".text = ''
    # macOS clipboard integration
    set-option -g default-command "reattach-to-user-namespace -l $SHELL"

    # Fix Touch ID authentication in tmux
    # Enable use of the macOS keychain for SSH keys
    set -g update-environment "SSH_ASKPASS SSH_AUTH_SOCK SSH_AGENT_PID SSH_CONNECTION DISPLAY"

    # Terminal settings - optimized for Ghostty
    set-option -g default-terminal "tmux-256color"
    set-option -ga terminal-overrides ",xterm-ghostty:Tc,tmux-256color:Tc"
    set-option -ga terminal-overrides ",xterm-ghostty:RGB,tmux-256color:RGB"

    # Cursor configuration - pink blinking cursor
    set-option -ga terminal-overrides ',*:Ss=\E[%p1%d q:Se=\E[2 q'
    set-option -g cursor-style blinking-block
    set-option -g cursor-colour "#FF24C0"

    # Essential vim integration - zero escape delay
    set -sg escape-time 0

    # Focus events for vim/neovim
    set -g focus-events on

    # Start windows and panes at 1, not 0
    set -g base-index 1
    set -g pane-base-index 1

    # Renumber windows when one is closed
    set -g renumber-windows on

    # Increase scrollback buffer size (from your existing config)
    set -g history-limit 50000

    # Enable mouse support
    set -g mouse on

    # Don't exit tmux when closing a session
    set -g detach-on-destroy off

    # Status bar refresh rate
    set -g status-interval 60

    # Enable activity alerts
    setw -g monitor-activity on
    set -g visual-activity on

    # Remap prefix to Ctrl-a (from your existing config)
    set -g prefix C-a
    unbind C-b
    bind C-a send-prefix

    # Traditional prefix-based navigation (keeping your existing workflow)
    bind h select-pane -L
    bind j select-pane -D
    bind k select-pane -U
    bind l select-pane -R

    # Direct Ctrl+hjkl navigation (your main request!) with vim-tmux-navigator
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

    # Quick pane cycling with Ctrl-a (from your existing config)
    unbind ^A
    bind ^A select-pane -t :.+

    # Smart splits that inherit current directory (from your existing config)
    bind '"' split-window -c "#{pane_current_path}"
    bind % split-window -h -c "#{pane_current_path}"
    bind c new-window -c "#{pane_current_path}"

    # Additional intuitive split bindings
    bind | split-window -h -c "#{pane_current_path}"
    bind - split-window -v -c "#{pane_current_path}"

    # Pane resizing with arrow keys (from your existing config)
    bind Right resize-pane -R 8
    bind Left resize-pane -L 8
    bind Up resize-pane -U 4
    bind Down resize-pane -D 4

    # Vim-style pane resizing (alternative)
    bind -r H resize-pane -L 5
    bind -r J resize-pane -D 5
    bind -r K resize-pane -U 5
    bind -r L resize-pane -R 5

    # Copy mode with vim keybindings
    setw -g mode-keys vi
    bind-key -T copy-mode-vi 'v' send -X begin-selection
    bind-key -T copy-mode-vi 'y' send -X copy-pipe-and-cancel "reattach-to-user-namespace pbcopy"

    # Mouse wheel scrolling in copy mode
    bind-key -T copy-mode-vi WheelUpPane send -X scroll-up
    bind-key -T copy-mode-vi WheelDownPane send -X scroll-down
    bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "reattach-to-user-namespace pbcopy"

    # Config reload (from your existing config)
    unbind r
    bind r source-file ~/.tmux.conf \; display "Reloaded!"

    # Clear screen with prefix C-l (from your existing config)
    bind C-l send-keys 'C-l'

    # Clear history with prefix + K (capital K to avoid conflict with pane navigation)
    bind-key K clear-history

    # Restore pane navigation that was accidentally removed
    # This maintains your existing Ctrl+A+hjkl navigation pattern

    # Window navigation
    bind -n S-Left previous-window
    bind -n S-Right next-window

    # Catppuccin theme configuration
    set -g @catppuccin_flavor 'mocha'
    set -g @catppuccin_window_status_style "basic"

    # Configure Catppuccin status modules
    set -g @catppuccin_status_modules_right "session host date_time"
    set -g @catppuccin_status_modules_left ""
    set -g @catppuccin_date_time_text "%Y-%m-%d %H:%M"

    # Status bar spacing and appearance
    set -g @catppuccin_status_left_separator " "
    set -g @catppuccin_status_right_separator " "
    set -g @catppuccin_status_connect_separator "yes"

    # Window status padding
    set -g @catppuccin_window_left_separator ""
    set -g @catppuccin_window_right_separator " "
    set -g @catppuccin_window_middle_separator " | "
    set -g @catppuccin_window_number_position "left"

    # TPM (Tmux Plugin Manager) configuration
    # Plugins will be installed to ~/.tmux/plugins/
    set -g @plugin 'tmux-plugins/tpm'
    set -g @plugin 'catppuccin/tmux#v2.1.3'
    set -g @plugin 'tmux-plugins/tmux-resurrect'
    set -g @plugin 'tmux-plugins/tmux-continuum'

    # tmux-resurrect settings
    set -g @resurrect-strategy-vim 'session'
    set -g @resurrect-strategy-nvim 'session'
    set -g @resurrect-capture-pane-contents 'on'

    # tmux-continuum settings
    set -g @continuum-restore 'on'
    set -g @continuum-save-interval '15'

    # Initialize TMUX plugin manager (keep this line at the very bottom of tmux.conf)
    run '~/.tmux/plugins/tpm/tpm'
  '';
}
