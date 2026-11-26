# Harness Pipelines

## Structure and stage types

```yaml
pipeline:
  name: smoke
  identifier: smoke
  orgIdentifier: default
  projectIdentifier: my_project
  stages:
    - stage:
        name: hello
        identifier: hello
        type: Custom
        spec:
          execution:
            steps:
              - step:
                  type: ShellScript
                  name: echo
                  identifier: echo
                  spec:
                    shell: Bash
                    source:
                      type: Inline
                      spec:
                        script: echo <+pipeline.name>
                  timeout: 10m
```

| UI stage | YAML `type` | Notes |
| --- | --- | --- |
| Deploy | `Deployment` | service + environment + infrastructure |
| Build | `CI` | codebase and build infra; `<+codebase.*>` resolves only here |
| Approval | `Approval` | Harness, Jira, ServiceNow, Custom approval steps |
| Custom | `Custom` | any steps, optional env/infra, no service, no rollback |
| Pipeline | `Pipeline` | chaining: `spec.org`, `spec.project`, `spec.pipeline`, `spec.inputs` |

- Classic (v0) schema shown; the New experience v1 schema is flat with
  `if:` / `on_failure:`. More stages: Feature Flag, Infrastructure, Dynamic.
- `- parallel:` wraps stages or steps; DAG pipelines use per-stage
  `dependsOn: [ids]`. `- stepGroup: {name, identifier, steps}` shares
  conditions, failure strategy, and looping.

Doc: <https://developer.harness.io/harness-platform/use-harness-platform/pipelines/add-a-stage>

## Expressions, runtime inputs, input sets

- `<+...>` is evaluated by JEXL at runtime. The FQN from `pipeline.` always
  works; relative: `<+stage.variables.v>`, `<+execution.steps.ID...>`.
- Common: `<+pipeline.executionId|sequenceId|triggerType>`,
  `<+pipeline.variables.v>`, `<+pipeline.stages.S.variables.v>`,
  `<+pipeline.stages.S.spec.execution.steps.T.output.outputVariables.V>`.
- `<+trigger.branch|commitSha|prNumber|payload.x|header['X-Y']>` is null on
  manual runs; `<+codebase.branch|commitSha|prNumber>` covers both.
- Wrap compounds whole: `<+<+stage.variables.env> == "prod">`; ternary
  without spaces; hyphenated keys need `["x-auth"]` or `.get("my-var")`.
  Undefined variables fail the run; never reference later or own steps.
- `<+input>` modifiers: `.default(v)`, `.allowedValues(a,b)`,
  `.selectOneFrom(a,b)`, `.selectManyFrom(a,b)`, `.executionInput()`
  (mid-run prompt; on timeout use failure type *Execution-time Inputs
  Timeout Errors* → *Proceed with Default Values*).
- `inputSet:` holds a `pipeline:` value subtree; `overlayInputSet:` lists
  `inputSetReferences` (later wins). Triggers: `inputSetRefs` or `inputYaml`.

Doc: <https://developer.harness.io/harness-platform/use-harness-platform/variables-and-expressions/harness-variables>

## Templates

- Types: Step, Step Group, Stage, Pipeline, Deployment, Monitored Service,
  Secrets Manager, Artifact Source. Reference with `template: {templateRef,
  versionLabel, templateInputs}`; prefix `org.`/`account.` for scope.
- Edit a version in place only if its inputs are unchanged; otherwise save
  a new version. *Always use Stable* follows promotions; a pinned
  `versionLabel` does not. Reconcile callers after input changes.
- Caller-editable via `allowedOverrides`: `ConditionalExecution`,
  `LoopingStrategy`, `FailureStrategy`, `DelegateSelectors`, and more.

Doc: <https://developer.harness.io/harness-platform/use-harness-platform/templates/template>

## Triggers

- Types: **Webhook** (GitHub, GitLab, Bitbucket, Azure Repos, Harness,
  Custom), **Artifact**, **Manifest** (Helm chart), **Scheduled** (cron).
- Webhook: `source.type: Webhook` → `spec.type: Github` → `spec.spec.type:
  Push`; filters `payloadConditions`, `headerConditions`, `jexlCondition`;
  `autoAbortPreviousExecutions`. RBAC does not gate webhook events.
- Custom: POST `.../webhook/custom/{token}/v3?...` with `X-Api-Key`;
  enforce via *Mandate Authorization for Custom Webhook Triggers*.
- Cron: `source.type: Scheduled`, `spec.type: Cron`, `expression`,
  `type: UNIX` or Quartz; UTC unless a FF enables `timezone`. Artifact
  triggers: `<+trigger.artifact.build>`.

Doc: <https://developer.harness.io/harness-platform/use-harness-platform/triggers/triggers-reference>

## Failure strategies, conditions, looping

- `failureStrategies: [{onFailure: {errors: [AllErrors], action: {type:
  X}}}]` on step, step group, or stage (step wins). YAML actions:
  `StageRollback`, `PipelineRollback`, `Retry` (`retryCount`,
  `retryIntervals`, `onRetryFailure.action`), `ManualIntervention`,
  `Ignore`, `Abort`. UI adds Mark as Success/Failure, step-group retry.
- `when`: stages use `pipelineStatus`, steps and step groups use
  `stageStatus` (`Success`, `Failure`, `All`), plus optional `condition`.
- A rolled-back stage is not "failed": a later `Failure`-gated stage skips.
- `strategy:` takes one of `matrix` (tag lists, `exclude`, `nodeName`),
  `repeat` (`times` or `items`), or `parallelism: N`.
- `maxConcurrency` and `onFailure: ignore|abort`: matrix and repeat only;
  `continueOnFailure` is invalid. Read `<+matrix.tag>`, `<+repeat.item>`.

Doc: <https://developer.harness.io/harness-platform/use-harness-platform/pipelines/step-skip-condition-settings>
Doc: <https://developer.harness.io/harness-platform/use-harness-platform/pipelines/looping-strategies/looping-strategies-matrix-repeat-and-parallelism>

## Approvals and flow control

- `HarnessApproval`: `approvers.userGroups`, `minimumCount`,
  `disallowPipelineExecutor`, `approverInputs`. Jira/ServiceNow approvals
  poll a ticket by conditions or JEXL (`<+issue.Status> == "Done"`);
  `CustomApproval` polls a script. Rejection: *Approval Rejection* error.
- Barrier: pipeline `flowControl.barriers[].identifier`; step `type:
  Barrier`, `spec.barrierRef`. Parallel Deploy/Custom stages or step
  groups, same pipeline only; give rollback its own barrier.
- Resource constraints: automatic per service + env + connector + infra,
  account-wide; opt out with `allowSimultaneousDeployments`.
- Queue: `type: Queue`, `spec.key`, `spec.scope: Pipeline|Stage`; keys are
  account-wide and serialize across pipelines and projects.

Doc: <https://developer.harness.io/continuous-delivery/use-continuous-delivery/manage-deployments/controlling-deployments-with-barriers-resource-constraints-and-queue-steps>
