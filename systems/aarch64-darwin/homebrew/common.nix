_:

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

      # Productivity Tools
      "raycast"
      "setapp"
      "obsidian"

      # Communication & Collaboration
      "linear-linear"
      "claude" # desktop

      # Development & Terminal
      "orbstack"
      "ghostty"
      "claude-code"

      # Networking & VPN
      "arc"
      "google-chrome"
      "tailscale-app"
      "mullvad-vpn@beta"

      # Media & Entertainment
      "vlc"
    ];
    masApps = { };
    onActivation = {
      cleanup = "uninstall";
      upgrade = true;
      autoUpdate = true;
    };
  };
}
