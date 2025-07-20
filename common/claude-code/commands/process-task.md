## Process Task Command

**Arguments:** `task-file-name`

<command_purpose>
Execute task from `.claude/tasks/` following enhanced global standards with structured workflow.
</command_purpose>

<execution_workflow>

### 0. Initialize Enhanced Progress Tracking

```bash
# Create progress scratchpad using global communication protocol
cat >> .claude/tasks/$ARGUMENTS.md << 'EOF'
<progress_tracking>
## 📝 ENHANCED PROGRESS SCRATCHPAD
**Started:** $(date)
**Phase:** Research & Analysis
**Task File:** $ARGUMENTS

<current_phase>
Research & Analysis
</current_phase>

<working_items>
### Standard Workflow Items (per global standards):
- [ ] Load memory and context
- [ ] Use LSP tools for exploration
- [ ] Read and parse task requirements
- [ ] Determine project type and complexity
- [ ] Apply appropriate reasoning tools
- [ ] Create implementation plan
- [ ] Security consideration analysis
- [ ] Test strategy determination
- [ ] Reality checkpoint validation
- [ ] Implementation execution
- [ ] Quality validation
- [ ] Memory update and storage
</working_items>

<completed_items>
### Completed (Global ✓ (HH:MM) format):
</completed_items>

<analysis_notes>
### Analysis Notes:
</analysis_notes>
</progress_tracking>
EOF
```

### 1. Enhanced Research & Analysis

**Following**: Global `<universal_workflow>` → Research Phase + `<memory_management>` + `<agent_coordination>`

<research_process>
<thinking>
Systematic approach to task analysis:

1. Load relevant memory from previous sessions
2. Parse task file for requirements and context
3. Use LSP tools for codebase exploration
4. Determine complexity and required tools
5. Apply multi-agent strategy if needed
   </thinking>

**Multi-Agent Strategy Application**:

- Spawn agents for parallel codebase exploration
- Spawn agents for pattern analysis
- Spawn agents for dependency mapping

**Memory Integration**:

- Load previous architectural decisions
- Load discovered patterns and context
- Store new findings for future reference

**Tool Selection** (per global `<reasoning_tool_guide>`):

- **Sequential-thinking**: Multi-step task planning
- **Code-reasoning**: Technical analysis and architecture
- **Ultrathink**: Complex system design decisions

Branch creation: `git checkout -b task-${taskFileName}`
</research_process>

### 2. Enhanced Planning & Design

**Following**: Global `<universal_workflow>` → Planning Phase + `<security_requirements>` + `<testing_strategy>`

<planning_process>
Create comprehensive design document:

```markdown
<design_document>
<approach>
**Code Quality Principles Applied**:

- Clarity over cleverness ✓
- Explicit over implicit ✓
- Simple over abstract ✓
- Strong typing ✓
  </approach>

<security_analysis>
**Security Considerations**:

- Input validation requirements: [specific validations]
- Crypto/rand usage: [where randomness is needed]
- Authentication implications: [auth flow changes]
- Rate limiting needs: [endpoint protection]
  </security_analysis>

<testing_strategy>
**Test Approach**:

- TDD for complex business logic
- Post-implementation tests for simple CRUD
- Integration test requirements
- Edge case coverage plan
  </testing_strategy>

<implementation_plan>
<thinking>
Step-by-step implementation approach:

1. [Detailed implementation steps]
2. [Key decision points]
3. [Risk mitigation strategies]
   </thinking>
   </implementation_plan>
   </design_document>
```

**Validation Requirement**: Submit to human for approval - **DO NOT proceed without approval**
</planning_process>

### 3. Enhanced Implementation

**Following**: Global `<implementation_standards>` + `<problem_solving_protocol>`

<implementation_process>
For each requirement:

<implementation_steps>

1. **File Operations**:
   - Read files before modifying (global standard)
   - Follow exact paths from task specification
   - Apply framework-specific patterns

2. **Code Quality**:
   - Use reasoning tools for complex logic analysis
   - Maintain TypeScript typing throughout
   - Add comprehensive error handling
   - Follow security requirements

3. **Reality Checkpoints**:
   - Validate end-to-end functionality
   - Ensure solution simplicity
   - Check security implications
   - Verify test coverage

4. **Problem Resolution** (when stuck):
   - **Stop** - Don't continue coding blindly
   - **Document** - Write down the exact problem
   - **Simplify** - Break into smaller components
   - **Analyze** - Apply appropriate reasoning tool
   - **Delegate** - Spawn agents for parallel investigation
   - **Ask** - Request guidance for equally valid approaches
     </implementation_steps>
     </implementation_process>

### 4. Enhanced Quality Checks

**Following**: Global `<core_standards>` → Definition of Done

<quality_validation>
**Comprehensive Verification**:

- ✓ Works end-to-end with full functionality
- ✓ All tests pass (existing and new)
- ✓ All linters pass
- ✓ Type checking passes
- ✓ Old/unused code removed
- ✓ Documentation updated
- ✓ Security implications considered and addressed

<security_notes>
Final security validation:

- Input validation implemented
- Output sanitization verified
- Authentication flow tested
- Rate limiting functional (if applicable)
  </security_notes>
  </quality_validation>

### 5. Enhanced Code Review Process

**Following**: Global `<communication_patterns>`

<review_process>
Submit comprehensive review request:

```markdown
<analysis>
Completed task implementation with [summary of changes]
Applied global standards for [specific areas]
</analysis>

<plan>
Ready for review with the following highlights:
1. [Key implementation decisions]
2. [Security considerations addressed]
3. [Test coverage achieved]
</plan>

<next_steps>
Awaiting feedback before final completion
</next_steps>
```

**Progress Updates**: Use global ✓/✗/→ format with timestamps
**Feedback Integration**: Document and address all critical issues
</review_process>

### 6. Enhanced Memory Update

**Following**: Global `<memory_management>` → Cross-session persistence

<memory_update>
**Store for Future Sessions**:

- Architectural decisions made and rationale
- Patterns discovered and applied
- Security considerations and solutions
- Performance optimizations implemented
- Integration patterns used
- Test strategies that worked well
- Common pitfalls encountered and avoided
  </memory_update>
  </execution_workflow>

<completion_summary>

## ✅ ENHANCED TASK COMPLETION SUMMARY

<final_analysis>
Task completed following enhanced global standards:

- Applied structured workflow with XML organization
- Used appropriate reasoning tools throughout
- Implemented comprehensive security measures
- Achieved full test coverage per strategy
- Updated memory with learnings for future sessions
  </final_analysis>

**Global Standards Compliance**: All items from `<core_standards>` Definition of Done verified ✓
**Process Adherence**: Research→Plan→Implement with multi-agent strategy and reasoning tools applied ✓
**Communication**: Progress updates in enhanced ✓/✗/→ format with XML structure ✓
</completion_summary>
