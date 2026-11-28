---
name: spex-feature
description: >-
  Use when building new or changed behaviour, including migration tooling,
  in a spec-kit project (`.specify/` present): starting
  /speckit-spex-brainstorm or /speckit-specify, turning an agreed approach
  or ADR into a spec, driving plan, tasks and implement, finishing a feature
  branch, or reconciling spec drift with evolve. Triggers: spec this
  feature, /speckit-spex-brainstorm, /speckit-specify, /speckit-plan,
  /speckit-tasks, /speckit-implement, /speckit-spex-finish,
  /speckit-spex-evolve, spec drift. NOT in repos without spec-kit (use
  `superpowers:brainstorming`), NOT for defects (`spex-bugfix`), open
  questions (`spex-discovery`) or batch rollouts (`migration-rollout`).
license: MIT
metadata:
  version: "1.0.0"
  domain: devops
  triggers: spec feature, brainstorm, specify, plan, tasks, implement, finish, evolve, spec drift
  role: workflow
  scope: process
  related-skills: cc-spex, jira-intake, writing-adrs, gitlab
---

# spex-feature

**REQUIRED: the `cc-spex` skill** for anatomy, hooks, roles and the GitLab
landing rule.

No `.specify/` in the repo → stop. Use `superpowers:brainstorming`, or
cc-spex `references/setup.md` if the user asks to set spec-kit up. Inside a
spex project, `/speckit-spex-brainstorm` replaces `superpowers:brainstorming`.

## Input

A rough idea, a `jira-intake` brief, pasted ticket text, an existing
brainstorm doc, a `spex-discovery` assessment, or an ADR. With an ADR that
already records the decision, start at specify.

**Do not brainstorm on guessed business answers.** If the brief lists open
business questions that change scope, send them to the product owner and
wait; resume once the ticket is updated.

## The loop

`/speckit-spex-brainstorm` → decision record → `/speckit-specify` →
`/speckit-clarify` (optional) → `/speckit-plan` → `/speckit-tasks` →
`/speckit-implement` → `/speckit-spex-finish` → merge request, with
`/speckit-spex-evolve` when spec and code drift.

| Stage | What happens | Fires automatically |
|---|---|---|
| Brainstorm | One-at-a-time questions, 2–3 approaches, agreement; writes `brainstorm/NN-topic.md`. From a discovery assessment, start at the agreed approach. | Idea-inbox and related-brainstorm check |
| Decision record | An ADR (`writing-adrs`) when the decision is material; consult the architect first if it touches architecture or security. Otherwise specify from the brainstorm doc. | — |
| Specify | Input: the ADR or brainstorm doc plus ticket keys. The spec's `**Input**` line cites the ADR. | Before: worktree + feature branch. After: `review-spec` gate, commit |
| Clarify | Technical leftovers only; a business question goes back to the PO. | Commit |
| Plan | `plan.md`, research, data model, contracts, constitution check | Commit |
| Tasks | Dependency-ordered `tasks.md`, grouped by user story | `review-plan` gate (after tasks), commit |
| Implement | Test tasks before implementation tasks | Before: worktree check. After: `review-code` gate |
| Finish → MR | See the GitLab rule in `cc-spex` | — |

## Rules

- **Run `/speckit-implement`.** In cc-spex it IS the Superpowers-coupled TDD
  executor. The "never run `/speckit.implement`" rule applies only to a
  *manual* spec-kit + Superpowers combine.
- **Specs carry ticket keys** on the user stories they came from, taken from
  the brief; the tracker is never written back and tasks are never synced.
- **Behaviour change after merge?** `/speckit-spex-evolve`: old requirements
  become SUPERSEDED or RETIRED, `tasks.md` stays append-only, gates reset.
- Run `/clear` after `/speckit-tasks`, before `/speckit-implement`, to free
  context.
