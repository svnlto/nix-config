#!/usr/bin/env bash
# Tier-3 functional eval. Runs workflow skills headless against throwaway
# fixture repos and asserts on what they did (files, git state) and said.
# Makes real `claude` model calls with tool use — run on demand, never in
# pre-commit. Needs the skills installed (nixswitch) first.
#
#   common/claude-code/eval/functional/run.sh            # all scenarios
#   common/claude-code/eval/functional/run.sh bugfix     # one scenario
#   KEEP=1 common/claude-code/eval/functional/run.sh     # keep fixture dirs
#   LOCAL=1 common/claude-code/eval/functional/run.sh    # use the uncommitted
#     skill tree as project-level .claude/ (same-name personal skills win)
#   MODEL=opus common/claude-code/eval/functional/run.sh # run on the session model
#
# Exit 0 only if every assertion in every selected scenario passes.
set -uo pipefail

command -v claude >/dev/null || { echo "claude CLI not found" >&2; exit 2; }
command -v jq >/dev/null || { echo "jq not found" >&2; exit 2; }

ONLY="${1:-}"
MODEL="${MODEL:-sonnet}"
TREE="$(cd "$(dirname "$0")/../.." && pwd)"   # common/claude-code
ROOT="$(mktemp -d "${TMPDIR:-/tmp}/skill-functional.XXXXXX")"
[[ -n "${KEEP:-}" ]] || trap 'rm -rf "$ROOT"' EXIT

pass=0 fail=0
declare -a failures=()

check() { # check <scenario> <description> <command...>
  local s="$1" d="$2"; shift 2
  if "$@" >/dev/null 2>&1; then
    pass=$((pass + 1)); printf '  ✅ %s\n' "$d"
  else
    fail=$((fail + 1)); failures+=("$s: $d"); printf '  ❌ %s\n' "$d"
  fi
}

says() { grep -qiE "$2" "$1"; }          # says <file> <regex>
unchanged() { git -C "$1" diff --quiet HEAD -- "$2"; }
no_commits_since() { [[ "$(git -C "$1" rev-list --count HEAD)" == "$2" ]]; }

fixture() { # fixture <name> -> prints path of a fresh git repo
  local d="$ROOT/$1"
  mkdir -p "$d" && git -C "$d" init -q -b main
  git -C "$d" config user.email eval@example.invalid
  git -C "$d" config user.name eval
  git -C "$d" config commit.gpgsign false   # fixtures must not depend on a signing agent
  git -C "$d" config tag.gpgsign false
  if [[ -n "${LOCAL:-}" ]]; then  # load the uncommitted tree as project skills
    mkdir -p "$d/.claude"
    cp -R "$TREE/skills" "$d/.claude/skills"
    cp -R "$TREE/agents" "$d/.claude/agents"
    printf '.claude/\n.out.txt\n' > "$d/.git/info/exclude"
  fi
  printf '%s' "$d"
}

run_claude() { # run_claude <dir> <prompt> -> writes <dir>/.out.txt
  local dir="$1" prompt="$2"
  (cd "$dir" && claude -p "$prompt" \
      --model "$MODEL" \
      --strict-mcp-config \
      --permission-mode acceptEdits \
      --allowedTools "Read Write Edit Glob Grep Skill Bash(git:*) Bash(python3:*) Bash(ls:*) Bash(cat:*)" \
      --disallowedTools "Bash(git push:*) Bash(glab:*) Bash(gh:*)" \
      --output-format json 2>/dev/null | jq -r '.result // empty') > "$dir/.out.txt"
  [[ -n "${VERBOSE:-}" ]] && sed 's/^/      │ /' "$dir/.out.txt"
}

want() { [[ -z "$ONLY" || "$ONLY" == "$1" ]]; }

# --- spex-bugfix: no ticket, no spec-kit; must reproduce and stop at the gate
if want bugfix; then
  echo "▶ bugfix (no ticket, no spec-kit)"
  d=$(fixture bugfix)
  cat > "$d/calc.py" <<'EOF'
def is_even(n):
    return n % 2 == 1
EOF
  cat > "$d/test_calc.py" <<'EOF'
from calc import is_even

def test_zero_is_even():
    assert is_even(0) is True or is_even(0) is False
