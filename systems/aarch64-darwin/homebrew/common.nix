_:

{
  homebrew = {
    enable = true;
    taps = [ "datadog-labs/pack" ];
    brews = [
      "mas"
      "dockutil"
      "pre-commit"
      "datadog-labs/pack/pup"
      "herdr"
    ];
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
      "antigravity-cli"

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
