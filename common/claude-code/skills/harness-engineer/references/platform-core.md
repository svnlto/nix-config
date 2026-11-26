# Harness Platform Core

## Hierarchy and scope

- Scopes: **Account** > **Organization** > **Project**. Pipelines belong to
  a project; connectors, secrets, templates, delegates, roles, resource
  groups, and policies exist at any scope.
- Entities are usable at their scope and below, never above. An
  account-level template can fix only account-level resources; anything
  lower must be `<+input>`. `identifier` is immutable after save.
- Two schemas coexist: Classic (v0, `pipeline.stages[].stage.spec`) and
  the New experience (flat v1). Former modules (CD, CI, IACM, STO, CCM)
  are now capabilities of four "Harness Agents".

Doc: <https://developer.harness.io/harness-platform/new-experience/in-harness-new-experience/comparison>

## Scope prefixes in references

| Reference | Project | Org | Account |
| --- | --- | --- | --- |
| `templateRef`, `connectorRef`, `userGroups` | `id` | `org.id` | `account.id` |
| Secret | `<+secrets.getValue("id")>` | `"org.id"` | `"account.id"` |
| Custom variable | `<+variable.id>` | `<+variable.org.id>` | `<+variable.account.id>` |
| External SM path | `"hashicorpvault://smId/path/name#key"` | `"org.hashicorpvault://…"` | `"account.hashicorpvault://…"` |

Other schemes: `awssecretsmanager://`, `azurevault://`,
`gcpsecretsmanager://`. Built-in group: `account._account_all_users`.

Doc: <https://developer.harness.io/harness-platform/use-harness-platform/secrets/secrets-management/reference-existing-secret-manager-secrets>

## Connectors

- Categories: cloud providers, artifact repos, code repos, ticketing (Jira,
  ServiceNow), monitoring, secret managers, communication, AI providers.
- **Connectivity mode**: *Connect through Harness Platform* (required on
  Harness Cloud build infra) or *Connect through a Harness Delegate*
  (private networks; any delegate or tag-selected ones).
- Credentials are secret identifiers (`passwordRef`, `tokenRef`), never
  plaintext. Connection test runs on save; `ignoreTestConnection: true`
  skips it only with FF `CI_IGNORE_TEST_CONNECTION`.

Doc: <https://developer.harness.io/harness-platform/use-harness-platform/connectors/connectors-overview>

## Delegates

- Outbound-only HTTPS/WSS to Harness Manager. Install via Helm chart,
  Terraform Helm provider, Kubernetes manifest, or `docker run`; needs the
  account ID plus a delegate token.
- Images: `harness/delegate:yy.mm.verno` (kubectl, Helm bundled) and
  `yy.mm.verno.minimal` (no client tools; add via `INIT_SCRIPT` or a
  custom image). `latest` (legacy) is deprecated; FIPS images are SMP-only.
- Tags: name is auto-tagged; add `DELEGATE_TAGS="a,b"`. A delegate must
  carry every listed selector; explicit selection never falls back.
- Selector priority: step > step group > stage > pipeline > connector.
  Step selectors do not apply to CI (steps run in the build pod).
- HA: more replicas of one delegate, not duplicate installs. `upgrader`
  CronJob (hourly) auto-upgrades Helm/Terraform/manifest installs; Docker
  needs its own upgrader. EOS 6, EOL 8 months after release. 3.x: beta.

Doc: <https://developer.harness.io/harness-platform/use-harness-platform/delegates/delegate/manage-delegates/select-delegates-with-selectors>

## Secrets and secret managers

- Types: text, file, SSH key, WinRM. Value is *Inline* (stored by the
  chosen SM) or *Reference* (points at an existing external secret).
- Built-in **Harness Secret Manager** (Google Cloud KMS envelope
  encryption) vs external: HashiCorp Vault, AWS Secrets Manager, Azure Key
  Vault, GCP Secret Manager, AWS/GCP KMS, custom SM. Credentials for an
  external SM may only live in the built-in SM.
- The delegate decrypts, so it needs network access to the SM. YAML
  creates a skeleton only ("Incomplete Secret"); enter values in the UI.
- Reference by identifier, not name. Masking is exact-match: decoded or
  transformed values are not masked. Single-quote values containing `$`.
  Deleting an inline text secret also deletes it in the external SM.

Doc: <https://developer.harness.io/harness-platform/use-harness-platform/secrets/add-use-text-secrets>

## RBAC, service accounts, API keys

- Role assignment = principal (user, user group, service account) + role
  (actions) + resource group (objects), bound at a scope.
- Grants flow down only. Project Admin cannot use an account-level
  connector (`NG_ACCESS_DENIED`); assign at the resource's scope or use a
  resource group that includes child scopes.
- Additive, no explicit deny: a narrower role never removes access.
  Built-in roles: Account/Organization/Project Admin and Viewer, Pipeline
  Executor. Built-in RGs: *All Resources Including Child Scopes*, *All
  Account/Organization/Project Level Resources*. Only custom roles are
  reusable across scopes. ABAC refines connector/environment access.
- Service accounts (any scope) hold role bindings; API key → tokens that
  inherit the owner's permissions. PAT (`pat.`) is personal and account
  scope only; SAT (`sat.`) is for service accounts. Header `x-api-key`;
  expiry 30/90/180 days, custom, or none; token shown once.

Doc: <https://developer.harness.io/harness-platform/use-harness-platform/platform-access-control>
Doc: <https://developer.harness.io/harness-platform/use-harness-platform/automation/api/add-and-manage-api-keys>
Doc: <https://apidocs.harness.io/>

## Git Experience

- Per entity: **Inline** (stored in Harness) or **Remote** (YAML in Git
  under `.harness/`): pipelines, input sets, templates, services,
  environments, infra definitions, overrides, OPA policies (FF
  `OPA_IMPORT_FROM_GIT`). Artifact source templates are unsupported.
- References in the same repo load from the run branch; other repos, and
  remote children of inline parents, load from the default branch.
  `gitBranch` on the reference pins a template branch.
- Default sync is Harness→Git; bidirectional sync needs a webhook. The Git
  cache only speeds UI rendering; executions always fetch from Git.
- Settings: *Enforce Git Experience* (blocks new inline pipelines and
  templates), default store type, default and allowed repos. **Referenced
  By** is tracked for the default branch only.

Doc: <https://developer.harness.io/harness-platform/use-harness-platform/git-experience/configure-git-experience-for-harness-entities>

## Policy as Code (OPA)

- Rego policy → **policy set** (entity type + event + severity: *Error and
  Exit* or *Warn and Continue*). A policy outside a set is not enforced.
- Pipeline events: **On Save**, **On Run** (after preflight), **On Step
  Start**. Templates: On Save. Entity pages also cover connectors,
  secrets, services, environments, overrides, users and groups.
- Input is the expanded entity JSON; expressions are **not** resolved.
  SaaS lacks `http.send` and `net.lookup_ip_addr`.
- On Save also evaluates direct Git commits; a failing commit blocks
  runs. Arbitrary payloads: `Policy` step with `spec.type: Custom`,
  `spec.policySets`, `spec.policySpec.payload`. Rego shape: `package
  pipeline`, `deny[msg] { ... }` over `input.pipeline.stages[i].stage`.

Doc: <https://developer.harness.io/harness-platform/use-harness-platform/governance/policy-as-code/harness-governance-overview>
