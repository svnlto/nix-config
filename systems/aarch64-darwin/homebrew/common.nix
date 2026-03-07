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
      "marked-app"

      # Communication & Collaboration
      "claude" # desktop

      # Development & Terminal
      "orbstack"
      "ghostty"
      "claude-code"

      # Networking & VPN
      "arc"
      "google-chrome"

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
