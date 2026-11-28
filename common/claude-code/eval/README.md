# Skill & agent evals

Two tiers guarding the `common/claude-code/skills` and `agents` trees.

## Tier 1 — static lint (`lint-skills.py`)

Deterministic, no model calls. Runs in pre-commit (hook `claude-skills-lint`)
and standalone:

```bash
python3 common/claude-code/eval/lint-skills.py   # or: just lint-skills
```

Checks every skill and agent:

- frontmatter present and terminated
- `name` == directory (skills) / filename stem (agents)
- `description` present and ≤ 1536 chars (the skill-listing truncation cap)
- agent `skills:` bindings resolve to a local skill or a known-external one
  (`KNOWN_EXTERNAL_SKILLS` in the script — currently just `terraform-skill`)

Add new upstream bindings to `KNOWN_EXTERNAL_SKILLS` when an agent preloads a
skill merged from a flake input rather than the local tree.

## Tier 2 — routing eval (`routing/`)

Probabilistic, makes model calls via the `claude` CLI — run on demand, never
in pre-commit:

```bash
common/claude-code/eval/routing/run.sh       # or: just route-eval
common/claude-code/eval/routing/run.sh -v    # also print raw model output
```

`routing/cases.tsv` maps `prompt → expected skill/agent` (or `none`). The runner
asks the model to name the single skill it would auto-invoke, then scores hit
rate. Cases target the trigger collisions tightened in the cleanup
(observability three-way split, k8s vs helm/yaml generators, architecture vs
cloud). Routing is non-deterministic — treat a single miss as a prompt to tune a
`description`, then re-run before concluding.

`FILTER='<regex>'` runs only cases whose expected pick matches. `LOCAL=1` routes
against the uncommitted skill tree, loaded as project-level `.claude/` in a temp
workspace, so drafts can be tested before a switch. Installed personal skills
with the same name still win over the local copy.

The runner pins `MODEL` (default `sonnet`) and runs at low effort with MCP
servers skipped. A description that routes correctly on Sonnet holds on stronger
models, so re-run a miss with `MODEL=opus` before tuning a description. The
summary line prints the run's cost.

## Tier 3 — functional eval (`functional/`)

Probabilistic and the most expensive: runs workflow skills headless with tool
use against throwaway fixture repos, then asserts on files, git state and the
reply. Run on demand:

```bash
common/claude-code/eval/functional/run.sh            # or: just func-eval
common/claude-code/eval/functional/run.sh bugfix     # one scenario
LOCAL=1 KEEP=1 VERBOSE=1 common/claude-code/eval/functional/run.sh
```

`MODEL` (default `sonnet`) selects the model; set `MODEL=opus` to reproduce on
the session model.

Scenarios guard the stop conditions that matter most: `spex-bugfix` stops at
its approval gate without touching source; `migration-rollout` refuses to run
without a rollback; `spex-discovery` leaves the verdict to the user; the `spex`
agent reports without changing code or switching the checkout.
