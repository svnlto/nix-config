# Stacked PRs with jj

Verified against `jj 0.43.0`. Flag and revset names change across
releases — re-check with `jj <cmd> --help` before trusting this file
against a different version.

A stack is a chain of reviewable changes, each depending on the one
below it. jj makes building the stack easy (`jj new`, `jj edit`
mid-stack); the mechanics below are what turn that stack into pull
requests on GitHub or Azure DevOps, and where the two platforms
diverge.

## One bookmark per reviewable change

A git branch and a PR are the same thing conceptually — one ref, one
diff, one review thread. jj's unit of work is the change, not the
branch, so nothing forces a bookmark to exist until you push. Each
change that should get its own PR needs its own bookmark:

```bash
jj bookmark set my-feature-part-1 -r <change-id>
```

Or let jj name it:

```bash
jj git push -c <revset>
```

`-c`/`--change` creates a bookmark for every commit the revset
resolves to, using the `templates.git_push_bookmark` config key —
default `"push-" ++ change_id.short()`, i.e. `push-<change-id>`.
Confirmed on a clean config (`JJ_CONFIG=/dev/null`, so no personal
override could leak in):

```bash
$ jj git push -c 'trunk()..@'
Creating bookmark push-voupnlmtuwky for revision voupnlmtuwky
Creating bookmark push-rnnnutnrzyys for revision rnnnutnrzyys
Changes to push to origin:
  bookmark: push-voupnlmtuwky [add to 88b6b67653c2]
  bookmark: push-rnnnutnrzyys [add to 207bfd1bff32]
```

`templates.git_push_bookmark` is a template, not a fixed string — set
it to prefix the generated name however you like (a username, a
ticket key). Whatever you choose, that prefix is a per-repo or
per-user config choice, not something to hardcode here.

## `--all` pushes bookmarks, not revisions

`jj git push --all` pushes every *bookmark* jj knows about. It does
not discover or push every commit in your stack that lacks one. A
3-commit stack with only the top commit bookmarked pushes exactly one
ref:

```bash
$ jj log -r 'trunk()..@' --no-graph -T 'description'
step 3
step 2
step 1
$ jj bookmark set top -r @
Created 1 bookmarks pointing to ... top | (empty) step 3
$ jj git push --all
Changes to push to origin:
  bookmark: top [add to 2aebccebf784]
$ git branch -a   # on the remote
* main
  top
```

`step 1` and `step 2` never got a ref of their own — no PR can target
them. Give every change in the stack its own bookmark (or push with
`-c` over the whole range) before relying on `--all`.

## The payoff over git

Once each change has a bookmark, `jj edit <change-id>` jumps to any
point in the stack, mid-review, and fixes it in place — descendants
rebase automatically, no separate rebase step. A single
`jj git push` afterward updates every bookmark that moved in one
command. The git equivalent is a manual rebase cascade: check out
each branch in order, rebase it onto its now-changed parent, push,
repeat for every branch above it.

Warn before force-pushing a restacked branch: rewriting a commit that
already has review comments moves those comments off the new diff.
The reviewer's tool may keep them visible against the old lines, or
may not — either way, restacking after review has started is worth
flagging to reviewers, not just pushing silently.

## `git.private-commits`

`git.private-commits` is a revset; commits it matches are refused at
push time. Check it first whenever a push comes back short of what
you expected pushed. Confirmed behavior is stricter than "skips the
one commit" — a single matching commit anywhere in the pushed range
blocks the *entire* push, including commits that would otherwise have
gone through clean:

```bash
$ jj config get git.private-commits
description(glob:'wip:*')
$ jj log -r 'trunk()..@' --no-graph -T 'description'
step 3
wip: step 2 debugging
step 1
$ jj git push -c 'trunk()..@'
Creating bookmark push-mrnqstnrvkpv for revision mrnqstnrvkpv
Creating bookmark push-yynupxqkplzz for revision yynupxqkplzz
Creating bookmark push-wkvxowoppywq for revision wkvxowoppywq
Error: Won't push commit 8ee78332ba36 since it is private
Hint: Rejected commit: yynupxqk 8ee78332 (empty) wip: step 2 debugging
Hint: Configured git.private-commits: 'description(glob:'wip:*')'
```

Nothing in that range reached the remote — not `step 1`, not
`step 3`, only the offending commit named in the error. The bookmarks
were created locally regardless; re-run after fixing or excluding the
matching commit.

## Platform: create, retarget, fix up

Both platforms create a PR the same way — point it at the parent
change's bookmark instead of the trunk. Where they diverge is what
happens after the parent PR merges and its branch is deleted.

| | GitHub | Azure DevOps |
|---|---|---|
| Create | `gh pr create --base <parent> --head <this>` | `az repos pr create --source-branch <this> --target-branch <parent>` |
| Branch deleted after merge | Retargets child PRs to the merged PR's base | **Not confirmed in Azure DevOps docs** — commonly reported behavior is no auto-retarget; verify in your own environment before relying on it |
| Fix-up | none needed | `az repos pr update --id N --target-branch main` |

The `gh`/`az` command syntax above is cited from each CLI's
documented reference, not run here — it would hit real remotes.

GitHub's retarget is documented, and it triggers on branch
**deletion**, not the merge by itself. Per the [Pull Request
Retargeting
changelog](https://github.blog/changelog/2020-05-19-pull-request-retargeting/),
when a head branch is deleted, GitHub finds open PRs whose base is
that branch and rewrites their base to the merged PR's base. Merge a
PR while keeping its branch and nothing retargets.

The ADO side of the table is unsourced, not merely untested: no
Microsoft documentation confirming or denying auto-retarget turned up
after searching Microsoft Learn, the Azure DevOps docs, and Azure
DevOps Developer Community, and it was not tested against a live ADO
instance for this task (`az` was off limits — it would hit a real
remote). The closest thing found was a Developer Community feature
request titled "Retarget pull request when target branch merges" — a
request for the capability, which suggests it does not exist, but the
page could not be read to confirm its status, so treat that as
circumstantial, not a citation. It is the least-certain claim in this
file — read it that way, and verify it in your own organization
before relying on it.

That uncertainty doesn't change the operational advice: retarget
every child PR to its new parent (or to `main`, if it was the top of
the stack) immediately after each merge, on ADO specifically,
regardless of whether the underlying platform behavior is ever
confirmed. It costs nothing if ADO turns out to retarget on its own,
and prevents a stranded PR if it doesn't — if the commonly reported
behavior holds, merging the bottom PR and deleting its branch leaves
the next PR up still targeting a branch that no longer exists,
without erroring, looking like a broken PR rather than a missing
step.

## Detecting which platform you're on

The repo's `pr-review` skill already solves this from the git remote
URL; match its approach rather than inventing a new one:

```bash
REMOTE=$(git remote get-url origin 2>/dev/null)
# github.com → gh
# dev.azure.com or visualstudio.com → az
# neither → pure git diff, no PR platform
```
