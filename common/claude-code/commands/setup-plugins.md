# Setup Plugins

Install Claude Code plugins from curated marketplaces. This command
registers plugin sources and installs selected plugins for enhanced
development workflows.

## Plugin Marketplaces

The following marketplaces are registered as plugin sources:

| Marketplace | Focus |
|-------------|-------|
| `hashicorp/agent-skills` | HashiCorp tooling (Terraform, Vault, Consul) |
| `ahmedasmar/devops-claude-skills` | DevOps automation and infrastructure |
| `akin-ozer/cc-devops-skills` | Cloud-native DevOps practices |
| `Jeffallan/claude-skills` | General-purpose development skills |

## Instructions

For each marketplace listed above:

1. Clone or fetch the repository from GitHub
2. Review available plugins/skills in the repository
3. Install plugins that match the current project's domain:
   - **Terraform/IaC projects**: prioritize hashicorp/agent-skills, devops skills
   - **Kubernetes projects**: prioritize devops skills, cloud-native skills
   - **Go/Java projects**: prioritize general development and API skills
   - **Ansible projects**: prioritize devops and automation skills

4. Install by copying skill files to `~/.claude/skills/`
   following the existing skill structure
5. Report what was installed and any conflicts with existing skills

## Steps

1. Check existing skills in `~/.claude/skills/` to avoid duplicates
2. For each marketplace, fetch the repo contents and list available skills
3. Present the user with a selection of relevant skills based on the current project
4. Install selected skills to `~/.claude/skills/`
5. Verify skills are loadable by checking file structure
