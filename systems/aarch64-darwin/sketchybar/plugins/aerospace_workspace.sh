#!/bin/bash

# Get the focused workspace from AeroSpace
WORKSPACE="$FOCUSED_WORKSPACE"

if [ -z "$WORKSPACE" ]; then
    WORKSPACE=$(aerospace list-workspaces --focused)
fi

sketchybar --set "$NAME" label="$WORKSPACE"