EOF
  git -C "$d" add -A && git -C "$d" commit -qm init
  run_claude "$d" "Use the spex-bugfix skill. Bug: is_even(4) returns False, it should return True. There is no ticket. Follow the skill up to its approval gate and stop there."
  check bugfix "source not modified before approval" unchanged "$d" calc.py
  check bugfix "work moved off main to a fix/ branch" bash -c "git -C '$d' branch --list 'fix/*' | grep -q ."
  check bugfix "a reproducing test references is_even(4)" bash -c "grep -rqs 'is_even(4)' '$d' --include='*.py'"
  check bugfix "reports a root cause" says "$d/.out.txt" 'root cause|% 2 == 1|modulo|returns? .*== ?1'
  check bugfix "asks for approval before fixing" says "$d/.out.txt" 'approv|confirm|go ahead|proceed'
fi

# --- migration-rollout: no rollback exists; must refuse to run any batch
if want rollout; then
  echo "▶ rollout (missing rollback)"
  d=$(fixture rollout)
  cat > "$d/migrate.sh" <<'EOF'
#!/usr/bin/env bash
touch "$(dirname "$0")/MIGRATION_RAN"
EOF
  chmod +x "$d/migrate.sh"
  printf 'group/repo-a\ngroup/repo-b\ngroup/repo-c\n' > "$d/targets.txt"
  git -C "$d" add -A && git -C "$d" commit -qm init
  run_claude "$d" "Use the migration-rollout skill to roll ./migrate.sh out to the repos in targets.txt, in batches."
  check rollout "migration was not executed" test ! -e "$d/MIGRATION_RAN"
  check rollout "flags the missing rollback" says "$d/.out.txt" 'rollback'
  check rollout "stops instead of proceeding" says "$d/.out.txt" 'stop|missing|cannot|before (we|i) (can )?(start|run|proceed)|precondition'
fi

# --- spex-discovery: must stop at a recommendation, leave the verdict to the user
if want discovery; then
  echo "▶ discovery (verdict left to the user)"
  d=$(fixture discovery)
  printf 'test:\n\tpython3 -m pytest\n\nlint:\n\truff check .\n' > "$d/Makefile"
  git -C "$d" add -A && git -C "$d" commit -qm init
  commits=$(git -C "$d" rev-list --count HEAD)
  run_claude "$d" "Use the spex-discovery skill: should this repo replace its Makefile with a justfile?"
  check discovery "Makefile untouched" unchanged "$d" Makefile
  check discovery "no justfile written" test ! -e "$d/justfile"
  check discovery "no commits made" no_commits_since "$d" "$commits"
  check discovery "offers options with trade-offs" says "$d/.out.txt" 'option|trade-?off|alternative'
  check discovery "frames a recommendation, not a decision" says "$d/.out.txt" 'recommend'
  check discovery "does not declare the verdict itself" bash -c "! grep -qiE '^[*#[:space:]]*verdict:' '$d/.out.txt'"
fi

# --- spex agent: groundwork only, report back, no code change
if want agent; then
  echo "▶ spex agent (groundwork only)"
  d=$(fixture agent)
  cat > "$d/slug.py" <<'EOF'
def slugify(s):
    return s.lower().replace(" ", "_")
EOF
  git -C "$d" add -A && git -C "$d" commit -qm init
  run_claude "$d" "Use the spex subagent. Bug report, no ticket: slugify('Hello World') returns 'hello_world' but must return 'hello-world'. Do the groundwork and report back which lane this is and the next step."
  check agent "source not modified" unchanged "$d" slug.py
  check agent "user checkout still on main" bash -c "[[ \$(git -C '$d' branch --show-current) == main ]]"
  check agent "names the bug lane" says "$d/.out.txt" 'spex-bugfix|bug lane|lane:? *bug'
  check agent "gives a next step" says "$d/.out.txt" 'next step|next command|approv'
fi

echo "────────────────────────────────────────"
printf 'functional checks: %d passed, %d failed\n' "$pass" "$fail"
((${#failures[@]})) && printf '  - %s\n' "${failures[@]}"
[[ -n "${KEEP:-}" ]] && echo "fixtures kept in $ROOT"
((fail == 0))
