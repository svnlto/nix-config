# Harness Internal Developer Portal (IDP)

## Model: IDP 2.0 is current

IDP 2.0 rebuilds Backstage-based 1.0 natively; 1.0 entities auto-upgrade.

| Area | IDP 1.0 (legacy) | IDP 2.0 (current) |
| --- | --- | --- |
| Entity `apiVersion` | `backstage.io/v1alpha1` | `harness.io/v1` |
| Workflow YAML | `scaffolder.backstage.io/v1beta3`, `kind: Template` | `harness.io/v1`, `kind: Workflow` |
| Scope | `metadata.namespace`, account-wide | Account / Org / Project via `orgIdentifier`, `projectIdentifier` |
| Access control | No entity-level granular RBAC | Harness roles + resource groups (Create, Edit, Read, Delete, Execute) |
| Authoring | YAML in Git | Inline (UI/API) or Remote (Git Experience) |
| Catalog API | Backstage `/idp/api/catalog/...` | Harness Entities API, scope- and RBAC-aware |
| Scorecards, Layouts, Plugins | Account | Still Account scope only |

Doc: <https://developer.harness.io/internal-developer-portal/use-idp/software-catalog/data-model/data-model>

## Software catalog: entity YAML

- Kinds: `Component`, `API`, `Resource`, `System`, `Group` (Team),
  `Workflow`. One entity per file; `identifier` unique per kind.
- Moved to root vs Backstage: `metadata.name` → `identifier`,
  `metadata.title` → `name`, `spec.type` → `type`, `spec.owner` → `owner`.
  Removed: `metadata.namespace`, `spec.system`, `spec.domain`.
- Owner refs: `user:account/<email>`, `group:account/<id>`; case-sensitive.
  A Team owner passes its View/Edit/Delete rights to owned entities.
- Declare relations one way (`dependsOn`, `providesApis`); reverses appear.

```yaml
apiVersion: harness.io/v1
kind: Component
identifier: payments-api
name: Payments API
type: service
owner: group:account/payments_team
orgIdentifier: default
projectIdentifier: payments
spec:
  lifecycle: production
```

Doc: <https://developer.harness.io/internal-developer-portal/use-idp/software-catalog/catalog-yaml>

## Registration and auto-discovery

- Create via UI, Entities API, or `harness_platform_idp_catalog_entity`. Git
  Experience keeps Catalog and Workflow YAML Inline or Remote (two-way sync).
- Integrations (`IDP_INTEGRATIONS` flag: GitHub, Kubernetes, PagerDuty,
  ServiceNow CMDB, Harness CD, others) **Register** or **Merge** entities.
  The Catalog Ingestion API (`/gateway/v1/catalog/custom-properties`) only
  enriches existing entities.

Doc: <https://developer.harness.io/internal-developer-portal/use-idp/software-catalog/create-entity/catalog-discovery/overview>

## Self-service workflows

Frontend `spec.parameters` (JSON-Schema form pages, `ui:field` pickers such
as `HarnessProjectPicker`), backend `spec.steps`, results `spec.output`
(`links`, `text`).

- Actions: `trigger:harness-custom-pipeline` (`inputset` and/or
  `inputSetName`), `trigger:trigger-pipeline-with-webhook` (input set +
  custom trigger), `harness:create-secret`, `harness:delete-secret`,
  `debug:log`.
- `inputset` keys are pipeline runtime variables (or FQNs such as
  `pipeline.variables.x`); values are `${{ parameters.x }}`, valid only in
  `steps`.
- Auth: `apikey: ${{ parameters.token }}` from a `ui:field: HarnessAuthToken`
  property on page one (the user needs pipeline Execute), or
  `apiKeySecret: <secretId>` (the key's owner needs Execute, users do not).
- `showOutputVariables: true` exposes `${{ steps.<id>.output.<var> }}`.
  `url` accepts `${{ workflowContext.accountId }}` (also `host`, `orgId`,
  `projectId`); Git-backed pipelines need `repoName` and `branch` in it.

```yaml
apiVersion: harness.io/v1
kind: Workflow
identifier: create-service
type: service
owner: group:account/platform_team
spec:
  parameters:
    - title: Service details
      required: [service_name]
      properties:
        service_name: { type: string, title: Service name }
  steps:
    - id: trigger
      name: Onboard service
      action: trigger:harness-custom-pipeline
      input:
        url: "<pipeline studio URL>"
        inputset:
          service_name: ${{ parameters.service_name }}
        apiKeySecret: idp_pipeline_key
```

Doc: <https://developer.harness.io/internal-developer-portal/use-idp/self-service-workflows/create-workflow/custom-actions>

## Onboarding via Harness pipelines

The workflow is the form; the pipeline does the work. Stage type **Developer
Portal** (`type: IDP`) has steps `GitClone`, `CookieCutter`, `CreateRepo`,
`DirectPush`, `CreateCatalog`, `RegisterCatalog`, `SlackNotify`,
`CreateResource` (OpenTofu + Harness provider). Custom, Deploy, and
codebase-disabled CI stages also work. No looping strategies in IDP stages.
The `CreateCatalog` doc example still writes `backstage.io/v1alpha1`
content; emit `harness.io/v1` entities instead.

Docs conflict on picker and output keys — check both pages before use:
`OwnerPicker` takes `ui:options.allowedKinds` (workflow YAML page) or
`catalogFilter` (inputs page); the trigger output is
`steps.<id>.output.PipelineUrl` or `.url`.

Doc: <https://developer.harness.io/internal-developer-portal/use-idp/self-service-workflows/create-workflow/harness-pipeline>

## Scorecards and checks

A check is a pass/fail rule over data-source data points (GitHub, Bitbucket,
Harness, PagerDuty, catalog). Basic mode: All Of / Any Of rules. Advanced:
JEXL, such as `catalog.annotationExists."jira/project-key" == true`. Tier
groups map the 0–100 score to bands (Bronze, Silver, Gold).

Doc: <https://developer.harness.io/internal-developer-portal/use-idp/scorecards/create-scorecards/checks>

## Plugins, TechDocs, Backstage

- Plugins: curated Backstage subset plus Harness-native (CI/CD, STO, FME,
  IaCM, CCM, Chaos); `app-config.yaml` + globally unique secret variables;
  Delegate proxy for private networks. No custom backend plugins.
- TechDocs: MkDocs (`mkdocs.yml` + `docs/`) via the
  `backstage.io/techdocs-ref` annotation (`dir:.` or `url:`).
- Versus self-hosted Backstage: Harness runs the core and adds RBAC,
  hierarchy, OPA, audit, and pipeline workflows on isolated infrastructure.

Doc: <https://developer.harness.io/internal-developer-portal/troubleshooting-and-resources/harness-vs-backstage>
