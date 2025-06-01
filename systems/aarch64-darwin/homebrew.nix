{ config, pkgs, ... }:

{
  homebrew = {
    enable = true;
    taps = [ "FelixKratz/formulae" "hashicorp/tap" ];
    brews = [ "mas" "dockutil" "pre-commit" "rclone" "qemu"];
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
      "zoom"
      "slack"
      "whatsapp"
      "telegram"

      # Development & Terminal
      "visual-studio-code"
      "hashicorp/tap/hashicorp-vagrant"
      "vagrant"
      "zed"
      "linear-linear"

      # Networking & Utilities
      "tailscale"

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
