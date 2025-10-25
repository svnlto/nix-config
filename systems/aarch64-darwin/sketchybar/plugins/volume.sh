#!/bin/bash

VOLUME=$(osascript -e "output volume of (get volume settings)")
MUTED=$(osascript -e "output muted of (get volume settings)")

if [[ $MUTED == "true" ]]; then
  ICON="󰖁"
else
  case ${VOLUME} in
    [7-9][0-9]|100) ICON="󰕾"
    ;;
    [4-6][0-9]) ICON="󰖀"
    ;;
    [1-3][0-9]) ICON="󰕿"
    ;;
    *) ICON="󰖁"
  esac
fi

sketchybar --set "$NAME" icon="$ICON"
