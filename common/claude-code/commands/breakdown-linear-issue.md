# Linear Issue Breakdown Command

**Arguments:** `$ARGUMENTS` (Linear issue ID, e.g., DEV-35)

Break down Linear issue into executable tasks based on project type.

## Process:

### 1. Fetch & Analyze

**Following: Global § "Universal Workflow - Research Phase"**

- Fetch issue details using Linear tools
- Detect project type from:
  - Issue labels (terraform, react, fastify, etc.)
  - File references in description
  - Project/team context
- Load appropriate context from `.claude/prompts/[type]-dev.md`
- **If complex**: "Let me ultrathink about this breakdown..."

### 2. Task Generation

**Following: Global § "Implementation Standards - Code Quality"**

Generate 3-8 discrete tasks using project-specific patterns:

#### Base Template (all projects):

```markdown
# Task N - [Descriptive Name]

[1-2 sentence description]

Files to Create/Modify:

1. [path/file.ext] - Purpose
2. [path/file.ext] - Purpose
   [etc...]

[Context paragraph about current state]

Requirements:

- Specific technical requirement
- Security/compliance requirement (per global § "Security Always")
- Testing requirement (per global § "Testing Strategy")

[Implementation guidance with patterns]

// Example configuration/code
[Project-specific example based on detected type]

Acceptance Criteria:

- ✓ All automated checks pass (lint, test, type-check)
- ✓ Feature works end-to-end
- ✓ Security validations in place
- ✓ [Project-specific criteria]
```

#### Project-Specific Patterns:

**Terraform Projects:**

- Include provider configurations
- Resource examples with tags
- Variable definitions with types
- Acceptance: `terraform plan/validate/test`

**React Projects:**

- Component structure examples
- TypeScript interfaces
- Test file patterns
- Acceptance: `pnpm test`, Storybook stories

**Fastify Projects:**

- Route definitions
- Schema validation examples
- Plugin patterns
- Acceptance: Integration tests, OpenAPI spec

**Backend Services:**

- API endpoint examples
- Database migrations
- Service layer patterns
- Acceptance: E2E tests, API docs

### 3. Output

**Following: Global § "Communication Protocol"**

Create task files: `/tasks/[issue]-task-[n]-[description].md`

Progress tracking:

```
✓ Fetched issue DEV-35 (10:30)
✓ Detected project type: terraform (10:31)
✓ Loaded terraform-dev.md context (10:32)
✓ Identified 5 tasks (10:45)
→ Creating task files...
```

## Multi-Agent Strategy

When breaking down complex features:

- Spawn agent to analyze existing codebase
- Spawn agent to identify dependencies
- Spawn agent to plan test coverage

## Auto-Detection Logic

```javascript
// Pseudo-code for project type detection
function detectProjectType(issue) {
  // Check labels
  if (issue.labels.includes("terraform")) return "terraform";
  if (issue.labels.includes("frontend")) return "react";

  // Check file references
  if (issue.description.match(/\.tf|terraform\//)) return "terraform";
  if (issue.description.match(/\.tsx?|components\//)) return "react";
  if (issue.description.match(/routes\/|fastify/)) return "fastify";

  // Check team/project context
  if (issue.team.name.includes("Infrastructure")) return "terraform";
  if (issue.team.name.includes("Frontend")) return "react";

  // Default or ask
  return promptForType();
}
```

## Quality Validation

Each generated task must meet global § "Definition of Done":

- Clear implementation path
- Security considerations included
- Test requirements defined
- Acceptance criteria measurable
- Project-specific standards applied
