_:

# Every-host baseline only. Host-specific apps live in personal.nix / work.nix.
# The shared import in default.nix pulls this onto every host (incl. the morty
# VM), so keep it minimal — a Zscaler appliance wants nothing GUI here.
{
  homebrew = {
    enable = true;
    brews = [
      "dockutil" # dock.nix needs it
    ];
    casks = [
      "font-sf-pro"
    ];
    masApps = { };
    onActivation = {
      cleanup = "uninstall";
      upgrade = true;
      autoUpdate = true;
    };
  };
}
