# Harness CI

## YAML flavours

- Classic (v0): `pipeline.stages[].stage`, `type: CI`,
  `spec.execution.steps`. All examples here are v0.
- New experience / CI 3.0 (v1): flat `stages[].steps`, `run.script`,
  `runtime: cloud`, pipeline-level `clone`, typed `${{ inputs.x }}`. Never
  paste v0 into v1 unchanged. CI is now the "Builds" capability.

Doc: <https://developer.harness.io/continuous-integration/3.0/new-to-harness-ci/whats-new>

## Stage anatomy

```yaml
- stage:
    name: Build
    identifier: Build
    type: CI
    spec:
      cloneCodebase: true
      platform: { os: Linux, arch: Amd64 }
      runtime: { type: Cloud, spec: {} }
      execution:
        steps:
          - step:
              type: Run
              name: Test
              identifier: Test
              spec: { shell: Sh, command: make test }
```

- Workspace `/harness` is shared by all steps for the stage lifetime;
  other paths need `sharedPaths`; cross-stage data goes via cache.
- Stage timeout 1h default, 24h max; later stages can propagate infra.

Doc: <https://developer.harness.io/continuous-integration/use-harness-ci/use-harness-ci/set-up-build-infrastructure/ci-stage-settings>

## Codebase and clone

- `properties.ci.codebase`: `connectorRef` (or `repoName` for Harness Code),
  `build` (usually `<+input>`), `depth`, `prCloneStrategy`, `sslVerify`.
- `prCloneStrategy`: `MergeCommit` (default, fails on conflict) or
  `SourceBranch`. Depth: 50 for manual branch/tag, 0 for PR and triggers.
- `cloneCodebase: false` per stage; `GitClone` step for extra repos.

Doc: <https://developer.harness.io/continuous-integration/use-harness-ci/use-harness-ci/codebase-configuration/create-and-configure-a-codebase>

## Build infrastructure

| Option | Stage YAML | Caveats |
| --- | --- | --- |
| Harness Cloud | `runtime.type: Cloud`, optional `spec.size`, `nestedVirtualization` | Credits; connectors via Harness Platform only (no delegate, IRSA, AssumeRole); macOS runs no containers |
| Kubernetes | `infrastructure.type: KubernetesDirect`, `connectorRef`, `namespace`, `os` | Pod per stage; image required on every step; Kaniko for Build and Push |
| VMs (AWS, GCP, Azure, Anka) | `infrastructure.type: VM`, `spec.type: Pool`, `poolName` | Delegate + Drone VM runner; runner slated for deprecation end of Jan 2027 (Unified Runner) |
| Local runner | `runtime.type: Docker` | One Docker Delegate + Harness Docker Runner per host; small builds |

| Feature | Cloud | Kubernetes | VMs | Local |
| --- | --- | --- | --- | --- |
| Build Intelligence | Linux | Linux | No | No |
| Cache Intelligence | Yes | Yes | Yes | No (conflicting docs) |
| Docker layer caching | Yes | Yes (privileged) | Yes | Yes |
| Test Intelligence | Yes | Yes | Yes | Yes |

Doc: <https://developer.harness.io/continuous-integration/use-harness-ci/use-harness-ci/set-up-build-infrastructure/which-build-infrastructure-is-right-for-me>

## Step types

| Step | YAML `type` | Notes |
| --- | --- | --- |
| Run | `Run` | Bash, Sh, PowerShell, Pwsh, Python; `outputVariables`; `reports` |
| Background | `Background` | Service for stage lifetime; no failure strategy or outputs |
| Plugin | `Plugin` | Drone plugin `image` + `settings` |
| GitHub Action | `Action` | `uses` / `with`; Harness Cloud |
| Build and Push | `BuildAndPushDockerRegistry`, `...ECR`, `...GAR`, `...ACR` | Kaniko on K8s (needs root), drone-docker elsewhere |
| Test (TI v2) | `Test` | `command`, `intelligenceMode`, `globs`, `reports` list, `parallelism` |
| Run Tests (TI v1) | `RunTests` | Legacy; `runOnlySelectedTests: true` |

- Reach Background services at `stepId:port`; K8s/host mode: `localhost`.
- Outputs: `<+steps.ID.output.outputVariables.NAME>`; 64KB, single line by
  default.

Doc: <https://developer.harness.io/continuous-integration/use-harness-ci/use-harness-ci/run-step-settings>

## Caching

| Mechanism | How | Notes |
| --- | --- | --- |
| Cache Intelligence | Stage `caching.enabled: true`, optional `paths`, `key` | Auto restore/save; on by default for new stages |
| Harness cache steps | `SaveCache` / `RestoreCache`: `key`, `sourcePaths`, `archiveFormat` | Harness Cloud only; `cacheHit` output |
| Bucket cache steps | `SaveCacheS3` / `RestoreCacheS3`, GCS variants | Dedicated bucket |
| Docker layer caching | Build and Push `caching: true` | Switches engine to BuildKit/Buildx |
| Remote cache image | Build and Push `remoteCacheRepo` | Kubernetes only; wins over DLC |

- Auto-detects Maven, Gradle, Bazel, Yarn, Go, .NET; a custom path without
  a key disables Cache Intelligence.
- Self-managed infra needs object storage in Default Settings. Managed cache
  keeps 15 days; key on lockfiles: `{{ checksum "package-lock.json" }}`.

Doc: <https://developer.harness.io/continuous-integration/use-harness-ci/use-harness-ci/caching-ci-data/cache-intelligence>

## Build and Test Intelligence

- Build Intelligence: stage `buildIntelligence.enabled: true`; Gradle,
  Bazel, Maven 3.9+, Go; Run and Test steps only, never in a Dockerfile.
- Test Intelligence: Test step, `intelligenceMode: true`; Python, Java,
  Kotlin, Scala, Ruby, C#; unit tests only; no `venv`, no matrix; first run
  is the baseline; PR triggers need the Synchronize event.

Doc: <https://developer.harness.io/continuous-integration/use-harness-ci/use-harness-ci/run-tests/tests-v2>

## Reports and artifacts

- JUnit XML or TRX. Run step `reports.type: JUnit` + `spec.paths`; Test
  step `reports` list. Parallel runs need unique files per iteration.
- Artifacts (beta): `hcli artifact upload <src> --destination <path>` in
  Run steps; 5 GiB per file; Artifacts tab.

Doc: <https://developer.harness.io/continuous-integration/use-harness-ci/use-harness-ci/build-and-upload-artifacts/artifacts>

## Codebase expressions

- `<+codebase.branch>` (target branch on PRs), `<+codebase.commitSha>`,
  `<+codebase.shortCommitSha>`, `<+codebase.tag>`, `<+codebase.prNumber>`,
  `<+codebase.sourceBranch>`, `<+codebase.targetBranch>`,
  `<+codebase.build.type>`.
- Prefer them to `<+trigger.*>` (`null` on manual runs). Resolved only in
  CI stages, for the default codebase, never on cron runs.

Doc: <https://developer.harness.io/continuous-integration/use-harness-ci/use-harness-ci/codebase-configuration/built-in-cie-codebase-variables-reference>
