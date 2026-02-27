#!/usr/bin/env bash
# Claude Code status line - mirrors Oh My Posh theme (Catppuccin Mocha palette)
# Colors: blue=#89B4FA, pink=#F5C2E7, lavender=#B4BEFE, orange=#FAB387, os=#9399B2

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Shorten path: replace $HOME with ~, then show up to last 3 components (agnoster_short style)
home_dir="$HOME"
short_path="${cwd/#$home_dir/\~}"
IFS='/' read -ra parts <<< "$short_path"
part_count=${#parts[@]}
if [ "$part_count" -gt 3 ]; then
  short_path=".../${parts[$((part_count-2))]}/${parts[$((part_count-1))]}"
fi

# ANSI 24-bit color helpers (using $'...' for real escape characters)
blue=$'\033[38;2;137;180;250m'
pink=$'\033[38;2;245;194;231m'
lavender=$'\033[38;2;180;190;254m'
orange=$'\033[38;2;250;179;135m'
red=$'\033[38;2;243;139;168m'
muted=$'\033[38;2;147;153;178m'
reset=$'\033[0m'

# Build status line
user_host="$(whoami)@$(hostname -s)"

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

echo "${blue}${user_host}${reset} ${pink}${short_path}${reset} ${muted}[${model}]${reset}${ctx_part}"
