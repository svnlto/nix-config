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

### 3. Fix Implementation

**Reality Checkpoint** (from global):

- ✓ Does fix resolve the issue?
- ✓ No new bugs introduced?
- ✓ Is this the simplest solution?

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
