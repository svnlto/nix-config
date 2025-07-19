# Process Task Command

**Arguments:** `task-file-name`

Execute task from `.claude/tasks/` following global standards.

## Prerequisites

Global standards from `~/.claude/CLAUDE.md` are already loaded. This command extends those standards for task execution.

## Workflow:

### 0. Initialize Progress Tracking

```bash
cat >> .claude/tasks/$ARGUMENTS.md << 'EOF'

---
## 📝 PROGRESS SCRATCHPAD
**Started:**
**Current Phase:** Research & Analysis

### Working Items:
<!-- Using global Communication Protocol format -->
- ⧖ Read and analyze task requirements
- ⧖ Determine task type and load appropriate context
- ⧖ Parse requirements and identify files to modify
- ⧖ Create feature branch
- ⧖ Create design document
- ⧖ Get design validation from Gemini
- ⧖ Implement each requirement
- ⧖ Generate tests using Ultrathink
- ⧖ Run all quality checks
- ⧖ Get code review from Gemini
- ⧖ Create completion summary

### Completed:
<!-- ✓ Item (HH:MM) format from global standards -->

### Notes:
<!-- Key findings, following global documentation style -->

EOF
```

### 1. Research & Analysis Phase

**Following: Global Standards § "Universal Workflow - Research Phase"**

```bash
# Direct reference to global workflow
echo "→ Applying 'Research → Plan → Implement' workflow from global standards"
echo "→ As per global: 'Let me research the codebase and create a plan before implementing.'"
```

- Read complete task file: `.claude/tasks/$ARGUMENTS.md`
- **UPDATE**: ✓ Read and analyze task requirements (HH:MM)
- Determine task type and load appropriate context from `.claude/prompts/` (e.g., terraform-dev.md, react-dev.md, fastify-dev.md)
- **UPDATE**: ✓ Determine task type and load appropriate context (HH:MM)
- Parse requirements, acceptance criteria, and files to modify
- **UPDATE**: ✓ Parse requirements and identify files to modify (HH:MM)
- Create branch: `git checkout -b ${taskFileName}`
- **UPDATE**: ✓ Create feature branch (HH:MM)

**Multi-Agent Strategy** (from global § "Multi-Agent Strategy"):

- Spawn agent for codebase exploration: "I'll spawn agents to explore different parts of the codebase"
- Spawn agent for pattern analysis: "Having an agent investigate existing patterns"

### 2. Planning & Design

**Following: Global Standards § "Universal Workflow - Planning Phase"**

When creating design document:

- ✓ Document approach (global standard)
- ✓ Identify edge cases (global standard)
- ✓ Consider security implications (global § "Security Always")

**For complex architecture** (from global § "When to Ultrathink"):
"Let me ultrathink about this architecture..."

Design document template with global sections:

```markdown
### Approach

[Following global "Code Quality" principles]

### Security Considerations

[Applying global § "Security Always":]

- Input validation strategy
- Randomness approach (crypto/rand)
- Auth implications

### Testing Strategy

[From global § "Testing Strategy":]

- Complex logic: TDD approach
- Simple CRUD: Test after
```

- **UPDATE**: ✓ Create design document (HH:MM)
- Submit to Gemini using `planner` mode for validation
- Revise based on feedback
- **UPDATE**: Document Gemini feedback in Notes section
- **DO NOT proceed without approval**
- **UPDATE**: ✓ Get design approval from Gemini (HH:MM)

### 3. Implementation

**Following: Global Standards § "Implementation Standards"**

For each requirement:

```bash
# Reality checkpoint (from global standards)
echo "✓ Checkpoint: Is feature working end-to-end?"
echo "✓ Checkpoint: Am I keeping it simple?"
```

- Read existing files before modifying
- Follow exact file paths from task
- Apply framework-specific patterns from loaded context
- Maintain TypeScript strict typing
- Add proper error handling
- Use Gemini `testgen` to generate tests
- **UPDATE**: ✓ Implement requirement [X] (HH:MM)
- **UPDATE**: ✓ Generate tests using Gemini testgen (HH:MM)

Apply these global principles:

- **Code Quality**: "Clarity over cleverness"
- **File Management**: "Read before modifying"
- **Error Handling**: "Catch specific errors"

**When stuck** (from global § "Problem-Solving Protocol"):

1. Stop - Document what isn't working
2. Check if we need to ultrathink
3. Consider spawning helper agents
4. Present options: "I see two approaches..."

### 4. Quality Checks

**Following: Global Standards § "Core Standards - ZERO TOLERANCE"**

```bash
# Must match global definition of done
echo "Checking against global 'Definition of Done':"
echo "✓ Feature works end-to-end?"
echo "✓ All tests pass?"
echo "✓ All linters pass?"
echo "✓ Old code removed?"
echo "✓ Security considered?"
```

### 5. Code Review

**Using: Global Standards § "Communication Protocol"**

- Submit to Gemini using `codereview` mode
- **UPDATE**: Document review feedback in Notes
- Address critical feedback
- **UPDATE**: ✓ Get code review from Gemini (HH:MM)

All updates follow global format:

```
✓ Implemented auth module (14:30)
✗ Rate limiting failing - investigating
→ Next: Debug rate limit logic
```

When asking for help (from global):
"I see two approaches:

- [A]: [Description with tradeoffs]
- [B]: [Description with tradeoffs]
  Which do you prefer?"

## Integration Examples:

### Referencing Specific Sections:

```bash
# When implementing security features
echo "Applying global § 'Security Always' principles..."

# When writing tests
echo "Following global § 'Testing Strategy' - using TDD for complex logic"

# When stuck
echo "Using global § 'Problem-Solving Protocol' step 4: ultrathink"
```

### Delegating to Global Workflow:

```bash
# Instead of duplicating instructions
echo "→ Executing standard 'Research → Plan → Implement' workflow"
# The global file has the complete details
```

### Using Global Quick Reference:

```bash
# Check triggers
echo "Checking global § 'Quick Reference - When to Spawn Agents'"
echo "✓ Parallel file analysis needed - spawning agent"
```

## Completion Summary

Template incorporates global standards:

```markdown
## ✅ TASK COMPLETION SUMMARY

### Global Standards Checklist:

[From § "Definition of Done"]

- ✓ Feature works end-to-end
- ✓ All tests pass
- ✓ All linters pass
- ✓ Old code removed
- ✓ Documentation updated
- ✓ Security considered

### Process Validation:

- ✓ Followed Research → Plan → Implement
- ✓ Used multi-agent strategy for: [tasks]
- ✓ Applied ultrathink for: [complex problems]
- ✓ Security validations: [list]

### Communication Log:

[Progress updates in global format]
```
