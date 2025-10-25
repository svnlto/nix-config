#!/bin/bash

# Only show workspaces assigned to main display (per AeroSpace config)
SPACE_SIDS=(1 2 3 4 5 6 7 8)

for sid in "${SPACE_SIDS[@]}"; do
  space=(
    script="$PLUGIN_DIR/space.sh"
    icon="$sid"
    icon.font="$DEFAULT_ICON_FONT"
    label.font="$ICON_FONT"
    label.padding_right=10
    label.y_offset=-1
    background.color="$ITEM_BG_COLOR"
    background.height=20
    background.corner_radius=4
    background.drawing=off
    click_script="aerospace workspace $sid"
  )

  sketchybar --add item "space.$sid" left \
    --set "space.$sid" "${space[@]}" \
    --subscribe "space.$sid" aerospace_workspace_change
done

# Separator item to trigger window updates for all spaces
space_separator=(
  icon.drawing=off
  label.drawing=off
  background.drawing=off
  script="$PLUGIN_DIR/space_windows.sh"
)

sketchybar --add item space_separator left \
  --set space_separator "${space_separator[@]}" \
  --subscribe space_separator aerospace_workspace_change front_app_switched
