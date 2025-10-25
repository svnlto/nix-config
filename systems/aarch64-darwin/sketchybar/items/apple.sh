#!/bin/bash
# shellcheck source=/dev/null

source "$CONFIG_DIR/colors.sh"

POPUP_OFF="sketchybar --set apple.logo popup.drawing=off"
POPUP_CLICK_SCRIPT="sketchybar --set \$NAME popup.drawing=toggle"

apple_logo=(
  icon="$APPLE"
  icon.font="SF Pro:Black:16.0"
  icon.color="$WHITE"
  label.drawing=off
  background.padding_right=10
  click_script="$POPUP_CLICK_SCRIPT"
  popup.background.color="$TRANSPARENT"
  popup.background.corner_radius=2
  popup.background.border_width=1
  popup.background.border_color="$WHITE"
  popup.blur_radius=20
)

apple_prefs=(
  icon="$PREFERENCES"
  label="Preferences"
  click_script="open -a 'System Settings'; $POPUP_OFF"
)

apple_activity=(
  icon="$ACTIVITY"
  label="Activity"
  click_script="open -a 'Activity Monitor'; $POPUP_OFF"
)

apple_lock=(
  icon="$LOCK"
  label="Lock Screen"
  click_script="pmset displaysleepnow; $POPUP_OFF"
)

sketchybar --add item apple.logo left \
  --set apple.logo "${apple_logo[@]}" \
  \
  --add item apple.prefs popup.apple.logo \
  --set apple.prefs "${apple_prefs[@]}" \
  \
  --add item apple.activity popup.apple.logo \
  --set apple.activity "${apple_activity[@]}" \
  \
  --add item apple.lock popup.apple.logo \
  --set apple.lock "${apple_lock[@]}"
