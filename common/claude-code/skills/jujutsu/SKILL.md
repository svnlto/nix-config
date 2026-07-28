---
name: jujutsu
description: >-
  Use before running any state-changing git command (commit, add, stash,
  checkout, branch, rebase, cherry-pick, reset, push, pull) in a repo
  with a `.jj/` directory next to `.git/` — applies even when the user
  names the git command verbatim. Also use before launching a jj TUI
  (lazyjj, jjui), or when treating a git/jj mistake as unrecoverable.
---

# Jujutsu (jj) in colocated repos

## Gate

Before any state-changing git command, check for `.jj/` next to `.git/`
and use the jj equivalent below. This applies hardest when the
ask uses git vocabulary ("commit", "push", "stash"): vocabulary names an
outcome, not a tool.

Reads are exempt: `git log`, `git show`, `git diff`, `git blame`,
`git ls-remote`.

Violating the letter of this rule is violating its spirit: an uncovered
git subcommand, or editing `.git` directly, still forfeits the op-log
and change-id continuity jj gives.

## Translation table

| git | jj |
|---|---|
| `git add` | nothing — auto-snapshot (see `references/colocated-repos.md`) |
| `git commit -m` | `jj commit -m` |
| `git commit --amend` | `jj describe` / `jj squash` |
| `git checkout -b` | `jj new` then `jj bookmark set` |
| `git checkout <branch>` | `jj edit` / `jj new <bookmark>` |
| `git stash` | nothing — `jj new`, return later |
| `git branch -d` | `jj bookmark delete` |
| `git pull` | `jj git fetch` + `jj rebase -o trunk()` |
| `git push` | `jj git push` |
| `git rebase -i` | `jj split` / `jj squash` / `jj absorb` |
| `git cherry-pick` | `jj duplicate -o` |
| `git revert` | `jj revert -r <rev> -o @` |
| `git reset --hard` | `jj abandon` / `jj restore` |
| `git reflog` + reset | `jj op log` + `jj op restore` |

## Rationalizations

| Verbatim excuse | Why it is wrong |
|---|---|
| "the ask used git vocabulary ('commit', 'push')" | Vocabulary is not tool selection. "Commit" names an outcome. |
| "the remote is a plain bare git repo" | Every jj remote is a git remote. `jj git push` exists for exactly this. |
| "git operations in a colocated repo are fully valid and jj will pick up the ref move on its next invocation" | True, and still wrong. Costs the op-log entry, change-id continuity, and `jj undo`. |

## Red flags — STOP

- About to run a mutating git command without checking for `.jj/`
- The user named a git command you are about to run verbatim
- About to launch `lazyjj` or `jjui` — TUIs hang an agent shell
- `git merge --abort` — jj records conflicts *in* commits
- Treating a mistake as unrecoverable — `jj undo`/`jj op restore` exist

Raw git is still correct for read-only inspection and for tools reading
`.git` directly — jj keeps refs and `HEAD` current on every jj command.
See
`references/workflows.md`, `references/stacked-prs.md`, and
`references/colocated-repos.md` for day-to-day flow, stacked changes,
and colocated mechanics.
