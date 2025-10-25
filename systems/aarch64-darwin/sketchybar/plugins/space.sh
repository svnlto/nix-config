#!/bin/bash
# shellcheck source=/dev/null

source "$CONFIG_DIR/colors.sh"

# Get the focused workspace from AeroSpace
if [ "$SENDER" != "aerospace_workspace_change" ]; then
  FOCUSED_WORKSPACE=$(aerospace list-workspaces --focused)
fi

# Extract space number from item name (space.1 -> 1)
SPACE_ID=${NAME#space.}

# Check if this space is the focused workspace
if [ "$SPACE_ID" = "$FOCUSED_WORKSPACE" ]; then
  sketchybar --set "$NAME" \
    background.drawing=on \
    background.color="$SPACE_BG_COLOR" \
    label.color="$WHITE" \
    icon.color="$WHITE"
else
  sketchybar --set "$NAME" \
    background.drawing=off \
    label.color="$WHITE" \
    icon.color="$WHITE"
fi
