#!/usr/bin/env bash
# Claude Code status line — Catppuccin Mocha palette
# Mirrors Oh My Posh theme (default.omp.json) with matching colors and Nerd Font icons

input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // ""')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
cwd=$(echo "$input" | jq -r '.cwd // ""')
worktree_name=$(echo "$input" | jq -r '.workspace.git_worktree // empty')
five_hour_used_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_hour_resets_at=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')

# Catppuccin Mocha palette — exact RGB values from default.omp.json
blue=$'\033[38;2;137;180;250m'     # p:blue     #89B4FA
pink=$'\033[38;2;245;194;231m'     # p:pink     #F5C2E7
lavender=$'\033[38;2;180;190;254m' # p:lavender #B4BEFE
green=$'\033[38;2;166;227;161m'    # p:green    #A6E3A1
orange=$'\033[38;2;250;179;135m'   # p:orange   #FAB387
red=$'\033[38;2;243;139;168m'      #            #F38BA8
os=$'\033[38;2;147;153;178m'       # p:os       #9399B2
gray=$'\033[38;2;108;112;134m'     # p:overlay0 #6C7086
reset=$'\033[0m'

# Nerd Font icons — matching default.omp.json segments
icon_apple=$''    # nf-fa-apple        os segment
icon_branch=$''   # nf-dev-git_branch  git branch_icon
icon_worktree=$'' # nf-fa-folder_open  worktree
icon_modified=$'' # nf-fa-pencil_square git working changes
icon_staged=$''   # nf-fa-check_square git staged changes
icon_chevron=$''  # nf-fa-angle_right  closer segment
icon_tokens=$'󰀋' # nf-md-counter  session token count
icon_clock=$''    # nf-fa-clock_o      time remaining

# OS icon (OMP os segment, p:os)
os_part="${os}${icon_apple}${reset}"

# user@host (OMP session segment, p:blue)
user_host="${blue}$(whoami)@$(hostname -s)${reset}"

# Shortened path (OMP path segment, p:pink, agnoster_short max_depth 3)
short_path() {
  local p="$1"
  p="${p/#$HOME/\~}"
  local IFS='/'
  read -ra parts <<< "$p"
  local n=${#parts[@]}
  if [ "$n" -le 3 ]; then
    printf '%s' "$p"
  else
    printf '.../%s/%s' "${parts[$n-2]}" "${parts[$n-1]}"
  fi
}
path_part="${pink}$(short_path "$cwd")${reset}"

# Git segment (OMP git segment, p:lavender, branch_icon + dirty status)
git_part=""
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
  branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null \
           || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
  if [ -n "$branch" ]; then
    changed=""
    if ! git -C "$cwd" diff --quiet 2>/dev/null; then
      wcount=$(git -C "$cwd" diff --numstat 2>/dev/null | wc -l | tr -d ' ')
      changed=" ${icon_modified} ${wcount}"
    fi
    staged=""
    if ! git -C "$cwd" diff --cached --quiet 2>/dev/null; then
      scount=$(git -C "$cwd" diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
      staged=" ${icon_staged} ${scount}"
    fi
    git_part=" ${lavender}${icon_branch} ${branch}${changed}${staged}${reset}"
  fi
fi

# Worktree segment (gray, shown only when in a linked worktree)
wt_part=""
if [ -n "$worktree_name" ]; then
  wt_part=" ${gray}wt${reset}"
fi

# Separator (OMP closer segment, p:os)
sep="${os}${icon_chevron}${reset}"

# Context usage with color threshold
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

# Session usage percentage (5-hour window)
usage_part=""
if [ -n "$five_hour_used_pct" ]; then
  used_int=$(printf "%.0f" "$five_hour_used_pct")
  remaining=$((100 - used_int))
  if [ "$remaining" -le 20 ]; then
    usage_color="$red"
  elif [ "$remaining" -le 50 ]; then
    usage_color="$orange"
  else
    usage_color="$green"
  fi
  usage_part=" ${usage_color}${icon_tokens} ${used_int}%${reset}"
fi

# Time remaining in 5-hour session window (only shown for claude.ai subscribers)
time_part=""
if [ -n "$five_hour_resets_at" ]; then
  now=$(date +%s)
  secs_left=$((five_hour_resets_at - now))
  if [ "$secs_left" -gt 0 ]; then
    mins_left=$((secs_left / 60))
    if [ "$mins_left" -ge 60 ]; then
      hours=$((mins_left / 60))
      mins=$((mins_left % 60))
      time_fmt=$(printf "%dh%02dm" "$hours" "$mins")
    else
      time_fmt=$(printf "%dm" "$mins_left")
    fi
    # green >60m, orange 20-60m, red <20m
    if [ "$mins_left" -ge 60 ]; then
      time_color="$green"
    elif [ "$mins_left" -ge 20 ]; then
      time_color="$orange"
    else
      time_color="$red"
    fi
    time_part=" ${time_color}${icon_clock} ${time_fmt}${reset}"
  fi
fi

printf '%s %s %s%s%s %s  %s[%s]%s%s%s%s\n' \
  "$os_part" \
  "$user_host" \
  "$path_part" \
  "$wt_part" \
  "$git_part" \
  "$sep" \
  "$os" "$model" "$reset" \
  "$ctx_part" \
  "$usage_part" \
  "$time_part"
