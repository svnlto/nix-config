---
name: migration-rollout
description: >-
  Use when existing migration tooling has to be rolled out across many
  repositories or projects in batches: planning pilot and batch sizes,
  writing the runbook for a batched multi-repo migration, running a batch,
  or deciding whether to halt after failures. Triggers: roll out to all
  repos, mass migration, batch migration, migration waves, pilot projects,
  multi-repo rollout runbook, halt the rollout. NOT for building or
  changing the migration tooling (`spex-feature`), fixing it when a batch
  fails (`spex-bugfix`), or single-service deploy checklists.
license: MIT
metadata:
  version: "1.0.0"
  domain: devops
  triggers: rollout, mass migration, batch migration, waves, pilot, multi-repo runbook, halt
  role: workflow
  scope: process
  related-skills: cc-spex, spex-feature, spex-bugfix, jira-intake
---

# migration-rollout

Rolling out is operations, not development: no spec, no plan. The tooling
must already exist and be tested.

## Preconditions

Check each; a missing one is built first through `spex-feature`, not
improvised in the runbook:

- A migration script or switch that takes an explicit list of targets.
- A rollback that takes the same list.
- A validation check per target (pipeline green, job ran, metric present).
- The target list, supplied by the user. This skill does not choose targets.

## Runbook

Keep it as a file in the tooling repo (e.g. `rollouts/<name>.md`) so the log
is durable; a tracker story per batch may mirror it.

| Section | Content |
|---|---|
| Scope | Tooling version, target list source, owner |
| Batches | Pilot (smallest, one willing team), then growing batches; size and date per batch |
| Per batch | Exact command with the batch's list, validation check, support contact, owners to notify |
| Changes per target | If the tooling opens an MR per target: who reviews, and where MR links are logged |
| Rollback | Trigger, exact command, who decides |
| Stop rule | Threshold that halts the rollout, e.g. any data loss or more than N failed targets |
| Log | Per batch: date, targets, passed, failed, rolled back, notes |

## Running a batch

1. Show the exact command and target list; run only after the user confirms
   this batch. Approval does not carry over to the next batch.
2. Validate every target and record the results in the log.
3. Stop rule breached: roll back the failed targets, halt, and fix the
   tooling through `spex-bugfix` before the next batch.

## Rules

- Never widen a batch beyond the confirmed list.
- Never patch the tooling inside the runbook; changes go back through
  `spex-feature` or `spex-bugfix`.
