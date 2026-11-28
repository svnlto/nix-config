---
name: cc-spex
description: >-
  Use when configuring or troubleshooting cc-spex itself in a spec-kit
  project: choosing or installing spex and spec-kit extensions, debugging a
  hook or gate that did or did not fire, running spex headless or in CI,
  landing a spex branch on GitLab, setting up spec-kit or the spex plugin in
  a repo, or deciding which lane a piece of work belongs to. Triggers:
  cc-spex, spex, spec-kit, SDD, specify CLI, specify init, /spex:init,
  spex.json, extensions.yml, spex-gates, spex-worktrees, constitution.md,
  speckit hooks, which lane. For doing the work, use a lane skill:
  `spex-feature`, `spex-bugfix`, `spex-discovery` or `migration-rollout`.
license: MIT
metadata:
  version: "3.0.0"
  domain: devops
  triggers: cc-spex, spex, spec-kit, SDD, specify CLI, spex-gates, spex-worktrees, extensions, hooks, constitution, lane
  role: workflow
  scope: process
  related-skills: spex-feature, spex-bugfix, spex-discovery, migration-rollout, jira-intake
---

# cc-spex: shared base

cc-spex ([rhuss/cc-spex](https://github.com/rhuss/cc-spex), Apache-2.0) fuses
**spec-kit** (GitHub; the WHAT: constitution, spec, plan, tasks) with
**Superpowers** (Jesse Vincent; the HOW: TDD, worktrees, verification
gates). spec-kit plans `tasks.md`; implementation runs under Superpowers
discipline; cc-spex runs the quality gates as lifecycle hooks.

This skill holds what every lane shares. Loading it is not a request to
install anything: a project is set up when `.specify/` exists.

## Pick the lane

| Work | Skill |
|---|---|
| New or changed behaviour, including building migration tooling | `spex-feature` |
| A defect in shipped behaviour to fix and land as an MR | `spex-bugfix` |
| An open question that must end in a go/no-go verdict | `spex-discovery` |
| Batched rollout of existing tooling across many repos | `migration-rollout` |

Starting from a ticket, any lane may run `jira-intake` for a brief. If the
tracker is unavailable, work from the ticket text the user pastes.

## Who does what

| Role | Owns | Never |
|---|---|---|
| Product owner | Stories, acceptance criteria, priority; answers business questions by editing the ticket; accepts at the demo | Edits the repo; decides the HOW |
| Tech lead | Runs the loop; writes ADRs/HLDs after consulting the architect; owns plan and tasks | Answers a business question for the PO |
| Architect | Advises on and reviews ADRs/HLDs; says when a security review is needed | Writes the team's ADR |
| Team | Implementation, MR review, technical clarify questions | Changes scope without the PO |

## Project anatomy

- `.specify/memory/constitution.md` — rules every plan is checked against.
- `.specify/spex.json` — extension selection; `.specify/extensions.yml` —
  hook registry (`before_*`/`after_*` per command).
- `.claude/skills/speckit-*/SKILL.md` — commands, invoked as `/speckit-*`
  (hyphen). Extension commands follow `/speckit-<extension>-<command>`;
  check `.claude/skills/` for exact names.
- `specs/NNN-slug/` — one folder per feature; `brainstorm/` — brainstorm
  docs and the idea inbox.

## Optional first-party extensions

`bug` and `assess` ship with spec-kit but are not part of spex. Installed
when `.specify/extensions/<name>/` exists. To add one, the extension and its
workflow are separate steps:

```bash
specify extension add bug      # commands: /speckit-bug-*
specify workflow add bugfix    # then: specify workflow run bugfix
```

(`assess` likewise: `specify extension add assess`, `specify workflow add
assess`.) Their commands carry no spex worktree or review hooks unless
registered in `extensions.yml`.

## Rules that bite

- **Start with minimal extensions** — `spex-gates` + `spex-worktrees`. Leave
  `spex-deep-review`, `spex-collab`, `spex-teams`, `spex-detach` off until the
  core loop is understood.
- **GitLab: skip `submit`; finish, then "Keep branch as-is".**
  `/speckit-spex-submit` requires `gh` and opens a GitHub PR. Finish always
  verifies, runs the walkthrough gate, squashes and force-pushes, then offers
  a choice; it uses `gh` only to find and merge an existing PR. On GitLab
  pick **Keep branch as-is**, then open the MR with `glab mr create` (the
  `gitlab` skill has a template). Never pick "Merge to default branch": it
  runs a local `git merge --ff-only` into `main`, outside the MR.
- **cc-spex is interactive-first.** Gated stages run shell hooks (worktree
  prepare, template resolve) that need live approval. Headless
  `claude -p --permission-mode acceptEdits` stalls at the first hook (it
  auto-approves edits, not Bash); bypassing permissions is not the answer.
  For semi-autonomous or CI runs, add a **scoped Bash allowlist** for
  `.specify/scripts/*` and the plugin's worktree script.
- **`speckit-spex-ship`** (the autonomous one-shot) **requires
  `spex-deep-review`** (six review agents). For the lean loop, drive the
  stages individually.
- Keep subagents scoped to one question; don't hand them the whole
  `.specify/` tree. Update the spec when behaviour changes — drift breaks the
  audit trail.

## Reference

| Topic | File |
|-------|------|
| First-time project setup: `specify init`, enabling the plugin, `/spex:init` | `references/setup.md` |

## When not to use

Feature work in a repo without spec-kit: use `superpowers:brainstorming` and
the other Superpowers skills directly. Pure investigation with no fix to
land: `superpowers:systematic-debugging`.
