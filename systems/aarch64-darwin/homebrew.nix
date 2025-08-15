{ config, pkgs, ... }:

{
  homebrew = {
    enable = true;
    taps = [ "FelixKratz/formulae" ];
    brews = [ "mas" "dockutil" "pre-commit" "rclone" ];
    casks = [
      # Security & Password Management
      "1password"
      "1password-cli"
      "ledger-live"

      # Productivity Tools
      "raycast"
      "setapp"
      "notion-calendar"
      "notion-mail"

      # Communication & Collaboration
      "linear-linear"
      "slack"
      "zoom"
      "whatsapp"
      "telegram"
      "claude" # desktop

      # Development & Terminal
      "orbstack"
      "zed"
      "ghostty"

      # Networking & Utilities
      "tailscale"

      # Media & Entertainment
      "spotify"
      "vlc"
      "zwift"
      "figma"
    ];
    masApps = { };
    onActivation = {
      cleanup = "zap";
      upgrade = true;
      autoUpdate = true;
    };
  };
}
