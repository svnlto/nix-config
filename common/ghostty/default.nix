{ pkgs, lib, ... }:

let
  constants = import ../constants.nix;
in
{
  # Ghostty terminal configuration (GUI terminal — skip in containers/servers)
  home.file.".config/ghostty/config" = lib.mkIf (!pkgs.stdenv.isLinux) {
    text = ''
      theme = Catppuccin Mocha

      font-family = "Hack Nerd Font Mono"
      font-size = 12
      font-thicken = true
      adjust-cell-height = 7
      adjust-cell-width = -1

      window-theme = dark
      window-padding-y = 0
      macos-window-buttons = hidden
      macos-titlebar-proxy-icon = hidden
      title = " "
      background-opacity = 0.85

      cursor-style-blink = true
      cursor-color = "#ff00ff"

      shell-integration = zsh
      shell-integration-features = cursor,sudo,title

      scrollback-limit = ${toString constants.history.scrollbackBytes}

      mouse-hide-while-typing = true

      ${lib.optionalString pkgs.stdenv.isDarwin ''
        macos-option-as-alt = true
      ''}
      confirm-close-surface = false
    '';
  };
}
