---
name: gitlab
description: >-
  Read, search, create, and update GitLab merge requests,
  pipelines, issues, and releases via the glab CLI. Use when
  viewing or creating an MR, checking CI pipeline status,
  reading or filing issues, or managing releases on GitLab.
version: 1.0.0
tags: [gitlab, glab, merge-requests, pipelines, ci, issues]
metadata:
  related-skills: jira
---

# GitLab

Read and write GitLab using the `glab` CLI. No REST API
tokens or browser automation — `glab` reuses its own
authenticated config.

## Prerequisites

1. `glab` installed (via nix devPackages).
2. `glab auth login` completed once by the user. If a command
   reports "not authenticated", stop and ask the user to run
   `! glab auth login` — never run it yourself.
3. Run inside a checkout of the target GitLab repo when
   possible; `glab` resolves the host and project from the git
   remote.

## Instance Resolution

`glab` resolves the target host itself, in order:

1. Git remote of the current repo (primary).
2. `GITLAB_HOST` environment variable (fallback for
   out-of-repo use).
3. `glab` multi-host config in `~/.config/glab-cli/config.yml`.

Never hardcode a host — this repo is public. If host
resolution fails, report it and ask which host/repo to target.

## Invocation

Accepts a command plus arguments. If no command is given,
infer from context or ask. If a command needs an MR, issue,
or pipeline reference and none is given, ask.

## Command Routing

| Command | Reference                      | Load When                          |
| ------- | ------------------------------ | ---------------------------------- |
| mr      | `references/merge-requests.md` | Any merge request operation        |
| ci      | `references/pipelines.md`      | Pipeline/job status, logs, retry   |
| issue   | `references/issues.md`         | Issue read/search/create/update    |
| repo    | `references/repo-releases.md`  | Clone, browse, release, variables  |
| setup   | `references/setup.md`          | Auth or host troubleshooting       |

Drafting an MR description: see `references/templates.md`.

## Safety

`create`, `merge`, `approve`, `close`, and `variable set`
change shared state visible to others. Always show the exact
`glab` command and get explicit user confirmation before
running a state-changing command. Never merge or push
without instruction. No retry loops.

## Error Handling

Report clearly and stop.

| Condition                    | Action                            |
| ---------------------------- | --------------------------------- |
| Not authenticated            | Ask user to run `glab auth login` |
| Host not resolved            | Report; ask which host/repo       |
| Not inside a repo            | Ask for repo, or use `-R host/group/project` |
| MR / issue / pipeline 404    | Report stale or wrong reference   |
| Permission denied            | Report the missing scope/role     |
| `glab` non-zero exit         | Print stderr verbatim, stop       |
| No results (list/search)     | Report empty result set           |
