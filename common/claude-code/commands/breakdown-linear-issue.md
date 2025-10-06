# Linear Issue Breakdown Command

**Arguments:** `$ARGUMENTS` (Linear issue ID, e.g., DEV-35)

<command_purpose>
Break down Linear issue into executable tasks
</command_purpose>

<execution_workflow>

## 1. Fetch & Analyze

<research_steps>

  1. Fetch issue details using Linear tools
  2. <thinking>
     Analyze issue context:
     - Detect project type (labels, file refs, team context)
     - Identify complexity level and security implications
     - Determine required reasoning tools
     </thinking>
  3. Load context from `.claude/prompts/[type]-dev.md`
  4. Apply reasoning tools:
     - **Sequential-thinking**: For multi-step breakdown planning
     - **Code-reasoning**: For technical analysis and dependencies
</research_steps>

## 2. Task Generation

**Following**: Global `<implementation_standards>` → `<code_quality>`

<task_generation>
  Generate discrete tasks using enhanced project-specific patterns:

  **Base Template with XML Structure**:

  ```markdown
  <task_header>
    # Task N - [Name]

    **Type**: [Frontend/Backend/Infrastructure/Fullstack]
    **Complexity**: [Simple/Medium/Complex]
  </task_header>

  <task_description>
    [Clear description with context]
  </task_description>

  <task_context>
    **Current State**: [Analysis of existing implementation]
    **Dependencies**: [Other tasks, external services, etc.]
    **Files to Modify**:

    - `path/to/file.ext` - [Purpose and changes needed]
    - `path/to/test.spec.ext` - [Test coverage required]
  </task_context>

  <requirements>
    **Functional**:
    - [Core functionality requirements]

    **Technical**:
    - Clarity over cleverness
    - Explicit over implicit
    - Simple over abstract
    - Strong typing required

    **Security**:
    - Input validation at boundaries
    - Crypto/rand for random generation
    - Output sanitization
    - Authentication/rate limiting considerations

    **Testing**:
    - [TDD for complex logic / Tests after for simple CRUD]
    - Edge case coverage
    - Integration test requirements
  </requirements>

  <acceptance_criteria>
    **Global Standards** (per `<core_standards>`):
    - ✓ Works end-to-end
    - ✓ All tests pass
    - ✓ Old code removed
    - ✓ Documentation updated
    - ✓ Security considered

    **Task-Specific**:
    - ✓ [Specific measurable criteria]
    - ✓ [Performance requirements if applicable]
    - ✓ [Integration requirements]
  </acceptance_criteria>
```

</task_generation>

</execution_workflow>
