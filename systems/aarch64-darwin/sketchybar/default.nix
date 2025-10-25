{ pkgs, lib, ... }:

{
  # Install sketchybar-app-font if not already present
  home.activation.installSketchybarFont =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      FONT_PATH="$HOME/Library/Fonts/sketchybar-app-font.ttf"
      if [ ! -f "$FONT_PATH" ]; then
        $DRY_RUN_CMD ${pkgs.curl}/bin/curl -L \
          https://github.com/kvndrsslr/sketchybar-app-font/releases/download/v2.0.47/sketchybar-app-font.ttf \
          -o "$FONT_PATH"
        echo "Installed sketchybar-app-font to $FONT_PATH"
      fi
    '';

  # Sketchybar status bar configuration
  home.file.".config/sketchybar/sketchybarrc" = {
    source = ./sketchybarrc;
    executable = true;
  };

  # Colors configuration
  home.file.".config/sketchybar/colors.sh" = {
    source = ./colors.sh;
    executable = true;
  };

  # Item scripts
  home.file.".config/sketchybar/items/apple.sh" = {
    source = ./items/apple.sh;
    executable = true;
  };

  home.file.".config/sketchybar/items/spaces.sh" = {
    source = ./items/spaces.sh;
    executable = true;
  };

  home.file.".config/sketchybar/items/calendar.sh" = {
    source = ./items/calendar.sh;
    executable = true;
  };

  home.file.".config/sketchybar/items/battery.sh" = {
    source = ./items/battery.sh;
    executable = true;
  };

  home.file.".config/sketchybar/items/volume.sh" = {
    source = ./items/volume.sh;
    executable = true;
  };

  # Plugin scripts
  home.file.".config/sketchybar/plugins/volume.sh" = {
    source = ./plugins/volume.sh;
    executable = true;
  };
  home.file.".config/sketchybar/plugins/battery.sh" = {
    source = ./plugins/battery.sh;
    executable = true;
  };

  home.file.".config/sketchybar/plugins/clock.sh" = {
    source = ./plugins/clock.sh;
    executable = true;
  };

  home.file.".config/sketchybar/plugins/space.sh" = {
    source = ./plugins/space.sh;
    executable = true;
  };

  home.file.".config/sketchybar/plugins/space_windows.sh" = {
    source = ./plugins/space_windows.sh;
    executable = true;
  };

  home.file.".config/sketchybar/plugins/icon_map_fn.sh" = {
    source = ./plugins/icon_map_fn.sh;
    executable = true;
  };
}
