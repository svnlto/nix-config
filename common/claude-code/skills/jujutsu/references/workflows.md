# jj day-to-day workflows

Verified against `jj 0.43.0`. Flag and revset names change across
releases — re-check with `jj <cmd> --help` before trusting this file
against a different version.

## Stack anatomy

`jj log -r 'stack()'` shows the current stack: the working-copy commit
`@`, its mutable ancestors, and their descendants.

```text
$ jj log -r 'stack()'
@  umuywlst me@example.com 2026-07-28 10bc35df
│  (empty) wip
○  uylormqt me@example.com 2026-07-28 3116079f
│  (no description set)
◆  uvqzswtn me@example.com 2026-07-28 main 91e5e7e5
│  init
```

Each line starts with a **change ID** (`umuywlst`, `uylormqt`, ...) and
also shows a **commit ID** (`10bc35df`, ...). This is the single most
useful mental correction coming from git: the change ID is the stable
handle. It stays the same across `jj describe`, `jj rebase`,
`jj squash`, and every other rewrite. The commit ID changes on every
rewrite, exactly like a git SHA does. Refer to work in progress by
change ID (`jj edit umuywlst`, `jj squash --into uylormqt`) and it
keeps working after the commit underneath it changes.

## Extend a stack without moving `@`

`jj new --no-edit <base>` inserts a new empty commit after `<base>`
without checking it out — `@` stays where it was.

```bash
jj new --no-edit uylormqt -m "next step"
```

Useful for queuing up the next piece of a stack while still finishing
the current commit, or for scaffolding several planned commits before
filling any of them in.

## Edit mid-stack

`jj edit <change-id>` moves `@` to an existing commit and lets you
modify it directly. Descendants rebase automatically the moment you
change the parent — there is no separate rebase step and no
`--continue`/`--abort` cycle.

```bash
jj edit uylormqt
# ... make changes, they land in uylormqt directly ...
jj edit umuywlst  # back to the top of the stack
```

Bare `jj new` here does not return you to the top — it creates a new
child of `@` (currently `uylormqt`), a sibling of `umuywlst`, forking
the stack. Use `jj edit <top-change-id>` instead.

Contrast with git: rewriting a commit N deep in a branch there means
`git rebase -i`, marking the target `edit`, amending, then
`git rebase --continue` through every commit above it, with a real
chance of conflicts at each step along the way. In jj the descendants
just get rebased as part of the same operation, conflicts and all,
and you can walk away from a conflicted rebase to fix it later.

## `jj absorb`

`jj absorb` looks at the diff in the working-copy commit and routes
each hunk into whichever mutable ancestor last touched those lines,
instead of dumping everything into a new commit or squashing it all
into one target. There is no git equivalent worth naming — the
closest workaround is manually splitting a diff and squashing pieces
into different commits by hand.

```bash
# fix a typo that spans two commits in the current stack
jj absorb
```

Hunks that cannot be attributed unambiguously stay in the source
revision instead of being guessed at.

## `jj split`

`jj split` opens a diff editor on a revision and splits it into two
commits. By default it splits `@`; pass `-r` to split a commit that is
not the working copy.

```bash
jj split -r uylormqt
```

`-i`/`--interactive` (the default when no path is given) lets you
choose hunks in the editor. `-p`/`--parallel` makes the two resulting
commits siblings instead of parent/child. `-o <rev>` extracts the
selected changes onto a different destination instead of leaving them
in place.

## `jj squash --into`

`jj squash --into <rev>` moves the working-copy diff (or a
`--from`-selected diff) into an arbitrary target revision, not just
the immediate parent.

```bash
jj squash --into uylormqt
```

`--from <rev>` picks the source explicitly instead of defaulting to
`@`, so `jj squash --from A --into B` works between any two revisions
in the stack, in either direction.

## Recovery

`jj undo` reverts the single most recent operation — commit, rebase,
squash, abandon, anything. Run it again to keep walking backward.

For anything further back, use the operation log:

```bash
jj op log
jj op restore <op-id>
```

`jj op restore` resets the whole repo state to how it looked right
after that operation. Before starting something risky (a big rebase,
an experimental absorb, a squash you're not sure about), run
`jj op log` first and note the current op id — that gives `op restore`
a known-good target to come back to, rather than hunting through the
log under pressure after something has already gone wrong.

## Conflicts

jj records conflicts *in* commits instead of stopping the operation
that caused them. A rebase that would conflict in git and demand
`--continue`/`--abort` handling just... finishes in jj, leaving a
conflicted commit (or several) in the stack. This is the biggest model
difference from git, and the one most likely to trigger a reflexive
`git merge --abort` or `git rebase --abort` that does not apply here —
there is nothing mid-operation to abort.

Find conflicted commits with the `conflicts()` revset (renamed from
`conflict()` in v0.33):

```bash
jj log -r 'conflicts()'
```

`conflicted()` reads more naturally but does not exist as of 0.43 —
verify against `jj log -r 'conflicts()'` before trusting either name
on a different version.

Resolve conflicts by editing the conflicted commit directly (`jj edit
<change-id>`, fix the markers, no separate "continue" command needed)
or by re-running whatever produced them after fixing the upstream
cause. The commit stays conflicted, and everything downstream stays
usable, until you resolve it.
