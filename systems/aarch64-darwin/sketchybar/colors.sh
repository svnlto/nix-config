#!/bin/bash

# Color Palette
export BLACK=0xff1e1e2e
export WHITE=0xffffffff
export WHITE_DIMMED=0x80ffffff
export GREY=0xff6c7086
export TRANSPARENT=0x00000000

# General bar colors (matching native macOS menu bar - transparent with blur)
export BAR_COLOR=$TRANSPARENT # Fully transparent, relies on blur_radius for glass effect
export ITEM_BG_COLOR=$SPACE_BG_COLOR
export ACCENT_COLOR=0xff2cf9ed

# Space colors
export SPACE_BG_COLOR=0x1affffff # 10% white opacity for subtle active indicator

# Fonts (matching native macOS menu bar)
export FONT_FACE="SF Pro Text"
export ICON_FONT="sketchybar-app-font:Regular:14.0"
export LABEL_FONT="$FONT_FACE:Medium:14.0"
export DEFAULT_ICON_FONT="$FONT_FACE:Medium:14.0"
export DEFAULT_LABEL_FONT="$FONT_FACE:Medium:14.0"

# Icons (SF Symbols)
export APPLE=􀣺
export PREFERENCES=􀺽
export ACTIVITY=􀒓
export LOCK=􀒳
