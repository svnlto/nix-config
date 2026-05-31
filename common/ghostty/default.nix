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
      window-decoration = auto
      macos-window-buttons = hidden
      macos-titlebar-style = transparent
      macos-titlebar-proxy-icon = hidden
      background-opacity = 0.85

      cursor-style = block
      cursor-style-blink = true
      cursor-color = "#ff00ff"

      shell-integration = zsh
      shell-integration-features = cursor,sudo,title

      scrollback-limit = ${toString constants.history.scrollbackBytes}

      mouse-hide-while-typing = true

      link-url = true

      ${lib.optionalString pkgs.stdenv.isDarwin ''
        macos-option-as-alt = true
      ''}
      confirm-close-surface = false
    '';
  };
}
