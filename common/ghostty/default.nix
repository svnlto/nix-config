{ pkgs, lib, ... }:

let constants = import ../constants.nix;
in {
  # Ghostty terminal configuration (GUI terminal — skip in containers/servers)
  home.file.".config/ghostty/config" = lib.mkIf (!pkgs.stdenv.isLinux) {
    text = ''
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
      background-opacity = 0.85

      cursor-style = block
      cursor-style-blink = true
      cursor-color = "#ff00ff"

      shell-integration = zsh
      shell-integration-features = cursor,sudo,title

      scrollback-limit = ${toString constants.history.scrollbackLines}

      mouse-hide-while-typing = true
      click-repeat-interval = 300

      link-url = true

      ${lib.optionalString pkgs.stdenv.isLinux ''
        # Linux-specific: disable problematic GTK settings
        gtk-single-instance = false

        # Linux: use Ctrl+V for paste (macOS-style, not Ctrl+Shift+V)
        keybind = ctrl+v=paste_from_clipboard
        keybind = ctrl+c=copy_to_clipboard
      ''}

      ${lib.optionalString pkgs.stdenv.isDarwin ''
        macos-option-as-alt = true
      ''}
      confirm-close-surface = false
    '';
  };
}
