## Refactor Command

**Arguments:** `refactor-description`

<command_purpose>
Refactor code following enhanced global standards with systematic analysis and structured implementation.
</command_purpose>

<execution_workflow>

### 1. Enhanced Analysis Phase

**Following**: Global `<universal_workflow>` → Research Phase + `<memory_management>` + `<reasoning_tool_guide>`

<analysis_process>
**Mandatory Research Statement**:
"Let me research the codebase and create a comprehensive plan before implementing any changes."

<thinking>
Systematic refactoring analysis:
1. Load relevant memory about previous refactoring patterns
2. Use LSP tools for navigation and dependency analysis
3. Read target files and understand current architecture
4. Identify refactoring scope and impact assessment
5. Determine complexity level and required reasoning tools
</thinking>

**Memory Integration** (from global `<memory_management>`):

- Load previous architectural decisions
- Load discovered refactoring patterns
- Load security considerations from similar refactors

**Tool Selection** (per global `<reasoning_tool_guide>`):

- **Code-reasoning**: For analyzing existing code structure and dependencies
- **Sequential-thinking**: For multi-step refactoring planning and execution
- **Ultrathink**: For complex architectural refactoring decisions and trade-offs

**Impact Analysis**:

- Files affected and dependency mapping
- Breaking change assessment
- Performance implications
- Security impact evaluation
  </analysis_process>

### 2. Enhanced Implementation

**Following**: Global `<implementation_standards>` → `<code_quality>` + `<security_requirements>`

<implementation_process>
<analysis>
Apply enhanced refactoring principles:
</analysis>

**Code Quality Standards Applied**:

- ✓ Clarity over cleverness - Make code more readable
- ✓ Explicit over implicit - Remove hidden behaviors
- ✓ Simple over abstract - Reduce unnecessary complexity
- ✓ Strong typing - Improve type safety throughout

**Security Considerations**:

- Maintain input validation during refactoring
- Preserve authentication/authorization flows
- Ensure no new attack vectors introduced
- Validate crypto/random usage remains secure

<plan>
Structured refactoring approach:
1. Create comprehensive test coverage for existing behavior
2. Implement refactoring in small, verifiable steps
3. Validate each step maintains functionality
4. Update documentation and types
5. Remove old/unused code
</plan>

**Memory Update** (per global `<memory_management>`):

- Store refactoring patterns discovered
- Store architectural decisions and rationale
- Store successful refactoring strategies
  </implementation_process>

### 3. Enhanced Validation

**Following**: Global `<core_standards>` → Definition of Done

<validation_process>
**Comprehensive Quality Checks**:

- ✓ Lint checks pass
- ✓ Type checking passes
- ✓ All tests pass (existing and new)
- ✓ Feature works end-to-end
- ✓ Performance maintained or improved
- ✓ Security posture maintained
- ✓ Documentation updated

<security_notes>
Post-refactoring security validation:

- All input validation points preserved
- Authentication flows verified
- Authorization checks maintained
- No new security vulnerabilities introduced
  </security_notes>
  </validation_process>

### 4. Enhanced Problem Resolution

**Following**: Global `<problem_solving_protocol>`

<problem_resolution>
**When Encountering Issues**:

1. **Stop** - Don't continue refactoring blindly
2. **Document** - Write down the exact blocker
3. **Simplify** - Break refactoring into smaller steps
4. **Analyze** - Apply appropriate reasoning tool:
   - **Code-reasoning**: For complex code structure analysis
   - **Sequential-thinking**: For multi-step refactoring planning
   - **Ultrathink**: For architectural refactoring decisions
5. **Delegate** - Spawn agents for parallel analysis if needed
6. **Ask** - Request guidance when trade-offs are equally valid

**Tool Selection for Refactoring Challenges**:

- **Code-reasoning**: When analyzing complex existing code relationships
- **Sequential-thinking**: When planning multi-step refactoring sequences
- **Ultrathink**: When making significant architectural refactoring decisions
  </problem_resolution>

### 5. Enhanced Progress Communication

**Following**: Global `<communication_patterns>` + `<output_formatting>`

<communication_examples>
<example_communication>
**Enhanced Progress Format**:

```
<analysis>
Analyzed authentication module refactoring impact across 8 files
Identified opportunity to reduce complexity by 40% while improving type safety
</analysis>

<plan>
1. Add comprehensive test coverage for existing auth flows
2. Extract common authentication logic into reusable utilities
3. Implement strong TypeScript interfaces
4. Update error handling to be more explicit
5. Remove deprecated authentication methods
</plan>

✓ Completed: Impact analysis on 8 files (10:30)
✓ Completed: Test coverage for existing flows (11:00)
→ Next: Implementing utility extraction with type safety
✗ Issue: Dependency conflict with auth library - investigating resolution
```

</example_communication>

**Memory Integration Updates**:

- Document refactoring patterns that worked well
- Store architectural decisions and trade-offs made
- Record performance improvements achieved
- Save security considerations addressed
  </communication_examples>
  </execution_workflow>
  </command_purpose>
