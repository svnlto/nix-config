# Process Task Command

**Arguments:** `task-file-name`

Execute task from `.claude/tasks/` following global standards.

## Prerequisites

Global standards from `~/.claude/CLAUDE.md` are already loaded. This command extends those standards for task execution.

## Workflow:

### 0. Initialize Progress Tracking

```bash
# Create progress scratchpad using global Communication Protocol format
cat >> .claude/tasks/$ARGUMENTS.md << 'EOF'
## 📝 PROGRESS SCRATCHPAD
**Started:** **Phase:** Research & Analysis
### Working Items: [12 standard workflow items per global standards]
### Completed: [Global ✓ (HH:MM) format]
### Notes: [Global documentation style]
EOF
```

### 1. Research & Analysis Phase

**Following**: Global § "Universal Workflow - Research Phase" + "Working Memory" + "Multi-Agent Strategy"

- Load memory, use LSP tools, read task file, determine type, parse requirements
- Create branch: `git checkout -b ${taskFileName}`
- Apply multi-agent strategy for codebase exploration and pattern analysis
- Update scratchpad with global ✓ (HH:MM) format for each completed item

### 2. Planning & Design

**Following**: Global § "Universal Workflow - Planning Phase" + "Security Always" + "Testing Strategy"

Create design document covering:
```markdown
### Approach: [Global "Code Quality" principles]
### Security: [Input validation, crypto/rand, auth implications]
### Testing: [TDD for complex logic, test after for simple CRUD]
```

Apply tool selection per global § "Quick Reference": Sequential-thinking/Code-reasoning/Ultrathink
Submit to Gemini for validation - **DO NOT proceed without approval**

### 3. Implementation

**Following**: Global § "Implementation Standards" + "Problem-Solving Protocol"

For each requirement:
- Read files before modifying, follow exact paths, apply framework patterns
- Use reasoning tools for tests, maintain TypeScript typing, add error handling
- Apply reality checkpoints: end-to-end functionality, simplicity
- When stuck: Stop→Document→Simplify→Sequential-thinking/Code-reasoning/Ultrathink→Delegate→Ask

### 4. Quality Checks

**Following**: Global § "Core Standards & Definition of Done"

Verify: end-to-end functionality, tests pass, linters pass, old code removed, security considered

### 5. Code Review

**Following**: Global § "Communication Protocol"

Submit to Gemini, document feedback, address critical issues
Use global progress format: ✓/✗/→ with timestamps

### 6. Memory Update

**Following**: Global § "Working Memory"

Store architectural decisions, patterns, and context for future sessions

## Integration Examples

**Global Standard References**: Use § notation for Security Always, Testing Strategy, Problem-Solving Protocol
**Tool Selection**: Sequential-thinking (planning), Code-reasoning (analysis), Ultrathink (architecture)
**Memory Integration**: Load previous context, store patterns for future reference

## Completion Summary

```markdown
## ✅ TASK COMPLETION SUMMARY
### Global Standards: [Reference § "Definition of Done" checklist]
### Process: Research→Plan→Implement, multi-agent strategy, reasoning tools applied
### Communication: [Progress updates in global ✓/✗/→ format]
```
