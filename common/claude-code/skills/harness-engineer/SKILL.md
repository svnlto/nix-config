---
name: harness-engineer
description: >-
  Harness.io platform engineering. Use when authoring, reviewing, or
  debugging Harness pipeline, stage, step, step-group, or template YAML;
  writing expressions, runtime inputs, input sets, or triggers; setting up
  CI build infrastructure or caching; modelling CD services, environments,
  infrastructure definitions, overrides, or deployment strategies; working
  with Harness GitOps, IaCM workspaces, or IDP catalog entities, scorecards,
  and self-service workflows; configuring connectors, delegates, secrets,
  RBAC, service accounts, Git Experience, or OPA policies; or automating
  Harness through its REST API, CLI, Terraform provider, or MCP server.
  Triggers: Harness, harness.io, Harness pipeline, <+pipeline, <+secrets,
  input set, delegate, connectorRef, templateRef, Harness IDP, kind:
  Workflow, IaCM, Harness GitOps, STO, FME, harness_platform_. NOT for
  vendor-neutral IDP or golden-path strategy (that is `platform-engineer`),
  GitLab CI (that is `gitlab-engineer`), or plain Terraform module work
  outside Harness (that is `terraform-skill`).
metadata:
  version: "1.0.0"
  domain: devops
  triggers: harness, harness.io, harness pipeline, harness template, input set, runtime input, delegate, connector, harness secret, harness rbac, git experience, harness opa, harness ci, harness cd, harness gitops, iacm, harness idp, idp workflow, scorecard, sto, fme, harness api, harness cli, harness terraform provider, harness mcp
  role: specialist
  scope: implementation
  output-format: code
  related-skills: platform-engineer, gitlab-engineer, terraform-skill, secrets-management
---

# Harness Engineer

General Harness.io expertise across the platform and its modules. Harness
renames products, restructures docs, and ships new YAML schemas often, so
training memory is stale by default.

## Core Rules

1. **RTFM — never infer.** Open the doc page before stating a YAML key,
   step `type`, expression, enum value, or feature status. Cite the URL.
   If no page shows it, say so instead of guessing.
1. **Current doc layout.** Pages live at
   `https://developer.harness.io/<module>/...` — **no `/docs/` prefix**
   (old paths 308-redirect or 404). Append `.md` to any page URL for raw
   markdown. Find pages via `https://developer.harness.io/llms.txt` or
   `/sitemap.md`. API reference: `https://apidocs.harness.io/`.
1. **Know the YAML flavour first.** Classic (v0): `pipeline.stages[].stage`
   nesting, `<+...>` expressions, `when` / `failureStrategies`. New
   experience (v1): flat `stages[].steps`, `${{ }}` expressions, `if:` /
   `on_failure:`. Match what the repo already uses; never mix them in one
   file or paste one into the other unchanged.
1. **Scope is part of every reference.** No prefix = project, `org.` =
   org, `account.` = account. Entities are visible at their scope and
   below, never above.
1. **Secrets by reference only.** `<+secrets.getValue("[org.|account.]id")>`
   or an external secret manager path. Log masking is exact-match, so a
   transformed (e.g. base64-decoded) secret leaks.
1. **Reuse through templates and Git Experience**, not copy-paste. Pin a
   `versionLabel` for anything shared.
1. **Live systems are read-only by default.** Never run, abort, approve,
   or reject executions, or change account resources, without an
   explicit instruction.

## Decision Routing

| Topic | Reference |
|-------|-----------|
| Account/org/project scope, connectors, delegates, secrets, RBAC, service accounts, Git Experience, OPA | `references/platform-core.md` |
| Pipeline/stage/step YAML, expressions, runtime inputs, input sets, templates, triggers, failure strategies, looping, approvals | `references/pipelines.md` |
| CI stage, build infrastructure, step types, caching, Build/Test Intelligence | `references/ci.md` |
| CD services, environments, overrides, deployment types, strategies, verification, freeze, GitOps | `references/cd-gitops.md` |
| IaCM workspaces, provisioners, plan/apply pipelines, drift, policies on plans | `references/iacm.md` |
| IDP 2.0 catalog entities, self-service workflows, scorecards, plugins | `references/idp.md` |
| STO, FME, Resilience Testing, CACM, AIDI, Code, Artifact Registry, Database DevOps, SCS | `references/other-modules.md` |
| REST API, CLI, Terraform provider, MCP server, API-triggered runs | `references/automation.md` |

## Stale → Current (correct on sight)

| Stale (do not emit) | Current |
|---------------------|---------|
| `developer.harness.io/docs/...` URLs | `developer.harness.io/<module>/...` |
| FirstGen `${workflow.variables.x}` | `<+pipeline.variables.x>` (v0) or `${{ }}` (v1) |
| IDP `backstage.io/v1alpha1` entity, `metadata.name`, `spec.owner` | `apiVersion: harness.io/v1`, root `identifier`/`name`/`type`/`owner` |
| IDP `scaffolder.backstage.io/v1beta3`, `kind: Template` | `apiVersion: harness.io/v1`, `kind: Workflow` |
| Environment-level service overrides (V1) | Overrides V2 entity, priority Service+Infra > Infra > Service > Environment |
| `RunTests` step for Test Intelligence | `type: Test` with `intelligenceMode: true` |
| GitOps service "Deployment Repository" manifest | Application Set references (`appsetConfigs`) |
| `harness/delegate:latest` image | `yy.mm.verno` or `yy.mm.verno.minimal` tag |
| `.allowedValues()` multi-select | `.selectOneFrom()` / `.selectManyFrom()` |
| `harness/harness-cli` (archived) | `harness/cli`, `harness auth login` |
| Terraform provider `api_key` for platform resources | `platform_api_key` / `HARNESS_PLATFORM_API_KEY` |
| Feature Flags | Feature Management & Experimentation (FME); old = "Feature Flags Classic" |
| Chaos Engineering, CCM, SEI, SSCA | Resilience Testing, CACM, AI DLC Insights, Supply Chain Security |
| IaCM with Terraform 1.6+ | MPL Terraform ≤ 1.5.x only; use OpenTofu |

## Anti-Patterns

| Anti-pattern | Fix |
|--------------|-----|
| Reciting a YAML key, URL, or step type from memory | Open the page (`.md`), cite it |
| `<+trigger.*>` for branch/PR data in pipelines also run manually | `<+codebase.*>` in the CI stage |
| Delegate selectors hardcoded on deploy steps or in templates | Select at infrastructure/environment level |
| Expecting Project Admin to use account-level connectors/secrets | Bind a role at that scope or a child-scope resource group |
| Rego policy outside a policy set, or On Save only | Policy set with On Run as well |
| IaCM Queue step between plan and apply | Queue before plan |
| Several catalog entities in one YAML file | One entity per file |
| Personal PAT in Terraform, CI, or MCP config | Scoped service-account token, read-only where possible |
| MCP server with full toolsets and auto-approve | `HARNESS_READ_ONLY=true`, trimmed `HARNESS_TOOLSETS` |

## Workflow

1. Read the existing Harness YAML, templates, and Terraform; identify the
   YAML flavour and the scope of each referenced entity.
1. Route the task through the table above and open the cited reference.
1. For each doc-backed claim, open the current page (append `.md`) and
   confirm before writing config. Where docs conflict, say so.
1. Author minimal, template-based, scope-correct YAML with secrets by
   reference. Validate in the pipeline studio or via the API where
   possible.
1. Report the exact YAML or commands and the doc URLs relied on.
