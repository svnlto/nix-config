# Harness CD and GitOps

## Entity model

| Entity | Answers | Key contents |
| --- | --- | --- |
| Service | What | `serviceDefinition.type`, manifests, artifacts (`primary` + sidecars), config files, variables |
| Environment | Where (logical) | `type: Production` or `PreProduction`, variables |
| Infrastructure definition | Where (concrete) | `environmentRef`, `deploymentType`, `type` (e.g. `KubernetesDirect`), connector, namespace |
| Environment group | Many wheres | `envIdentifiers`, cross-scope via `org.`/`account.` prefix; doc marks Beta |

- Scoped to account, org or project. Use `<+artifacts.primary.image>` in
  values YAML or Kustomize patches; raw K8s manifests do not resolve it.

Doc: <https://developer.harness.io/continuous-delivery/use-continuous-delivery/cd-building-blocks/services/services-overview>

## Deploy stage

```yaml
- stage:
    name: Deploy
    identifier: Deploy
    type: Deployment
    spec:
      deploymentType: Kubernetes
      service:
        serviceRef: my_service
      environment:
        environmentRef: my_environment
        deployToAll: false
        infrastructureDefinitions:
          - identifier: my_k8s_infrastructure
      execution:
        steps:
          - step:
              type: K8sRollingDeploy
              name: Rolling Deployment
              identifier: rolling
              timeout: 10m
              spec: { skipDryRun: false }
        rollbackSteps: []
```

Doc: <https://developer.harness.io/continuous-delivery/use-continuous-delivery/verify-deployments/configure-cv/configure-verify-step-with-ai/ai-verify>

## Overrides

- Overrides V2 (current): own entity under Deployments > Overrides; project,
  org or account scope; inline or remote in Git. Doc still flags Beta; once
  enabled it is account-wide.
- Priority: Service & Infrastructure Specific > Infrastructure Specific >
  Service Specific > Global Environment; then Project > Org > Account.
- Variables and config files are replaced wholesale; values YAML merges.
  V1 (legacy) used environment config + environment service overrides.

Doc: <https://developer.harness.io/continuous-delivery/use-continuous-delivery/cd-building-blocks/overrides-v2>

## Deployment types

| Type | `deploymentType` | Steps / strategies |
| --- | --- | --- |
| Kubernetes (Helm rendered by Harness) | `Kubernetes` | `K8sRollingDeploy`, `K8sCanaryDeploy` + Canary Delete, `K8sBlueGreenDeploy` + `K8sBGSwapServices`, `K8sApply` |
| Native Helm (`helm upgrade`, hooks run) | Native Helm (UI) | Helm Deploy; Helm Canary and Blue Green steps in the step reference |
| ECS | `ECS` | `EcsRollingDeploy`; Canary, Blue Green, Basic |
| AWS Lambda | `AwsLambda` | `AwsLambdaDeploy`, `AwsLambdaCanaryDeploy`, rollback steps |
| Serverless.com on Lambda | Serverless (UI) | Containerized or delegate steps; v4 needs CLI auth |
| SSH / WinRM | `Ssh` / `WinRm` | Command steps on target hosts |
| Custom | `CustomDeployment` | Deployment Template scripts fetch hosts and deploy |

- Kubernetes-type Helm versions ConfigMaps/Secrets, self-rolls back, skips
  hooks; Native Helm uses Helm rollback. K8s canary: one Deployment per stage.

Doc: <https://developer.harness.io/continuous-delivery/use-continuous-delivery/deploy-services-on-different-platforms/helm/helm-cd-quickstart>

## Strategies and rollback

- Strategies: Rolling, Canary, Blue Green, Basic, Build, Multi-service.
- `rollbackSteps` run on failure action Rollback Stage (`StageRollback`) or
  Rollback Pipeline.
- Post-deployment rollback (service dashboard > instance): K8s, ASG, TAS,
  ECS, Native Helm, MIG; successful runs from the last 30 days; once per
  execution; replays that execution's YAML.

Doc: <https://developer.harness.io/continuous-delivery/use-continuous-delivery/manage-deployments/rollback-deployments>

## Continuous Verification

| Step | Setup | Health sources |
| --- | --- | --- |
| AI Verify (v1) | Monitored service, manual health sources, sensitivity High/Medium/Low (1σ/2σ/3σ) | AppDynamics, CloudWatch, Datadog, Dynatrace, GCP Ops, New Relic, Prometheus, Splunk, Sumo, ELK, Loki, custom |
| AI Verify (v2) | `AIVerifyNG` in a container step group (`stepGroupInfra`) | Datadog, Dynatrace (AI-configured); New Relic metrics, Splunk logs |

- v1 analysis types: Auto, Rolling Update, Canary, Blue Green, Load Test.

Doc: <https://developer.harness.io/continuous-delivery/use-continuous-delivery/verify-deployments/verify-deployments-with-the-verify-step>

## Freeze windows

- `freeze`: `entityConfigs` (Org, Project, Service, EnvType, Environment,
  Infrastructure; `filterType`), `windows` with recurrence, `status`,
  `notificationRules`. Scopes: account, org, project, plus Global.
- Running pipelines finish the current stage, then Aborted By Freeze;
  Rollback Pipeline is blocked unless a support flag skips the check.
- Account admins bypass; triggers are rejected during a freeze.

Doc: <https://developer.harness.io/continuous-delivery/use-continuous-delivery/manage-deployments/deployment-freeze>

## Artifact sources and triggers

- Sources include Harness Artifact Registry, Docker, GAR, GCR, ECR, ACR,
  S3, GCS, AMI, Nexus, Artifactory, Azure Artifacts, GitHub Packages, custom.
- Artifact triggers poll continuously; wait 5-10 minutes after create or
  update; pass the tag via `<+trigger.artifact.build>`; never on `latest`.

Doc: <https://developer.harness.io/harness-platform/use-harness-platform/triggers/trigger-on-a-new-artifact>

## Harness GitOps

- Argo CD is the only reconciler. The outbound-only GitOps Agent installs or
  overlays Argo CD (BYOA) in-cluster or hub-and-spoke.
- Entities: Agent, Cluster, Repository, Application, ApplicationSet (all
  generators; Git generator in PR pipelines), Argo project mapping.
- Stage: `deploymentType: Kubernetes`, `gitOpsEnabled: true`,
  `environment.gitOpsClusters`.
- Steps: `GitOpsUpdateReleaseRepo`, `MergePR`, `RevertPR`,
  `FetchLinkedApps`, `GitOpsSync`, `UpdateGitOpsApp`, GitOps Rollback.
- GitOps services use Application Set references (`appsetConfigs`); the
  Deployment Repository manifest stopped working on 20 Nov 2026.

Doc: <https://developer.harness.io/continuous-delivery/use-gitops/get-started/harness-git-ops-basics>
