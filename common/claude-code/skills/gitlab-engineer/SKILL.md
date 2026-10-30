---
name: gitlab-engineer
description: >-
  Authoring and engineering GitLab CI/CD on a GitLab Dedicated (Ultimate)
  instance. Use when writing or reviewing a .gitlab-ci.yml, designing
  pipelines, building reusable CI/CD components or catalog entries,
  enabling security scanning (SAST/DAST/secret/dependency/container),
  wiring pipeline secrets, or configuring hosted runners and Dedicated
  constraints. Triggers: .gitlab-ci.yml, GitLab pipeline, CI/CD component,
  CI/CD catalog, include:component, SAST, secret detection, hosted runner,
  GitLab Dedicated, Switchboard, Secrets Manager. NOT for operating MRs,
  issues, or pipeline status via the glab CLI — that is the `gitlab` skill.
metadata:
  version: "1.0.0"
  domain: devops
  triggers: gitlab ci, .gitlab-ci.yml, pipeline authoring, ci/cd component, ci/cd catalog, include component, gitlab dedicated, switchboard, hosted runner, sast, dast, secret detection, dependency scanning, container scanning, gitlab secrets manager, security scanning, merge request pipeline, rules, needs, workflow rules
  role: specialist
  scope: implementation
  output-format: code
  related-skills: gitlab, secrets-management, devsecops-expert
---

# GitLab Engineer

For a GitLab Dedicated (Ultimate) instance. Authoring and engineering
CI/CD — not operating GitLab through `glab` (that is the `gitlab` skill).

## Core Rules

1. **RTFM — never infer.** Open the doc page before stating a keyword,
   include path, feature status, or tier. GitLab moves fast and training
   memory is stale. Cite the path you used.
1. **Current doc base is `https://docs.gitlab.com/<path>`** —
   extensionless, **no `/ee/` segment and no `.html` suffix**. Old
   `/ee/...html` URLs are a memory artifact; do not emit them.
1. **Version-aware.** Dedicated ships monthly and cannot be pinned, so a
   keyword/feature may or may not be live yet. Check its version note.
1. **Components first.** Share config via CI/CD components pinned to a
   version, not copy-pasted `include:template`/`include:project`.
1. **Dedicated is the context.** Hosted runners, networking, and
   maintenance work differently than self-managed/gitlab.com — see
   `dedicated.md` before assuming a capability exists.

## Decision Routing

| Topic | Reference |
|-------|-----------|
| `.gitlab-ci.yml` keywords, rules/needs/workflow, include forms, deprecated keywords | `references/pipeline-authoring.md` |
| Reusable components, inputs, versioning, catalog publishing | `references/components-catalog.md` |
| SAST/DAST/secret/dependency/container scanning enablement + tiers | `references/security-scanning.md` |
| Pipeline secrets — CI variables, Secrets Manager, external secrets | `references/secrets.md` |
| Dedicated constraints, Switchboard, hosted runners, networking | `references/dedicated.md` |

## Stale → Current (correct on sight)

| Stale (do not emit) | Current |
|---------------------|---------|
| `docs.gitlab.com/ee/ci/...` | `docs.gitlab.com/ci/...` |
| `...gitlab.com/ee/user/...` | `...gitlab.com/user/...` |
| any `....html` doc URL | extensionless path |
| sharing via `include:project`/`template` as the default | `include:component@<version>` |
| "Dedicated has no runners / bring your own" (as a certainty) | hosted runners exist (Ultimate, Switchboard, billed via Credits) |
| hardcoded Dedicated hostname in a component | `$CI_SERVER_FQDN` |

## Anti-Patterns

| Anti-pattern | Fix |
|--------------|-----|
| Reciting a keyword/URL/feature from memory | Open the doc; cite the path |
| `include:project` copy-paste across repos | A versioned component |
| `ref: main` on a shared include in production | Pin a tag or SHA |
| No `image` on a hosted-runner job | Set `image` (default is `ruby:3.1`) |
| Top-level `before_script`/`cache`/`image` | Move under `default` |
| Hardcoding a secret or echoing it | Secrets Manager / external secrets |
| Assuming a feature is live on Dedicated | Check its version vs the monthly release |

## Workflow

1. Read the repo's existing `.gitlab-ci.yml`, stages, and any components
   it already includes; match conventions.
1. Route the task through the table above and open the cited reference.
1. For any doc-backed claim, open the current page and confirm before
   writing config.
1. Author minimal, pinned, component-based config. Validate in the
   pipeline editor (**Validate pipeline**) where possible.
1. Report the exact config and the doc paths you relied on.
