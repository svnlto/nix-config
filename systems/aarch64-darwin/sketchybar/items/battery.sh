#!/bin/bash
# shellcheck source=/dev/null

source "$CONFIG_DIR/colors.sh"

battery=(
  update_freq=120
  icon.font="$DEFAULT_ICON_FONT"
  icon.color="$WHITE"
  label.drawing=off
  script="$PLUGIN_DIR/battery.sh"
)

sketchybar --add item battery right \
  --set battery "${battery[@]}" \
  --subscribe battery system_woke power_source_change
