---
name: cc-spex
description: >-
  Operating cc-spex — spec-driven development that pairs GitHub spec-kit
  (the WHAT: constitution, spec, plan, tasks artifacts) with Superpowers
  (the HOW: TDD, git worktrees, review gates) — on a local or team project.
  Use when adopting or running cc-spex or spec-kit, driving a /speckit-* or
  /speckit-spex-* loop (constitution, specify, clarify, plan, tasks,
  implement, ship), installing the specify CLI or the spex plugin, enabling
  spex extensions, or deciding how spec-driven development fits the workflow.
  Triggers: cc-spex, spex, spec-kit, spec-driven development, SDD, /speckit,
  speckit-spex-ship, specify init, spex-gates, spex-worktrees, spex.json,
  constitution.md, .specify/specs. NOT the raw Superpowers brainstorming /
  writing-plans / executing-plans skills used for ordinary feature work
  without spec-kit — those stand alone; this skill is for the
  cc-spex-integrated spec-driven loop and its setup.
license: MIT
metadata:
  version: "1.0.0"
  domain: devops
  triggers: cc-spex, spex, spec-kit, spec-driven development, SDD, speckit, specify CLI, spex-gates, spex-worktrees, ship, constitution
  role: workflow
  scope: process
  related-skills: platform-engineer, copier, writing-adrs
---

# cc-spex: spec-driven development

cc-spex ([rhuss/cc-spex](https://github.com/rhuss/cc-spex), Apache-2.0) is a
Claude Code plugin that fuses two upstream projects:

- **spec-kit** (GitHub) — the WHAT. Artifact-centric, linear: each command
  emits a durable document (constitution, spec, plan, tasks).
- **Superpowers** (Jesse Vincent) — the HOW. Process discipline: TDD, git
  worktrees, verification gates, anti-rationalization.

The boundary is the task list. spec-kit plans `tasks.md`; the implementation
runs under Superpowers discipline. cc-spex wires them together and runs its
quality gates as lifecycle hooks.

## Setup

1. `specify` CLI (needs `uv`; this estate's sanctioned Python tool):

   ```bash
   nix run nixpkgs#uv -- tool install specify-cli --from git+https://github.com/github/spec-kit.git
   ```

   First resolve is slow (git build); cached after. Installs `~/.local/bin/specify`.
2. Init the project. **Must** pass both flags or it silently defaults to
   Copilot with no TTY:

   ```bash
   specify init --here --force --non-interactive --integration claude
   ```

   spec-kit installs its workflow as **project-local skills** under
   `.claude/skills/speckit-*/SKILL.md`, invoked as `/speckit-*` (hyphen, not
   a dot). `.specify/` holds `memory/constitution.md`, `scripts/`, `templates/`.
3. Install the plugin — **prefer project scope** so its hooks stay confined
   to this repo (user scope loads them into every Claude Code session):

   ```bash
   claude plugin marketplace add rhuss/cc-rhuss-marketplace
   claude plugin install spex@cc-rhuss-marketplace
   ```

4. Enable extensions via `/spex:init` (interactive: a 3-question
   `AskUserQuestion` for quality / workflow / permissions). Start minimal —
   `spex-gates` + `spex-worktrees`. `spex-worktrees` needs the spec-kit `git`
   extension (init errors out with a fix if missing). Leave `spex-deep-review`,
   `spex-collab`, `spex-teams`, `spex-detach` off until the core loop is
   understood. Selection persists to `.specify/spex.json`.

## The loop

Run in a live session (the plugin's `UserPromptSubmit` hook injects a
`<spex-context>`; a `PreToolUse` gate enforces skill use):

`/speckit-constitution` → `/speckit-specify` → `/speckit-clarify` (optional)
→ `/speckit-plan` → `/speckit-tasks` → `/speckit-implement`.

Gates fire as hooks: `review-spec` after specify, `review-plan` after tasks,
`review-code` after implement.

## Rules that bite

- **Run `/speckit-implement`.** In cc-spex it IS the Superpowers-coupled TDD
  executor (test tasks before implementation). The "never run
  `/speckit.implement`, Superpowers replaces it" rule applies only to a
  *manual* spec-kit + Superpowers combine, not to cc-spex.
- **`speckit-spex-ship`** (the autonomous one-shot) **requires
  `spex-deep-review`** (a 5-agent review swarm). For the lean loop, drive the
  stages individually rather than enabling deep-review.
- **cc-spex is interactive-first.** Its gated stages run mandatory shell
  hooks (worktree prepare, template resolve) that need live approval.
  Headless `claude -p --permission-mode acceptEdits` stalls at the first hook
  (it auto-approves edits, not Bash); `bypassPermissions` is correctly
  oversight-blocked. For semi-autonomous or CI runs, add a **scoped Bash
  allowlist** for `.specify/scripts/*` and the plugin's worktree script —
  never a blanket bypass. Plain drive-it-yourself is interactive.
- Keep subagents scoped to one task; don't hand them the whole `.specify/`
  tree. Update the spec when behavior changes — drift breaks the audit trail.

## Accor gate mapping (team phase — notes, not wired here)

cc-spex's `review-code` gate is its own. The sanctioned set is SonarQube
Cloud + conftest/Rego + Checkmarx + Wiz + gitleaks, enforced via pre-commit
and the GitLab compliance framework. A team rollout wires `review-code` onto
those rather than adopting cc-spex's deep-review stack, pins cc-spex into the
flake (like the other `cc-*` inputs) instead of `/plugin install`, and folds
the loop into the Software Factory blueprint.

## When not to use

Ordinary feature work with no spec-kit project — use the standalone
Superpowers skills (`brainstorming`, `writing-plans`, `executing-plans`)
directly. This skill is for the cc-spex-integrated loop and its setup.
