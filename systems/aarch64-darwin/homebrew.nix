{ config, pkgs, ... }:

{
  homebrew = {
    enable = true;
    taps = [ "FelixKratz/formulae" "hashicorp/tap" ];
    brews = [ "mas" "dockutil" "pre-commit" "rclone" ];
    casks = [
      # Security & Password Management
      "1password"
      "1password-cli"
      "ledger-live"

      # Productivity Tools
      "raycast"
      "setapp"
      "todoist"
      "notion-calendar"
      "notion-mail"

      # Communication & Collaboration
      "zoom"
      "slack"
      "whatsapp"
      "telegram"

      # Development & Terminal
      "visual-studio-code"
      "iterm2"
      "utm"
      "hashicorp/tap/hashicorp-vagrant"
      "vagrant"

      # Networking & Utilities
      "tailscale"
      "transmission"

      # Media & Entertainment
      "spotify"
      "vlc"
      "zwift"
      "vcv-rack"
      "ableton-live-standard"
    ];
    masApps = { };
    onActivation = {
      cleanup = "zap";
      upgrade = true;
      autoUpdate = true;
    };
  };
}
