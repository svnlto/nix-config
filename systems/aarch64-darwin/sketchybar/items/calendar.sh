#!/bin/bash
# shellcheck source=/dev/null

source "$CONFIG_DIR/colors.sh"

calendar=(
  update_freq=30
  icon.drawing=off
  label.font="$DEFAULT_LABEL_FONT"
  label.color="$WHITE"
  script="$PLUGIN_DIR/clock.sh"
)

sketchybar --add item calendar right \
  --set calendar "${calendar[@]}"
