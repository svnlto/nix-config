# Pipeline Authoring (`.gitlab-ci.yml`)

Doc: <https://docs.gitlab.com/ci/yaml/> — the keyword reference is the
source of truth. Never recall keyword behavior from memory; open this
page. On Dedicated, keyword availability tracks the monthly release, so
check the version note on a keyword before using it.

## Global keywords

| Keyword | Meaning |
|---------|---------|
| `stages` | Ordered stage list; same-stage jobs run in parallel |
| `default` | Fallback for `image`, `retry`, `cache`, `before_script`, etc. |
| `variables` | Pipeline-wide CI/CD variables |
| `workflow:rules` | Decides whether the pipeline is created at all |
| `include` | Pull in other config (forms below) |

## Job keywords

| Keyword | Meaning |
|---------|---------|
| `stage` | Stage the job belongs to (defaults to `test`) |
| `script` / `before_script` / `after_script` | Shell commands; `after_script` runs even on failure/cancel, in a separate shell |
| `rules` | Per-job conditions: `rules:if`, `rules:changes`, `rules:exists` |
| `needs` | DAG — start as soon as named jobs finish, ignoring stage order |
| `dependencies` | Which earlier jobs' artifacts to fetch (empty list = none) |
| `artifacts` | Keep files: `paths`, `expire_in`, `when`, `reports`, `access` |
| `cache` | Reuse files: `key`, `paths`, `policy`, `when`, `fallback_keys` |
| `image` / `services` | Job container + linked service containers |
| `extends` | Inherit from another job or template |
| `environment` | Target deployment environment |
| `when` | `on_success`/`on_failure`/`always`/`manual`/`delayed`/`never` |
| `allow_failure` | Continue pipeline on failure; `allow_failure:exit_codes` |
| `timeout` | Job time limit, overrides project setting |
| `parallel` / `parallel:matrix` | Run multiple instances / matrix of var sets |
| `trigger` | Start a downstream child or multi-project pipeline |
| `interruptible` | Cancellable when a newer pipeline supersedes it |
| `resource_group` | Serialize jobs sharing the group (one at a time) |

## `include` forms

| Form | Use |
|------|-----|
| `include:local` | File in the same repo + branch |
| `include:project` | File from another project on this instance (`file`, `ref`) — legacy sharing, see note |
| `include:remote` | Public HTTP(S) URL |
| `include:template` | GitLab-provided template (e.g. security scanners) |
| `include:component` | A CI/CD component pinned to a version — **preferred reuse** |

For sharing config across repos, prefer **components** over
`include:project`/`include:template`: versioned, typed inputs,
discoverable in the catalog. See `components-catalog.md`. `include:project`
needs the consumer's CI job token allowlisted on the shared project
(Settings > CI/CD > Token Access) when repos are in different top-level
groups.

## Deprecated / discouraged (do not author these)

- Top-level `before_script`, `after_script`, `cache` (and `image`,
  `services`) — move under `default`.
- `artifacts:public` — superseded by `artifacts:access`; cannot coexist.
- `start_in`, `allow_failure`, `needs` have no effect inside
  `workflow:rules`.

## MR vs branch pipelines

Jobs default to branch pipelines. To run in merge request pipelines, add
a `rules:if: $CI_PIPELINE_SOURCE == "merge_request_event"` branch. Watch
for duplicate pipelines (branch + MR) — gate with `workflow:rules`.
