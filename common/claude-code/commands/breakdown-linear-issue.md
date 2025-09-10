## Linear Issue Breakdown Command

**Arguments:** `$ARGUMENTS` (Linear issue ID, e.g., DEV-35)

<command_purpose>
Break down Linear issue into executable tasks based on project type, following the enhanced global workflow patterns.
</command_purpose>

<execution_workflow>

### 1. Fetch & Analyze

**Following**: Global `<universal_workflow>` → Research Phase + `<memory_management>` + `<reasoning_tool_guide>`

<research_steps>
  1. Fetch issue details using Linear tools
  2. <thinking>
     Analyze issue context:
     - Detect project type (labels, file refs, team context)
     - Identify complexity level and security implications
     - Determine required reasoning tools
     </thinking>
  3. Load context from `.claude/prompts/[type]-dev.md`
  4. Apply memory tools and reasoning tools per global standards:
     - **Sequential-thinking**: For multi-step breakdown planning
     - **Code-reasoning**: For technical analysis and dependencies
     - **Ultrathink**: For complex architecture decisions
</research_steps>

### 2. Task Generation

**Following**: Global `<implementation_standards>` → `<code_quality>`

<task_generation>
  Generate 3-8 discrete tasks using enhanced project-specific patterns:

  **Base Template with XML Structure**:

  ```markdown
  <task_header>
    # Task N - [Name]

    **Type**: [Frontend/Backend/Infrastructure/Fullstack]
    **Complexity**: [Simple/Medium/Complex]
    **Estimated**: [Time estimate]
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

    **Technical** (per global `<implementation_standards>`):
    - Clarity over cleverness
    - Explicit over implicit
    - Simple over abstract
    - Strong typing required

    **Security** (per global `<security_requirements>`):
    - Input validation at boundaries
    - Crypto/rand for random generation
    - Output sanitization
    - Authentication/rate limiting considerations

    **Testing** (per global `<testing_strategy>`):
    - [TDD for complex logic / Tests after for simple CRUD]
    - Edge case coverage
    - Integration test requirements
  </requirements>

  <implementation_guidance>
    <thinking>
    Approach this by:

    1. [Step-by-step implementation strategy]
    2. [Key technical decisions needed]
    3. [Potential pitfalls to avoid]
    </thinking>

    **Examples**: [Concrete code examples where helpful]
    **Patterns**: [Reference existing codebase patterns]
  </implementation_guidance>

  <acceptance_criteria>
    **Global Standards** (per `<core_standards>`):
    - ✓ Works end-to-end
    - ✓ All tests pass
    - ✓ Linters pass
    - ✓ Old code removed
    - ✓ Documentation updated
    - ✓ Security considered

    **Task-Specific**:
    - ✓ [Specific measurable criteria]
    - ✓ [Performance requirements if applicable]
    - ✓ [Integration requirements]
  </acceptance_criteria>
```

  ```

  **Project-Specific Enhancements**:
  - **Terraform**: +provider configs, +terraform validate/test, +state management
  - **React**: +TypeScript interfaces, +Storybook stories, +pnpm test, +accessibility
  - **Fastify**: +schema validation, +OpenAPI spec, +rate limiting
  - **Backend**: +migrations, +E2E tests, +monitoring/logging
</task_generation>

### 3. Output Generation

**Following**: Global `<communication_patterns>` + `<output_formatting>` + `<memory_management>`

<output_process>
  1. Create task files: `/tasks/[issue]-task-[n]-[description].md`
  2. Use enhanced progress format:

     ```
     <analysis>
       Broke down issue DEV-35 into 5 discrete tasks covering authentication refactor
     </analysis>

     ✓ Completed: Issue analysis and task breakdown (14:30)
     → Next: Creating task files with enhanced templates
     ```

  3. Store breakdown patterns in memory for future sessions
  4. **Multi-Agent Strategy**:
     - Spawn agent for codebase analysis
     - Spawn agent for dependency mapping
     - Spawn agent for test coverage assessment
</output_process>
</execution_workflow>

<auto_detection>
**Enhanced Project Detection**:

```javascript
function detectProjectType(issue) {
  const detectionRules = {
    labels: {
      terraform: ["infrastructure", "terraform", "aws", "gcp"],
      react: ["frontend", "ui", "react", "nextjs"],
      fastify: ["api", "backend", "fastify"],
      fullstack: ["fullstack", "end-to-end"],
    },
    files: {
      terraform: [".tf", ".tfvars", "terraform/"],
      react: [".tsx", ".jsx", "components/", "pages/"],
      fastify: ["routes/", "plugins/", "schemas/"],
    },
    teams: {
      terraform: ["Infrastructure", "DevOps", "Platform"],
      react: ["Frontend", "UI/UX"],
      fastify: ["Backend", "API"],
    },
  };

  // Enhanced detection with fallback to prompt
  return analyzeContext(issue, detectionRules) || promptForType();
}
```

</auto_detection>
