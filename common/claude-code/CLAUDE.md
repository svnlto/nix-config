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

## Workflow

- Read before modifying — never assume file contents
- Prefer editing existing files over creating new ones
- Question abstractions that don't solve existing problems
- Commit only when explicitly asked

## Installed Skills

Globally installed (auto-invoked by description match):

| Skill | Description | Best For |
|-------|-------------|----------|
| ci-cd | CI/CD pipeline design, secret management | All projects |
| devsecops-expert | Secure pipelines, shift-left security | Terraform, K8s, Ansible |
| rest-api-design | API design patterns | Go, Java |
| security-auditing | Code and infra security review | All projects |
| argo-expert | ArgoCD GitOps workflows | Kubernetes |
| cilium-expert | eBPF networking, network policies | Kubernetes |
| cloud-api-integration | Cloud AI API integration | Go, Java |
| database-design | Schema design, indexing, FTS | Java, Go |
| talos-os-expert | Talos Linux cluster management | Kubernetes |
| ado-standards | ADO pull request and pipeline standards | Azure DevOps projects |
| secrets-management | Secrets management (Key Vault, Vault, AWS SM) | All projects |
| sre-engineer | SRE practices, SLOs, Datadog, Terraform reliability | Terraform, K8s, Datadog |

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
