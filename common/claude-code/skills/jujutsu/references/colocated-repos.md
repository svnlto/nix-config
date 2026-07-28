# Colocated repos: jj + git mechanics

A colocated repo has both `.jj/` and `.git/` at its root (`jj git init
--colocate`, or `jj git init` inside an existing git checkout). jj
manages history; the `.git/` directory is kept in sync as a
side effect on every jj command. This file covers the mechanics that
surprise people arriving from plain git.

## jj DOES write to git's index

The common assumption — "jj doesn't touch git's staging area, so I
still need `git add`" — is wrong, but so is the naive fix. In a
colocated repo, jj snapshots the working copy into a new commit at
the *start* of every jj command, including read-only ones like `jj
status` or `jj log`. What that snapshot does to git's index depends
on the file:

- **New files** land as git intent-to-add entries (the same mechanism
  as `git add -N`): the index gets an entry pointing at the empty
  blob, not a staged copy of the file's bytes.
- **Modified tracked files** get no index update at all — the index
  entry is left pointing at the same blob it had at `HEAD`, unchanged.

Either way, the index never carries real staged content that differs
from `HEAD`.

Confirmed empirically on 0.43.0:

```bash
cd "$(mktemp -d)" && git init -q -b main . && echo a > a.txt \
  && git add a.txt \
  && git -c commit.gpgsign=false -c user.name=T -c user.email=t@e.st \
       commit -qm init \
  && jj git init --colocate
echo new > n.txt
git ls-files | grep -c n.txt    # 0 — no jj command has run yet
jj status >/dev/null
git ls-files | grep -c n.txt    # 1 — jj snapshotted the path
git ls-files -s n.txt           # blob is e69de29b... — the empty blob
git diff --cached -- n.txt      # empty — no content staged
git diff -- n.txt               # full contents, as an unstaged add

# now modify a.txt, an already-tracked, already-committed file
echo modified >> a.txt
jj status >/dev/null
git ls-tree HEAD a.txt          # 4b48deed... — the committed blob
git ls-files -s a.txt           # 4b48deed... — same blob, unchanged
git diff --cached -- a.txt      # empty — old content still, not new
git diff -- a.txt               # the real edit, unstaged
```

Consequence: `git add` is unnecessary for anything that only needs to
see the **path** — `git ls-files`, IDE file trees, tools that check
"is this tracked." The auto-snapshot does not produce staged
**content**, though: `git diff --cached`, and by extension
`pre-commit run` (see below), stay blind to both new and modified
files, because neither case ever gets real staged content: new files
get an intent-to-add path with an empty blob, modified files keep
their old committed blob untouched. The only window where a new file's path is
invisible to git-index-reading tools at all is between creating the
file and running the next jj command; run any jj command (`jj status`
is the cheapest) to close it.

## No git hooks fire

jj does not invoke git hooks (`pre-commit`, `post-commit`,
`pre-push`, etc.) on its own operations, by design. Confirmed
empirically: a `.git/hooks/pre-commit` script that echoes and exits
non-zero does not fire, and does not block, on `jj commit`.

This is deliberate, not a bug: jj re-snapshots the working copy on
essentially every invocation, so a hook wired to fire on every commit
would run continuously rather than at meaningful checkpoints. If a
hook genuinely must run on push, look at `jj-pre-push`, a third-party
tool built specifically to bridge git's pre-push hook into a jj
workflow — it is not bundled with jj itself.

## `pre-commit run` alone is a no-op

The `pre-commit` tool's default invocation looks at staged **content**
to decide what changed. Neither new nor modified files ever get real
staged content under jj (see above) — new files are intent-to-add
with an empty blob, modified files keep their old `HEAD` blob — so
pre-commit sees nothing to check and skips, whether you just created
the file or just edited one that's been tracked for months. It even
warns about the new-file case:

```text
$ pre-commit run
[WARNING] Unstaged intent-to-add files detected.
SHOUT................................................(no files to check)Skipped
$ pre-commit run --all-files
SHOUT....................................................................Passed
```

Run pre-commit with `--all-files` (`-a`) in a jj repo instead of
relying on the default staged-content selection:

```bash
pre-commit run --all-files
```

## Detached HEAD is normal

jj parks git's `HEAD` at the working copy's parent commit rather than
at a branch tip. Confirmed empirically: after `jj new` on a repo that
started on `main`, `git symbolic-ref HEAD` fails (no branch to
resolve) and `git status` reports HEAD as not on any branch — the
exact wording varies by git version, but the state is the same:
detached, not on a bookmark. This is how jj represents "the working
copy is its own commit that hasn't been given a bookmark yet" in
git's model — do not run `git checkout main` or `git switch` to "fix"
it. Bookmarks (jj's equivalent of branches) are moved explicitly with
`jj bookmark set`; git's `HEAD` is just a side channel jj keeps
updated for git-native tools to read.

## Check `signing.behavior`

`jj config list signing` shows the active signing setup, e.g.:

```text
signing.backend = "ssh"
signing.behavior = "drop"
signing.key = "ssh-ed25519 AAAA..."
```

`signing.behavior` controls what happens to a commit's signature when
it's rewritten (rebased, edited, squashed):

- `drop` — never auto-sign; strip any prior signature on rewrite.
- `keep` — keep a prior signature if the rewrite didn't change the
  author.
- `own` — sign every commit authored by the current user as it's
  created or rewritten.

With `drop`, expect mid-stack commits to show up unsigned after a
rebase even if they were signed before — that's the configured
behavior, not a failure. A common pairing is `signing.behavior =
"drop"` with `git.sign-on-push = true`, which signs all mutable
unsigned commits in a single batch immediately before `jj git push`
instead of signing continuously during everyday edits. Check both
settings before assuming unsigned intermediate commits are a problem.
