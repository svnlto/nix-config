# Global Preferences

## Languages & Tools

- Primary: Nix, Go, HCL, Bash, Ansible, Java
- JS package manager: pnpm (never npm or yarn)
- Testing: Vitest or Jest for JS/TS projects

## Code Style

- Functional and declarative over imperative
- Immutable data, pure functions, composition
- Explicit over implicit, simple over abstract
- Clarity over cleverness

## Work Environment

- Git hosting: Azure DevOps (not GitHub)
  — use ADO conventions for PRs, checks, policies
- SSH keys: RSA required (ADO rejects ED25519)
- Personal repos (like nix config): GitHub

## Documentation Editing

- Edit documents holistically, not piecemeal
- Stay at the requested abstraction level
  — no cost figures, source declarations, status headers,
  or version headers unless explicitly asked
- When a message reads as thinking-aloud or debating
  tradeoffs, ask before treating it as a change request

## Workflow

- Read before modifying — never assume file contents
- Prefer editing existing files over creating new ones
- Question abstractions that don't solve existing problems
- Commit only when explicitly asked
- Verify config tokens/keys against docs or source before trying them — don't trial-and-error

## Installed Skills

Globally installed (auto-invoked by description match):

| Skill | Description | Best For |
|-------|-------------|----------|
| ci-cd | CI/CD pipeline design, secret management | All projects |
| devsecops-expert | Secure pipelines, shift-left security | Terraform, K8s, Ansible |
| rest-api-design | API design patterns | Go, Java |
| security-auditing | Code and infra security review | All projects |
| cli-developer | Go CLI with Cobra, Bubbletea, Charmbracelet | Go projects |
| architecture-designer | System design, ADRs, trade-off analysis | All projects |
| kubernetes-specialist | K8s workloads, Helm, troubleshooting, operators | Kubernetes |
| cloud-architect | AWS/Azure architecture, Terraform, cost | All projects |
| cloud-api-integration | Cloud AI API integration | Go, Java |
| database-design | Schema design, indexing, FTS | Java, Go |
| talos-os-expert | Talos Linux cluster management | Kubernetes |
| ado-standards | ADO pull request and pipeline standards | Azure DevOps projects |
| secrets-management | Secrets management (Key Vault, Vault, AWS SM) | All projects |
| sre-engineer | SRE practices, SLOs, Datadog, Terraform reliability | Terraform, K8s, Datadog |
| monitoring-expert | Go observability, slog, OTel, pprof, k6, Datadog APM | Go projects |
| terraform-skill | Terraform/OpenTofu modules, testing, CI/CD, state management | Terraform, HCL |
| herdr | Herdr pane orchestration, agent state, workspace management | All projects |
| platform-engineer | IDP design, golden paths, self-service, developer experience | All projects |
| pr-review | PR review for GitHub and Azure DevOps, or local branch diffs | All projects |
| strategic-writing | Strategy document discipline: what/why not how, no implementation detail | All projects |
| datadog-advisor | Datadog monitoring strategy, alerting, tagging, dashboards, SLOs, cost | All projects |
| agno | Agno agent framework: agents, teams, workflows, MCP, AgentOS | Python agent projects |

## Superpowers Output

Superpowers specs and plans go to the Obsidian vault, not the project repo:

- Specs: `$HOME/Documents/obsidian-vault/Work/superpowers/specs/`
- Plans: `$HOME/Documents/obsidian-vault/Work/superpowers/plans/`

These files live in an Obsidian vault. When writing specs or
plans, invoke the `obsidian:obsidian-markdown` skill and use
Obsidian Flavored Markdown: frontmatter properties (title,
date, tags, aliases), wikilinks to related specs/plans, and
callouts for key decisions or warnings.

## Plugin Marketplaces

Use `/setup-plugins` to browse and install additional skills from:

- `hashicorp/agent-skills` — HashiCorp tooling
- `ahmedasmar/devops-claude-skills` — DevOps automation
- `akin-ozer/cc-devops-skills` — Cloud-native DevOps
- `Jeffallan/claude-skills` — General development
- `wshobson/agents` — Specialized agents
- `dwmkerr/claude-toolkit` — Developer productivity
