{ ... }:

{
  homebrew = {
    enable = true;
    taps = [ ];
    brews = [ "mas" "dockutil" "pre-commit" ];
    casks = [
      # Fonts
      "font-sf-pro"

      # Security & Password Management
      "1password"
      "1password-cli"
      "ledger-live"

      # Productivity Tools
      "raycast"
      "setapp"
      "notion-calendar"
      "notion-mail"
      "superwhisper"
      "obsidian"
      "brainfm"

      # Communication & Collaboration
      "linear-linear"
      "slack"
      "whatsapp"
      "telegram"
      "signal"
      "claude" # desktop

      # Development & Terminal
      "orbstack"
      "ghostty"
      "utm"

      # Networking & VPN
      "tailscale-app"
      "mullvad-vpn@beta"

      # Media & Entertainment
      "spotify"
      "vlc"
      "zwift"
    ];
    masApps = { };
    onActivation = {
      cleanup = "uninstall";
      upgrade = true;
      autoUpdate = true;
    };
  };
}
