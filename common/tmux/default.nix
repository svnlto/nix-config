{ config, pkgs, lib, ... }:

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
    ${lib.optionalString pkgs.stdenv.isDarwin ''
    # macOS clipboard integration
    set-option -g default-command "reattach-to-user-namespace -l $SHELL"
    ''}

    # Fix Touch ID authentication in tmux
    set -g update-environment "SSH_ASKPASS SSH_AUTH_SOCK SSH_AGENT_PID SSH_CONNECTION DISPLAY"

    # Terminal settings - optimized for Ghostty
    set-option -g default-terminal "tmux-256color"
    set-option -ga terminal-overrides ",xterm-ghostty:Tc,tmux-256color:Tc"
    set-option -ga terminal-overrides ",xterm-ghostty:RGB,tmux-256color:RGB"

    # Cursor configuration - fix blinking cursor inside and outside Neovim
    set-option -ga terminal-overrides ',xterm-ghostty:cnorm=\E[?12h\E[?25h'
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

    # Increase scrollback buffer size
    set -g history-limit 50000

    # Enable mouse support
    set -g mouse on

    # Don't exit tmux when closing a session
    set -g detach-on-destroy off

    # Status bar refresh rate
    set -g status-interval 60

    # Disable activity alerts
    setw -g monitor-activity off
    set -g visual-activity off

    # Remap prefix to Ctrl-a
    set -g prefix C-a
    unbind C-b
    bind C-a send-prefix

    # Traditional prefix-based navigation
    bind h select-pane -L
    bind j select-pane -D
    bind k select-pane -U
    bind l select-pane -R

    # Direct Ctrl+hjkl navigation
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
    ${lib.optionalString pkgs.stdenv.isDarwin ''bind-key -T copy-mode-vi 'y' send -X copy-pipe-and-cancel "reattach-to-user-namespace pbcopy"''}
    ${lib.optionalString pkgs.stdenv.isLinux ''bind-key -T copy-mode-vi 'y' send -X copy-pipe-and-cancel "wl-copy"''}

    # Mouse wheel scrolling in copy mode
    bind-key -T copy-mode-vi WheelUpPane send -X scroll-up
    bind-key -T copy-mode-vi WheelDownPane send -X scroll-down
    ${lib.optionalString pkgs.stdenv.isDarwin ''bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "reattach-to-user-namespace pbcopy"''}
    ${lib.optionalString pkgs.stdenv.isLinux ''bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "wl-copy"''}

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

    # Pane border colors - Catppuccin Mocha
    set -g pane-border-style "fg=#45475a"          # Mocha surface1 (inactive border)
    set -g pane-active-border-style "fg=#89b4fa"   # Mocha blue (active border)

    # Status bar - Catppuccin Mocha colors
    set -g status-style "bg=#1e1e2e,fg=#cdd6f4"
    set -g status-left-length 100
    set -g status-right-length 100
    set -g status-justify centre

    # Left: session name
    set -g status-left "#[fg=#89b4fa,bold] #S #[fg=#45475a]│ "

    # Right: date and time (European format: HH:MM DD-MM-YYYY)
    set -g status-right "#[fg=#45475a] │ #[fg=#cdd6f4]%H:%M %d-%m-%Y"

    # Window status format - no backgrounds
    set -g window-status-format "#[fg=#6c7086] #I:#W "
    set -g window-status-current-format "#[fg=#cdd6f4,bold] #I:#W "
    set -g window-status-separator ""

    # TPM (Tmux Plugin Manager) configuration
    # Plugins will be installed to ~/.tmux/plugins/
    set -g @plugin 'tmux-plugins/tpm'
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
