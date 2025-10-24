{ ... }:

{
  # Sketchybar status bar configuration
  home.file.".config/sketchybar/sketchybarrc" = {
    source = ./sketchybarrc;
    executable = true;
  };

  # Plugin scripts
  home.file.".config/sketchybar/plugins/aerospace_workspace.sh" = {
    source = ./plugins/aerospace_workspace.sh;
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
}
