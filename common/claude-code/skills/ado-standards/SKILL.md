---
name: Azure DevOps Standards
description: "Azure DevOps pull request workflows and pipeline design standards. Use when creating or reviewing ADO pull requests, writing azure-pipelines.yml, designing build/release pipelines, or setting branch policies."
version: 1.0.0
tags: [azure-devops, ado, pull-requests, pipelines, ci-cd, yaml]
---

# Azure DevOps Standards

## When to Use

- Creating or reviewing Azure DevOps pull requests
- Writing or modifying `azure-pipelines.yml`
- Designing build/release pipeline stages
- Setting branch policies or environment promotion rules

## Core Principles

- **Trunk-based development** with short-lived feature branches and squash merges
- **YAML pipelines only** — no classic editor pipelines for new work
- **Multi-stage pipelines** — separate Validate, Plan, Apply stages
- **Pipeline as code** — `azure-pipelines.yml` lives in the repo, not ADO UI
- **Secrets in ADO Library** — variable groups, never hardcoded in YAML
- **Workload identity federation** over service principal secrets
- **Bash over marketplace tasks** — `script:` steps reduce supply chain risk
- **PR size < 400 lines** — split larger work into stacked PRs
- **Same artifact promoted** — never re-plan per environment
- **Use the repo's PR template** — when creating or updating a PR, detect
  the repo's existing ADO template and fill it in; neither `az repos pr
  create` nor `az repos pr update` auto-applies it (see PR reference for
  locations and the CLI workflow)

## Reference Guide

Load detailed guidance based on context:

| Topic | Reference | Load When |
|-------|-----------|-----------|
| Pull Requests | [references/pull-request-conventions.md](references/pull-request-conventions.md) | Creating a PR (always — for the template workflow), branch strategy, PR requirements, branch policies, code review |
| Pipelines | [references/pipeline-design.md](references/pipeline-design.md) | Pipeline YAML structure, templates, security, naming |
| Artifacts & Promotion | [references/artifacts-and-promotion.md](references/artifacts-and-promotion.md) | Artifact management, environment promotion flow |

## Promotion Flow

```text
PR Build (validate + plan) -> main Build (plan) -> Dev (auto-apply) -> Staging (approval) -> Production (approval)
```

## Common Anti-Patterns

- Hardcoded secrets in YAML or scripts
- Single monolithic pipeline without stages
- `trigger: '*'` — always scope triggers to specific branches/paths
- Skipping PR validation builds ("it works on my machine")
- Long-running pipelines without caching (`Cache@2` task for `.terraform/`)
- Manual infrastructure changes not tracked in pipeline
- Using classic release pipelines alongside YAML (pick one)
- Using marketplace tasks when a simple `script:` step would do
- Running `terraform apply` without a saved plan file
- Creating or updating a PR from the CLI without applying the repo's PR
  template (the web UI auto-fills it; `az repos pr create`/`update` do not)
