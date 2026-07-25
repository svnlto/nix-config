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
