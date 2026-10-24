_:

# Every-host baseline — pulled onto every host incl the morty VM, so keep minimal.
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
