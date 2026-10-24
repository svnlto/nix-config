_:

# rick (personal host) Homebrew. Merges with common.nix (taps/brews/casks are
# concatenated by nix-darwin). No shared-real-mac layer by design.
{
  homebrew = {
    taps = [ "datadog-labs/pack" ];

    brews = [
      "mas"
      "pre-commit"
      "datadog-labs/pack/pup"
      "herdr"
    ];

    casks = [
      # Security & Password Management
      "1password"
      "1password-cli"
      "proton-pass"
      "proton-drive"
      "ledger-wallet"

      # Productivity
      "raycast"
      "setapp"
      "obsidian"
      "marked-app"
      "caskhub"
      "granola"
      "drawio"

      # Communication & Collaboration
      "microsoft-teams"
      "microsoft-outlook"
      "whatsapp"
      "telegram"
      "signal"

      # Development & Terminal
      "orbstack"
      "ghostty"
      "claude" # desktop
      "claude-code"
      "claude-devtools"
      "antigravity-cli"

      # Browsers
      "google-chrome"
      "thebrowsercompany-dia"

      # Media & Entertainment
      "vlc"
      "betterdisplay"
      "spotify"
      "zwift"

      # Networking & Virtualization
      "tailscale-app"
      "winbox"
    ];
  };
}
