#!/usr/bin/env bash
# Claude Code status line - Catppuccin Mocha palette

input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // ""')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
duration_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // empty')

# ANSI 24-bit color helpers (using $'...' for real escape characters)
lavender=$'\033[38;2;180;190;254m'
orange=$'\033[38;2;250;179;135m'
red=$'\033[38;2;243;139;168m'
muted=$'\033[38;2;147;153;178m'
reset=$'\033[0m'

# Context usage indicator
ctx_part=""
if [ -n "$used_pct" ]; then
  pct_int=$(printf "%.0f" "$used_pct")
  if [ "$pct_int" -ge 80 ]; then
    ctx_color="$red"
  elif [ "$pct_int" -ge 50 ]; then
    ctx_color="$orange"
  else
    ctx_color="$lavender"
  fi
  ctx_part=" ${ctx_color}ctx:${pct_int}%${reset}"
fi

# Session duration (mm:ss or hh:mm:ss)
time_part=""
if [ -n "$duration_ms" ]; then
  total_secs=$((duration_ms / 1000))
  hours=$((total_secs / 3600))
  mins=$(( (total_secs % 3600) / 60 ))
  secs=$((total_secs % 60))
  if [ "$hours" -gt 0 ]; then
    time_part=" ${muted}${hours}h${mins}m${reset}"
  elif [ "$mins" -gt 0 ]; then
    time_part=" ${muted}${mins}m${secs}s${reset}"
  else
    time_part=" ${muted}${secs}s${reset}"
  fi
fi

echo "${muted}[${model}]${reset}${ctx_part}${time_part}"
