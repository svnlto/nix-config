# Bugfix Command

**Arguments:** `issue-description`

Fix bugs using global standards.

## Workflow:

### 1. Reproduce Bug

**From: Global § "Testing Strategy - Bug fixes"**
"Write test that reproduces bug first" ← Direct quote from global

```javascript
// Following global testing strategy
test("should reproduce issue #123", () => {
  // Failing test that demonstrates the bug
});
```

### 2. Investigation

**From: Global § "Multi-Agent Strategy"**

If complex: "I'll have an agent investigate why this test is failing" (global phrase)

**Memory Integration** (from global § "Working Memory"):
- Load relevant memory about similar bugs and solutions
- Use LSP tools if available for navigation and code understanding

**Problem-Solving** (from updated global § "Problem-Solving Protocol"):

When debugging: Stop→Document→Simplify→Code-reasoning/Sequential-thinking→Delegate→Ask

**Tool Selection** (from global § "Quick Reference"):
- LSP tools: For navigating to definitions, finding references, code exploration
- Code-reasoning: For analyzing bugs, debugging logic, understanding existing implementations
- Sequential-thinking: For multi-step debugging, systematic investigation
- Memory tools: Load previous bug patterns, store solutions

### 3. Fix Implementation

**Reality Checkpoint** (from global):

- ✓ Does fix resolve the issue?
- ✓ No new bugs introduced?
- ✓ Is this the simplest solution?

**Memory Integration** (from global § "Working Memory"):
- Load relevant memory about similar bugs
- Store root cause analysis for future reference

### 4. Communication

**Using global format exactly:**

```
✓ Reproduced bug with test (11:00)
✓ Root cause: Race condition in auth (11:15)
→ Implementing mutex solution
```

## No Duplication Needed!

Notice: We don't repeat what's in global, we just reference it:

- "Follow § Problem-Solving Protocol"
- "Apply § Security Always principles"
- "Use § Communication Protocol format"
- "Apply § Working Memory for bug patterns"
