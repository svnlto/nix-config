#!/bin/bash
# shellcheck source=/dev/null

source "$CONFIG_DIR/colors.sh"

volume=(
  update_freq=5
  icon.font="$DEFAULT_ICON_FONT"
  icon.color="$WHITE"
  label.drawing=off
  script="$PLUGIN_DIR/volume.sh"
)

sketchybar --add item volume right \
  --set volume "${volume[@]}" \
  --subscribe volume volume_change
