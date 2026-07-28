#!/usr/bin/env bash
# Claude Code status line — Catppuccin Mocha palette
# Mirrors Oh My Posh theme (default.omp.json) with matching colors and Nerd Font icons

input=$(cat)

tsv=$(jq -r '[.model.display_name // "",
              .context_window.used_percentage // "",
              .cwd // "",
              .workspace.git_worktree // "",
              .rate_limits.five_hour.used_percentage // "",
              .rate_limits.five_hour.resets_at // "",
              .rate_limits.seven_day.used_percentage // ""] | @tsv' <<<"$input")
readarray -d $'\t' -t f <<<"$tsv"
f[-1]="${f[-1]%$'\n'}"
model="${f[0]}"
used_pct="${f[1]}"
cwd="${f[2]}"
worktree_name="${f[3]}"
five_hour_used_pct="${f[4]}"
five_hour_resets_at="${f[5]}"
seven_day_used_pct="${f[6]}"

# Catppuccin Mocha palette — exact RGB values from default.omp.json
pink=$'\033[38;2;245;194;231m'     # p:pink     #F5C2E7
lavender=$'\033[38;2;180;190;254m' # p:lavender #B4BEFE
green=$'\033[38;2;166;227;161m'    # p:green    #A6E3A1
orange=$'\033[38;2;250;179;135m'   # p:orange   #FAB387
red=$'\033[38;2;243;139;168m'      #            #F38BA8
os=$'\033[38;2;147;153;178m'       # p:os       #9399B2
gray=$'\033[38;2;108;112;134m'     # p:overlay0 #6C7086
reset=$'\033[0m'

# Nerd Font icons — matching default.omp.json segments
icon_branch=$''   # nf-dev-git_branch  git branch_icon / jj bookmark
icon_commit=$''   # nf-oct-git_commit  jj change id
icon_worktree=$'' # nf-fa-folder_open  worktree
icon_modified=$'' # nf-fa-pencil_square git working changes
icon_staged=$''   # nf-fa-check_square git staged changes
icon_chevron=$''  # nf-fa-angle_right  closer segment
icon_clock=$''    # nf-fa-clock_o      time remaining

# Shortened path (OMP path segment, p:pink, agnoster_short max_depth 3)
short_path() {
  local p="$1"
  p="${p/#$HOME/\~}"
  local IFS='/'
  read -ra parts <<<"$p"
  local n=${#parts[@]}
  if [ "$n" -le 3 ]; then
    printf '%s' "$p"
  else
    printf '.../%s/%s' "${parts[$n - 2]}" "${parts[$n - 1]}"
  fi
}
path_part="${pink}$(short_path "$cwd")${reset}"

# Jujutsu segment (OMP jujutsu segment, p:lavender) — wins over git when colocated
jj_root=""
d="$cwd"
while [ -n "$d" ] && [ "$d" != "/" ]; do
  if [ -d "$d/.jj" ]; then
    jj_root="$d"
    break
  fi
  d="${d%/*}"
done

jj_part=""
if [ -n "$jj_root" ] && command -v jj >/dev/null 2>&1; then
  jj_cmd=(jj -R "$jj_root" --ignore-working-copy --no-pager --color never log --no-graph)
  bookmarks_raw=$("${jj_cmd[@]}" -r 'heads(::@ & bookmarks())' \
    -T 'bookmarks.map(|b| b.name()).join("\n")' 2>/dev/null)
  bookmarks=""
  declare -A seen=()
  while IFS= read -r b; do
    [ -z "$b" ] && continue
    [ -n "${seen[$b]:-}" ] && continue
    seen[$b]=1
    bookmarks="${bookmarks}${bookmarks:+ }${b}"
  done <<<"$bookmarks_raw"
  if [ -n "$bookmarks" ]; then
    # closest bookmarks are equidistant from @, so one count suffices for all
    ahead=$("${jj_cmd[@]}" -r "${bookmarks%% *}..@" -T '"."' 2>/dev/null | tr -cd '.')
    label=""
    for bookmark in $bookmarks; do
      label="${label}${label:+ }${bookmark}${ahead:+⇡${#ahead}}"
    done
    jj_part=" ${lavender}${icon_branch} ${label}${reset}"
  else
    change_id=$("${jj_cmd[@]}" -r '@' -T 'change_id.shortest(8)' 2>/dev/null)
    [ -n "$change_id" ] && jj_part=" ${lavender}${icon_commit} ${change_id}${reset}"
  fi
fi

# Git segment (OMP git segment, p:lavender, branch_icon + dirty status)
git_part=""
if [ -z "$jj_root" ] && git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null ||
    git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
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
  printf -v pct_int "%.0f" "$used_pct"
  if [ "$pct_int" -ge 80 ]; then
    ctx_color="$red"
  elif [ "$pct_int" -ge 50 ]; then
    ctx_color="$orange"
  else
    ctx_color="$lavender"
  fi
  ctx_part=" ${ctx_color}ctx ${pct_int}%${reset}"
fi

# 5-hour session quota, with time remaining merged in (only shown for claude.ai subscribers)
usage_part=""
if [ -n "$five_hour_used_pct" ]; then
  printf -v used_int "%.0f" "$five_hour_used_pct"
  remaining=$((100 - used_int))
  if [ "$remaining" -le 20 ]; then
    usage_color="$red"
  elif [ "$remaining" -le 50 ]; then
    usage_color="$orange"
  else
    usage_color="$green"
  fi
  usage_part=" ${usage_color}5h ${used_int}%${reset}"

  if [ -n "$five_hour_resets_at" ]; then
    now=$EPOCHSECONDS
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
      usage_part="${usage_part} ${os}·${reset} ${time_color}${icon_clock} ${time_fmt}${reset}"
    fi
  fi
fi

# 7-day quota, same thresholds as the 5-hour one (resets_at deliberately unused — 2.5 days out isn't actionable)
seven_day_part=""
if [ -n "$seven_day_used_pct" ]; then
  printf -v day_int "%.0f" "$seven_day_used_pct"
  remaining=$((100 - day_int))
  if [ "$remaining" -le 20 ]; then
    day_color="$red"
  elif [ "$remaining" -le 50 ]; then
    day_color="$orange"
  else
    day_color="$green"
  fi
  seven_day_part=" ${day_color}7d ${day_int}%${reset}"
fi

printf '%s%s%s%s %s %s[%s]%s%s%s%s\n' \
  "$path_part" \
  "$wt_part" \
  "$jj_part" \
  "$git_part" \
  "$sep" \
  "$os" "$model" "$reset" \
  "$ctx_part" \
  "$usage_part" \
  "$seven_day_part"
