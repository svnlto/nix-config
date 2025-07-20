# Linear Issue Breakdown Command

**Arguments:** `$ARGUMENTS` (Linear issue ID, e.g., DEV-35)

Break down Linear issue into executable tasks based on project type.

## Process:

### 1. Fetch & Analyze

**Following**: Global § "Universal Workflow - Research Phase" + "Working Memory" + "Quick Reference"

- Fetch issue details using Linear tools
- Detect project type (labels, file refs, team context)
- Load context from `.claude/prompts/[type]-dev.md`
- Apply memory tools, LSP tools, Sequential-thinking/Code-reasoning/Ultrathink per global standards

### 2. Task Generation

**Following: Global § "Implementation Standards - Code Quality"**

Generate 3-8 discrete tasks using project-specific patterns:

#### Base Template:

```markdown
# Task N - [Name]
[Description]

Files: [list with purposes]
[Context about current state]

Requirements:
- Technical requirements
- Security (per global § "Security Always")
- Testing (per global § "Testing Strategy")

[Implementation guidance + examples]

Acceptance:
- ✓ Global "Definition of Done"
- ✓ [Project-specific criteria]
```

#### Project-Specific Patterns:

**All Projects**: Examples, tests, acceptance criteria per global standards
**Terraform**: +provider configs, +terraform validate/test
**React**: +TypeScript interfaces, +Storybook, +pnpm test
**Fastify**: +schema validation, +OpenAPI spec
**Backend**: +migrations, +E2E tests

### 3. Output

**Following**: Global § "Communication Protocol" + "Working Memory"

Create task files: `/tasks/[issue]-task-[n]-[description].md`
Use global progress format, store breakdown patterns in memory

**Multi-Agent Strategy**: Spawn agents for codebase analysis, dependencies, test coverage

## Auto-Detection Logic

```javascript
function detectProjectType(issue) {
  // Labels: terraform, frontend → terraform, react
  // Files: .tf, .tsx, routes/ → terraform, react, fastify
  // Team: Infrastructure, Frontend → terraform, react
  // Default: promptForType()
}
```

## Quality Validation

Each task must meet global § "Definition of Done": clear path, security, tests, measurable acceptance, project standards.
