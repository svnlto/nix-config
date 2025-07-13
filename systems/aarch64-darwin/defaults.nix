{
  config,
  pkgs,
  username,
  ...
}:

{
  system.defaults = {
    finder.FXPreferredViewStyle = "clmv";
    loginwindow.GuestEnabled = false;

    screencapture.location = "/Users/${username}/Desktop/screenshots";

    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      ApplePressAndHoldEnabled = false;
      KeyRepeat = 2;
      InitialKeyRepeat = 15;
      "com.apple.mouse.tapBehavior" = 1;
      "com.apple.sound.beep.volume" = 0.0;
      "com.apple.sound.beep.feedback" = 0;
    };

    dock = {
      autohide = true;
      show-recents = false;
      launchanim = true;
      orientation = "bottom";
      tilesize = 32;
      magnification = true;
      largesize = 48;
      mru-spaces = false;
      static-only = false;
      wvous-tr-corner = 2; # Top Right - Mission Control
      wvous-bl-corner = 13; # Bottom Left - Lock Screen
    };

    finder = {
      _FXShowPosixPathInTitle = false;
      AppleShowAllFiles = true;
      CreateDesktop = true;
      ShowPathbar = true;
      ShowStatusBar = true;
    };

    trackpad = {
      Clicking = false;
      TrackpadThreeFingerDrag = true;
    };

    WindowManager.EnableStandardClickToShowDesktop = false;
  };
}
