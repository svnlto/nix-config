# Refactor Command

**Arguments:** `refactor-description`

Refactor code following global standards.

## Execution:

### 1. Analysis Phase

**Using: Global § "Universal Workflow - Research"**

Say: "Let me research the codebase and create a plan before implementing." (from global)

**Memory Integration** (from global § "Working Memory"):
- Load relevant memory about previous refactoring patterns
- Use LSP tools if available for navigation

- Read target file and dependencies
- Identify refactoring impact
- **Tool Selection** (from global § "Quick Reference"):
  - **Code-reasoning**: For analyzing existing code structure and architectural decisions
  - **Sequential-thinking**: For multi-step refactoring planning
  - **Ultrathink**: For complex architectural refactoring decisions

### 2. Implementation

**Using: Global § "Implementation Standards - Code Quality"**

Apply principles:

- Clarity over cleverness ✓
- Explicit over implicit ✓
- Simple over abstract ✓

**Memory Update** (from global § "Working Memory"):
- Store discovered patterns for future reference
- Store refactoring decisions and rationale

### 3. Validation

**Using: Global § "Core Standards & Definition of Done"**

Must pass all:

- Lint ✓
- Tests ✓
- Type-check ✓
- Feature works end-to-end ✓

## When Stuck

**Updated Problem-Solving** (from global § "Problem-Solving Protocol"):

Stop→Document→Simplify→Sequential-thinking/Code-reasoning/Ultrathink→Delegate→Ask

**Tool Selection for Refactoring**:
- Code-reasoning: When analyzing complex existing code structure
- Sequential-thinking: When planning multi-step refactoring approach
- Ultrathink: When making architectural refactoring decisions

## Progress Updates

**Format from: Global § "Communication Protocol"**

```
✓ Analyzed impact on 5 files (10:30)
→ Refactoring authentication module
✗ Test failing - investigating
```
