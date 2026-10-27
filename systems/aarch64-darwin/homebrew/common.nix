_:

# Shared baseline for every macOS host (rick, studio, future corp). Keep minimal;
# per-host brews/casks live in their own homebrew/<host>.nix.
{
  homebrew = {
    enable = true;
    brews = [
      "dockutil" # dock.nix needs it
    ];
    casks = [
      "font-sf-pro"
      "homebrew-app" # BrewUI — Homebrew's official GUI (needs macOS >= 26)
    ];
    masApps = { };
    onActivation = {
      cleanup = "uninstall";
      upgrade = true;
      autoUpdate = true;
    };
  };
}
