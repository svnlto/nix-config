---
name: cc-spex
description: >-
  Operating cc-spex — spec-driven development that pairs GitHub spec-kit
  (the WHAT: constitution, spec, plan, tasks artifacts) with Superpowers
  (the HOW: TDD, git worktrees, review gates) — on a local or team project.
  Use when running cc-spex or spec-kit, driving a /speckit-* or
  /speckit-spex-* loop (brainstorm, constitution, specify, clarify, plan,
  tasks, implement, finish, evolve, ship), running the bundled bugfix or
  assess workflows, choosing spex extensions, deciding how spec-driven
  development fits the workflow, or when the user explicitly asks to set up
  spec-kit or the spex plugin in a project. Triggers: cc-spex, spex,
  spec-kit, spec-driven development, SDD, /speckit, speckit-spex-ship,
  speckit-spex-brainstorm, speckit-spex-finish, specify workflow run, bugfix
  workflow, specify init, spex-gates, spex-worktrees, spex.json,
  constitution.md, .specify/specs, .specify/bugs. NOT the raw Superpowers
  brainstorming / writing-plans / executing-plans skills used for ordinary
  feature work without spec-kit —
  those stand alone; this skill is for the cc-spex-integrated spec-driven
  loop.
license: MIT
metadata:
  version: "2.1.0"
  domain: devops
  triggers: cc-spex, spex, spec-kit, spec-driven development, SDD, speckit, specify CLI, spex-gates, spex-worktrees, ship, constitution, brainstorm, finish, evolve, bugfix
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

This skill is a reference for operating the loop. Loading it is not a request
to install anything. A project is already set up when `.specify/` exists; work
with it as it is. Read `references/setup.md` only when the user explicitly asks
to set up spec-kit or spex in a project that lacks them.

## The loop

Run in a live session (the plugin's `UserPromptSubmit` hook injects a
`<spex-context>`; a `PreToolUse` gate enforces skill use):

`/speckit-constitution` once per repo, then per feature:

`/speckit-spex-brainstorm` → decision record (ADR/HLD) → `/speckit-specify`
→ `/speckit-clarify` (optional) → `/speckit-plan` → `/speckit-tasks` →
`/speckit-implement` → `/speckit-spex-finish` → merge request.
`/speckit-spex-evolve` reconciles spec and code when they drift.

- **Brainstorm** settles the WHAT and WHY through one-at-a-time questions and
  2–3 approaches, then writes `brainstorm/NN-topic.md`. It never writes code
  or specs.
- **The decision record is the input to specify.** The agreed approach is
  written up as an ADR or HLD first and passed to `/speckit-specify` (the
  spec's `**Input**` line cites it). It is not an output of plan.
- **Gates fire as hooks:** `review-spec` after specify, `review-plan` after
  tasks (not after plan), `review-code` after implement. specify also creates
  the worktree and feature branch first.

Other bundled first-party lanes, each a `specify workflow run <id>`:

| Workflow | Steps | Use for |
|---|---|---|
| `bugfix` | `bug.assess` → review gate → `bug.fix` → `bug.test`, under `.specify/bugs/<slug>/` | A defect in shipped behaviour; needs the `bug` extension. Follow with evolve if the spec was wrong. |
| `assess` | intake → research → define → shape → decide → verdict gate | Discovery or feasibility questions; a go verdict hands off to brainstorm/specify manually |

Neither extension's commands carry the spex worktree or review hooks; register
them in `.specify/extensions.yml` if the gates should apply.

spec-kit's workflow lives in project-local skills under
`.claude/skills/speckit-*/SKILL.md`, invoked as `/speckit-*` (hyphen, not a
dot). `.specify/` holds `memory/constitution.md`, `scripts/`, `templates/`, and
the extension selection in `spex.json`.

## Rules that bite

- **Run `/speckit-implement`.** In cc-spex it IS the Superpowers-coupled TDD
  executor (test tasks before implementation). The "never run
  `/speckit.implement`, Superpowers replaces it" rule applies only to a
  *manual* spec-kit + Superpowers combine, not to cc-spex.
- **GitLab: no `submit`, finish with Keep branch.** `/speckit-spex-submit`
  and the PR path in `/speckit-spex-finish` call only `gh` (`gh pr create`,
  `gh pr merge`). On GitLab, run finish and pick **Keep branch** (verify,
  walkthrough, squash, force-push), then open the MR with `glab mr create`.
  Never pick "Merge to default branch": it fast-forwards `main` locally,
  outside the MR.
- **`speckit-spex-ship`** (the autonomous one-shot) **requires
  `spex-deep-review`** (a 5-agent review swarm). For the lean loop, drive the
  stages individually rather than enabling deep-review.
- **Start with minimal extensions** — `spex-gates` + `spex-worktrees`. Leave
  `spex-deep-review`, `spex-collab`, `spex-teams`, `spex-detach` off until the
  core loop is understood.
- **cc-spex is interactive-first.** Its gated stages run mandatory shell
  hooks (worktree prepare, template resolve) that need live approval.
  Headless `claude -p --permission-mode acceptEdits` stalls at the first hook
  (it auto-approves edits, not Bash); `bypassPermissions` is correctly
  oversight-blocked. For semi-autonomous or CI runs, add a **scoped Bash
  allowlist** for `.specify/scripts/*` and the plugin's worktree script —
  never a blanket bypass.
- Keep subagents scoped to one task; don't hand them the whole `.specify/`
  tree. Update the spec when behavior changes — drift breaks the audit trail.

## Reference

| Topic | File |
|-------|------|
| First-time project setup: `specify init`, enabling the plugin, `/spex:init` | `references/setup.md` |

## When not to use

Ordinary feature work with no spec-kit project — use the standalone
Superpowers skills (`brainstorming`, `writing-plans`, `executing-plans`)
directly.
