# Generating & Updating

Docs: <https://copier.readthedocs.io/en/stable/generating/> and
<https://copier.readthedocs.io/en/stable/updating/>.

## Commands

| Command | Purpose |
|---------|---------|
| `copier copy SRC DST` | Generate a new project (API: `copier.run_copy`). |
| `copier update` | Run inside the destination; apply template changes via three-way merge. |
| `copier recopy DST` | Re-apply the template over the project, keeping answers but ignoring prior history. |

## The answers file

Every generated project carries `.copier-answers.yml` (the
`_answers_file`). Two load-bearing keys plus the saved answers:

```yaml
# Changes here will be overwritten by Copier; NEVER EDIT MANUALLY
_commit: v1.2.0          # exact template ref last rendered from
_src_path: gh:acme/go-service-template   # where the template lives
project_name: Payments API
project_slug: payments-api
```

`copier update` reads `_src_path` and `_commit` from here. Never edit it
by hand; author it via the `.jinja` wiring (see `template-config.md`).

## Versioning requirement

For a clean update the template must be a **git repo with tags**. Copier
compares tags with **PEP 440** and targets the latest stable tag by
default. Tags should be stable releases; an untagged template has no
version to update to.

## What `copier update` does

1. Reads `_src_path` + `_commit` from `.copier-answers.yml`.
1. Picks the target ref (latest tag by default; override with
   `--vcs-ref`).
1. Regenerates at the OLD `_commit` with stored answers → pristine
   baseline.
1. Regenerates at the NEW ref with the same answers.
1. Diffs the two baselines and applies that patch onto the current
   worktree, preserving local edits.
1. Rewrites `.copier-answers.yml` with the new `_commit`.

## Conflict resolution

- `--conflict inline` — **default**; writes git-style conflict markers
  into the file.
- `--conflict rej` — writes a `.rej` file per conflicted file instead.

(Do not assume `.rej` is the default — inline markers are.)

## Key flags

| Flag | Effect |
|------|--------|
| `--vcs-ref REF` | Target a specific ref. `--vcs-ref=HEAD` → latest commit; `--vcs-ref=:current:` → update answers only, not the template. |
| `--defaults` | Reuse previous answers, no prompts. |
| `--data k=v` (`-d`), `--data-file FILE` | Override/add answers. |
| `--pretend` | Dry run. |
| `-a PATH` | Non-standard answers-file path. |
| `--skip-answered` (`-A`) | Only re-ask questions that changed. |

Tasks/migrations/extensions still need `--trust` on update too — see
`tasks-migrations-trust.md`.

## Consuming safely (update runbook)

```bash
cd payments-api
git status                 # must be clean
git stash                  # or commit if dirty — update applies a patch
copier update --trust      # --trust only if the template ships tasks/migrations
git status                 # review merged hunks; resolve conflict markers
git add -A && git commit -m "chore: update to template v2.0.0"
```
