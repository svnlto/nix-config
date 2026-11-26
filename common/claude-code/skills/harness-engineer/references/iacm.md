# Harness IaCM

## Model

- Hierarchy: account > org > project > workspace. Pipelines are separate
  entities that run against any workspace in the project.
- Workspace = repo + branch/tag + folder path, provisioner and version,
  connectors, variables, one state file. One workspace per environment.

Doc: <https://developer.harness.io/infrastructure-as-code-management/new-to-iacm/overview>

## Provisioners

| Provisioner | Support |
| --- | --- |
| OpenTofu | All versions (plugin reference says 1.6+) |
| Terraform | MPL versions only, up to 1.5.x; 1.6+ (BSL) unsupported |
| Terragrunt | Workspace level; default Folder Path, per-step Folder Path Override |
| AWS CDK | Separate provisioner with its own steps |
| Ansible | Configuration management: inventories and playbooks |

Doc: <https://developer.harness.io/infrastructure-as-code-management/troubleshooting-and-resources/whats-supported>

## Provision pipeline

```yaml
- stage:
    name: Provision
    identifier: provision
    type: IACM
    spec:
      workspace: <+input>
      platform: { os: Linux, arch: Amd64 }
      runtime: { type: Cloud, spec: {} }
      execution:
        steps:
          - step: { type: IACMTerraformPlugin, name: init, identifier: init, spec: { command: init } }
          - step: { type: IACMTerraformPlugin, name: plan, identifier: plan, spec: { command: plan } }
          - step: { type: IACMTerraformPlugin, name: apply, identifier: apply, spec: { command: apply } }
```

- One step type for OpenTofu and Terraform; `command` is one of `init`,
  `plan`, `apply`, `destroy`, `plan-destroy`, `plan-refresh-only`,
  `apply-refresh-only`, `detect-drift`, `import`, `removed`,
  `migrate-state`, `validate`, `fmt`.
- `plan` succeeds even with changes. Flags come from `PLUGIN_*` env vars
  (`PLUGIN_PLAN_TARGET`, `PLUGIN_PLAN_REPLACE`, `PLUGIN_LOCK`...);
  `TF_CLI_ARGS_plan` is ignored.
- Runtimes: Harness Cloud, Kubernetes, local runner (`type: Docker`).
  Default pipelines per operation are set per project, overridable per
  workspace.

Doc: <https://developer.harness.io/infrastructure-as-code-management/use-iacm/iacm-cli-commands/terraform-plugins>

## Approvals and queueing

- IaCM Approval step between plan and apply shows resource changes, cost
  and OPA results; `spec.autoApprove: true` skips empty plans; 60 min max;
  the build machine keeps running while it waits.
- Queue step serialises runs on one workspace; place it before plan, not
  between plan and apply, or a stale plan can be applied.

Doc: <https://developer.harness.io/infrastructure-as-code-management/platform/iacm-pipelines/operations-overview/approval-step-operations-overview>

## Drift and ephemeral workspaces

- Detect Drift operation (init, plan, detect-drift) fails the run on drift
  and marks resources Drifted in the Resources tab. Schedule via cron
  trigger or workspace/project drift settings.
- `plan-refresh-only` reconciles state without applying config. Ephemeral
  workspaces run the default Destroy pipeline after inactivity.

Doc: <https://developer.harness.io/infrastructure-as-code-management/platform/workspaces/drift-ephemeral-workspaces>

## PR automation and cost

- PR pipeline: choose the Pull Request operation, add a webhook trigger on
  the workspace's Git connector, event Pull Request, optional path filter.
  Plan posts as a PR comment; public repos need `HARNESS_PASSWORD_API`.
- Cost estimation: workspace toggle Cloud Cost Estimation runs Infracost on
  every plan (AWS, Azure, GCP list prices); `INFRACOST_API_KEY` only for
  paid custom pricing. Actual cost comes from the separate CCM integration.

Doc: <https://developer.harness.io/infrastructure-as-code-management/platform/workspaces/cost-estimation>

## OPA policies

| Entity type | Evaluated |
| --- | --- |
| Workspace | On workspace save (`input.workspace.*`) |
| Terraform Plan | After every plan (plan JSON) |
| Terraform State | After plan and after apply (state JSON) |

- Plan and State policy sets run automatically; they do not appear in the
  step policy dropdown. A Custom entity attached to a step gets no plan JSON.

Doc: <https://developer.harness.io/infrastructure-as-code-management/platform/policy-and-governance/opa-workspace>

## Variables and connectors

- Precedence: workspace template > workspace variables > Variable Sets (by
  priority) > HCL defaults.
- Connectors: AWS, GCP, Azure (OIDC needs `ARM_SUBSCRIPTION_ID`), Vault.
- Expressions: `<+workspace.outputs.NAME>`, `<+workspace.identifier>`,
  `<+workspace.gitBranch>`; apply-step outputs via
  `<+pipeline.stages.ID.spec.execution.steps.apply.output.outputVariables.NAME>`.

Doc: <https://developer.harness.io/infrastructure-as-code-management/platform/iacm-connectors-variables/connectors-variables>

## State and registries

- Harness-managed backend by default: no `backend` block, encrypted,
  versioned, RBAC-guarded, locked during plan/apply (other runs fail fast).
- Existing S3, GCS or Azure backends work via `backend` blocks; migrate in
  via CLI, pipeline or API. State rollback rolls forward to a copy.
- Workspace lock (Beta) blocks apply/destroy. Module Registry: Git tags
  become pinnable versions, OPA-governed; Private Provider Registry too.

Doc: <https://developer.harness.io/infrastructure-as-code-management/use-iacm/iac-provisioners/opentofu/state-management>

## IaCM vs CD provisioning steps

| Aspect | IaCM | CD Terraform/Terragrunt steps |
| --- | --- | --- |
| Stage | `type: IACM` | Deploy stage (`TerraformPlan`, `TerraformApply`, Destroy, Rollback; `TerragruntPlan`...) |
| Runs on | CI-style runtime (Cloud, K8s, Docker) | Delegate with Terraform installed |
| State | Harness-managed or own backend | Your backend or Terraform Cloud |
| Extras | Drift, PR comments, cost, OPA on plan, registry | Dynamic infra mapped to infrastructure definitions |

Doc: <https://developer.harness.io/continuous-delivery/use-continuous-delivery/provision-infrastructure/terraform-infra/terraform-provisioning-with-harness>
