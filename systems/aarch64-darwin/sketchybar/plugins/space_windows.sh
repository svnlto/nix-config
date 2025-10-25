#!/bin/bash

# Update all workspace window icons
update_workspace_windows() {
  # Get all workspaces (1-8)
  for workspace in {1..8}; do
    # Get all apps in this workspace
    apps=$(aerospace list-windows --workspace "$workspace" --format '%{app-name}' 2>/dev/null | sort -u)

    icon_strip=""
    if [ -n "$apps" ]; then
      while IFS= read -r app; do
        if [ -n "$app" ]; then
          icon_strip+=" $("$CONFIG_DIR"/plugins/icon_map_fn.sh "$app")"
        fi
      done <<<"$apps"
    fi

    # Set empty icon if no apps
    if [ -z "$icon_strip" ]; then
      icon_strip=" -"
    fi

    sketchybar --set "space.$workspace" label="$icon_strip"
  done
}

# Handle different events
if [ "$SENDER" = "aerospace_workspace_change" ] || [ "$SENDER" = "front_app_switched" ] || [ "$SENDER" = "space_windows_change" ]; then
  update_workspace_windows
fi
