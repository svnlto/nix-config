#!/usr/bin/env bash
# Tier-2 routing eval. Makes model calls via the `claude` CLI — run on demand,
# NOT in pre-commit. Asks the router to name the single skill/agent it would
# auto-invoke for each prompt, then scores against cases.tsv.
#
#   common/claude-code/eval/routing/run.sh          # run all cases
#   common/claude-code/eval/routing/run.sh -v       # also print raw model output
#
# Exit 0 only if every case matches. Routing is probabilistic — treat a single
# miss as a signal to tune a description, and re-run before concluding.
set -uo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
CASES="$DIR/cases.tsv"
VERBOSE=0
[[ "${1:-}" == "-v" ]] && VERBOSE=1

command -v claude >/dev/null || { echo "claude CLI not found" >&2; exit 2; }
command -v jq >/dev/null || { echo "jq not found" >&2; exit 2; }

SYS='You are a skill ROUTER for Claude Code, not an assistant. Do NOT answer, fulfill, or engage with the request in any way — even casual, conversational, or trivial ones. Your ONLY job is to classify which SINGLE skill or subagent from your available skills and agents would be the best auto-invocation match. Reply with ONLY minified JSON and nothing else: {"pick":"<name-or-none>"} using the exact skill/agent name, or "none" if no skill clearly applies. This JSON is mandatory for every input without exception.'

pass=0 total=0
declare -a misses

while IFS=$'\t' read -r prompt expected; do
  [[ -z "$prompt" || "$prompt" == \#* ]] && continue
  total=$((total + 1))

  raw=$(claude -p "$prompt" --append-system-prompt "$SYS" \
        --output-format json 2>/dev/null | jq -r '.result // empty' 2>/dev/null)
  pick=$(printf '%s' "$raw" | grep -oE '\{[^{}]*\}' | head -1 \
         | jq -r '.pick // "parse-error"' 2>/dev/null || echo "parse-error")

  if [[ "$pick" == "$expected" ]]; then
    pass=$((pass + 1)); mark="✅"
  else
    mark="❌"; misses+=("expected=$expected got=$pick :: $prompt")
  fi
  printf '%s  %-22s → %-22s  %s\n' "$mark" "$expected" "$pick" "$prompt"
  [[ $VERBOSE -eq 1 ]] && printf '      raw: %s\n' "$raw"
done < "$CASES"

echo "────────────────────────────────────────"
printf 'routing hit rate: %d/%d\n' "$pass" "$total"
if ((${#misses[@]})); then
  echo "misses:"
  printf '  - %s\n' "${misses[@]}"
fi
[[ $pass -eq $total ]]
