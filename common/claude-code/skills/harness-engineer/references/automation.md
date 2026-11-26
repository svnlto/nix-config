# Automating Harness

## Credentials: API keys, tokens, service accounts

| Concept | What it is |
| --- | --- |
| API key | Container for tokens. Personal keys: **My Profile** (account level only). Service-account keys: **Account Settings → Access Control → Service Accounts**. |
| Token | The secret you send: PAT (`pat.…`) or SAT (service account token). Shown once; optional expiry; rotatable. |
| Service account | Non-human principal; its keys and tokens inherit its role bindings. Creating one needs Account Admin or equivalent. |
| Scoped token (Beta, `PL_ENABLE_SCOPED_TOKENS`) | Token limited to declared permissions, intersected with the owner's. Persistent, or ephemeral (5 min to 24 h). |

A token can do whatever its owner can. Harness recommends SATs for Terraform
and other automation.

Doc: <https://developer.harness.io/harness-platform/use-harness-platform/automation/api/add-and-manage-api-keys>

## REST API

- Base `https://app.harness.io` + service path (`/gateway/ng/api`,
  `/gateway/pipeline/api`); other clusters use their own host. Reference:
  <https://apidocs.harness.io/>.
- Header `x-api-key: <token>` (FME Admin API: `Authorization: Bearer`).
  Params `accountIdentifier`, `orgIdentifier`, `projectIdentifier`; IaCM and
  DB DevOps take a `Harness-Account` header.
- `401` bad token, `403` no permission, `404` wrong scope, `429` back off.

```bash
curl "https://app.harness.io/gateway/ng/api/projects?accountIdentifier=$ACCOUNT_ID" \
  -H "x-api-key: $HARNESS_API_KEY"
```

Doc: <https://developer.harness.io/api-reference>

## Pipeline execution: API and webhook

| Method | Call |
| --- | --- |
| Runtime input YAML | `POST /gateway/pipeline/api/pipeline/execute/{pipelineId}` + scope params, body `application/yaml` (template from `/inputSets/template`) |
| Saved input sets | `POST …/pipeline/execute/{pipelineId}/inputSetList`, body `{"inputSetReferences": ["…"]}` |
| Git-backed pipeline | Add `branch` and `repoIdentifier` query params |
| Custom webhook trigger | `POST /gateway/pipeline/api/webhook/custom/{customWebhookToken}/v3` + scope params + `pipelineIdentifier`, `triggerIdentifier`; `X-Api-Key` when enforced |
| Trigger status | `GET` the returned `apiUrl` (`/webhook/triggerExecutionDetails/{eventId}`) with `X-Api-Key` holding pipeline View |

Copy the trigger call via **Copy as cURL Command**. Without enforced
authorization, the URL alone runs the pipeline.

Doc: <https://developer.harness.io/harness-platform/use-harness-platform/triggers/trigger-deployments-using-custom-triggers>

## Harness CLI (`harness`, repo `harness/cli`)

Current open-source Go CLI; the older `harness/harness-cli` is archived.

```bash
curl -fsSL https://raw.githubusercontent.com/harness/cli/main/install.sh | sh
harness auth login --profile ci --api-token "$HARNESS_API_KEY" \
  --account "$HARNESS_ACCOUNT"
harness execute pipeline deploy_service --input-set prod --branch main --follow
harness get execution deploy_service/<execution_id> --format json
```

- Also `brew install --cask harness/tap/harness-cli`. Profiles live in
  `~/.harness/config.yaml`. Env: `HARNESS_API_KEY`, `HARNESS_ACCOUNT`,
  `HARNESS_PROFILE`, `HARNESS_ORG`, `HARNESS_PROJECT`, `HARNESS_API_URL`.
- Grammar `harness <action> <resource> [id] [flags]`; actions `list`, `get`,
  `create` (`-f`/`--set`), `update` (`--set`/`--del`), `delete`, `execute`.
  `harness list noun --matrix` lists `resource:operation` forms. Flags:
  `--org`, `--project`, `--level`, `--format text|json|yaml`.

Doc: <https://developer.harness.io/harness-platform/use-harness-cli/harness-cli/harness-cli-overview>

## Terraform provider `harness/harness`

- Resources `harness_platform_*`: `organization`, `project`, `connector_*`,
  `secret_text`, `service`, `environment`, `pipeline`, `input_set`,
  `triggers`, `template`, `usergroup`, `roles`, `role_assignments`,
  `service_account`, `apikey`, `token`, `idp_catalog_entity`, `workspace`.
- Scope arguments `org_id`, `project_id`; in embedded YAML reference higher
  scopes as `org.<id>` or `account.<id>`.
- Env: `HARNESS_ENDPOINT`, `HARNESS_ACCOUNT_ID`, `HARNESS_PLATFORM_API_KEY`.
  `api_key` is FirstGen. Cannot provision users (SCIM) or run pipelines.

```hcl
provider "harness" {
  endpoint         = "https://app.harness.io/gateway"
  account_id       = var.harness_account_id
  platform_api_key = var.harness_sat
}

resource "harness_platform_project" "payments" {
  identifier = "payments"
  name       = "Payments"
  org_id     = "default"
}
```

Doc: <https://registry.terraform.io/providers/harness/harness/latest/docs>

## Harness MCP server (`harness/mcp-server`)

TypeScript server, npm `harness-mcp-v2`: 11 generic tools over about 139
resource types, not one tool per endpoint.

- Read: `harness_describe`, `_schema`, `_list`, `_get`, `_search`,
  `_diagnose`, `_status`. Write: `harness_create`, `_update`, `_delete`,
  `_execute`.
- Local: `claude mcp add harness -- npx harness-mcp-v2` with `HARNESS_API_KEY`
  (PAT or SAT; account ID comes from the token). Transport `stdio` or
  `http --port <n>`.
- Hosted (SaaS, OAuth via Harness ID, enabled by Support):
  `https://mcp.harness.io/mcp`, client ID `mcp-client`.
- `HARNESS_TOOLSETS` filters the 30 toolsets (all on by default): e.g.
  `pipelines`, `connectors`, `logs`, `audit`, `idp`, `ccm`, `sto`, `gitops`.
  Also `HARNESS_BASE_URL`, `HARNESS_ORG`, `HARNESS_PROJECT`.

Doc: <https://developer.harness.io/harness-ai/new-experience/use-harness-ai/ide-and-integrations/mcp-server/harness-mcp-server>

## Safe operation

- One service account per integration, bound to the narrowest role and
  resource group at the lowest scope (for example Account Viewer for
  read-only reporting). Use scoped tokens where enabled.
- Set expiry, rotate, and keep tokens in a secret manager, never in YAML.
- MCP: use `HARNESS_READ_ONLY=true` and a trimmed `HARNESS_TOOLSETS` for
  exploration. Writes confirm via elicitation; clients without it still run
  create, update, and execute, and only `harness_delete` is blocked. Never
  combine `HARNESS_AUTO_APPROVE_RISK=all` with the full toolset.
- IDP `apiKeySecret` runs pipelines as the key's owner; limit that service
  account to the onboarding project.

Doc: <https://developer.harness.io/harness-ai/new-experience/use-harness-ai/ide-and-integrations/mcp-server/approvals-and-safety>
