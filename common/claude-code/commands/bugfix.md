## Bugfix Command

**Arguments:** `issue-description`

<command_purpose>
Fix bugs using enhanced global standards with structured thinking and memory integration.
</command_purpose>

<execution_workflow>

### 1. Reproduce Bug

**Following**: Global `<testing_strategy>` → "Bug fixes → Reproduce issue with test first"

<reproduction_process>
  <thinking>
  Before implementing the fix:

  1. Understand the expected behavior
  2. Identify the actual behavior
  3. Create minimal reproduction case
  4. Write failing test that demonstrates the bug
  </thinking>

```javascript
// Following global testing strategy
describe("Bug Reproduction - Issue #123", () => {
  test("should reproduce the authentication timeout issue", () => {
    // Failing test that demonstrates the exact bug
    expect(authService.validateToken(expiredToken)).toThrow("Token expired");
  });
});
```

</reproduction_process>

### 2. Investigation

**Following**: Global `<agent_coordination>` + `<problem_solving_protocol>` + `<reasoning_tool_guide>`

<investigation_steps>
  **Multi-Agent Strategy**: "I'll spawn agents to tackle different aspects"

  - Agent 1: Root cause analysis
  - Agent 2: Impact assessment
  - Agent 3: Similar bug pattern research

  **Memory Integration** (from global `<memory_management>`):
  - Load relevant memory about similar bugs and solutions
  - Use LSP tools for navigation and code understanding

  **Problem-Solving Protocol**:
  1. **Stop** - Don't continue coding blindly
  2. **Document** - Write down the exact problem
  3. **Simplify** - Break into smaller components
  4. **Analyze** - Use appropriate reasoning tool:
     - **Code-reasoning**: For analyzing bugs and debugging logic
     - **Sequential-thinking**: For multi-step debugging process
     - **Ultrathink**: For complex systemic issues
  5. **Delegate** - Spawn agents for parallel investigation
  6. **Ask** - Request guidance when approaches are equally valid
</investigation_steps>

### 3. Fix Implementation

**Following**: Global `<implementation_standards>` + Reality Checkpoints

<implementation_process>
  <analysis>
  Apply systematic fix approach:

  1. Implement minimal fix that resolves root cause
  2. Ensure fix aligns with code quality principles
  3. Validate no regressions introduced
  </analysis>

  **Reality Checkpoints**:
  - ✓ Does fix resolve the issue?
  - ✓ No new bugs introduced?
  - ✓ Is this the simplest solution?
  - ✓ Follows security requirements?

  <security_notes>
    Validate fix doesn't introduce security vulnerabilities:

    - Input validation maintained
    - No new attack vectors created
    - Authentication/authorization preserved
  </security_notes>
</implementation_process>

### 4. Enhanced Communication

**Using**: Global `<communication_patterns>` with XML structure

<example_communication>
  ```
  <analysis>
    Identified race condition in JWT token validation causing intermittent auth failures
  </analysis>

  <plan>
    1. Implement mutex lock for token validation
    2. Add comprehensive test coverage
    3. Update error handling for better debugging
  </plan>

  ✓ Completed: Bug reproduction with test (11:00)
  ✓ Completed: Root cause analysis - race condition in auth (11:15)
  → Next: Implementing mutex solution with test coverage
  ```
</example_communication>
</execution_workflow>
