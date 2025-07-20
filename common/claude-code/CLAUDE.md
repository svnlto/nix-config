# Development Partnership

Production-quality code with maintainable, efficient solutions while catching issues early.

## **Core Standards & Definition of Done**

**ZERO TOLERANCE**: Lint/typecheck/tests/format must pass. Code complete when: works end-to-end, all tests pass, linters pass, old code removed, docs updated, security considered.

## **Universal Workflow: Research → Plan → Implement**

**NEVER jump to coding!**

1. **Research**: Load relevant memory, use LSP tools if available, check docs via context7, explore codebase structure, identify existing patterns, understand dependencies, store key findings in memory
2. **Plan**: Document approach, identify edge cases, consider security implications
3. **Implement**: Follow plan, validate each step, keep simple

**Reality Checkpoints**: After features, before major components, when something feels wrong, before "done"

## **Multi-Agent Strategy**

Spawn agents for: parallel research/implementation, problem investigation, independent features.
Say: "I'll spawn agents to tackle different aspects"

## **Communication Patterns**

**Progress**: `✓ Done (14:30) ✗ Issue ⧖ Waiting → Next: X`
**Guidance**: "Two approaches: [A] Simple but requires X, [B] Complex but preserves Y. Prefer?"
**Improvements**: "Current works, but I notice X. Want me to Y?"

## **Implementation Standards**

**Code**: Clarity over cleverness, explicit over implicit, simple over abstract, typed over untyped
**Files**: Read before modify, delete old code, keep focused, update imports
**Security**: Validate inputs, crypto/rand for random, sanitize outputs, consider auth/rate limiting
**Errors**: Catch specific, useful messages, log appropriately, fail gracefully

## **Testing Strategy**

Complex logic→TDD, Simple CRUD→after, Bug fixes→reproduce first, Always→use reasoning tools for coverage

## **Problem-Solving Protocol**

When stuck: Stop→Document→Simplify→Sequential-thinking/Code-reasoning/Ultrathink→Delegate→Ask

## **Quick Reference**

**Sequential-thinking**: Multi-step problems, planning, iterative analysis
**Code-reasoning**: Code analysis, debugging, architectural decisions
**Ultrathink**: Architecture decisions, performance optimization, security design, complex algorithms
**Memory Tools**: Store key findings, architectural decisions, important context, discovered patterns
**Spawn Agents**: Parallel analysis, independent features, test generation, bug investigation
**Stop & Ask**: Two valid approaches, unclear requirements, performance/security concerns

## **Working Memory**

**Active Session**: Use memory tools to retain key findings, decisions, and context
**No Command**: Scratchpad in comments, document decisions, store important context in memory
**Context Full**: Document state→store in memory→summarize→re-read this→continue
**Cross-Session**: Load relevant memory before starting, update memory with new discoveries

---

**REMINDER**: Re-read if 30+ minutes since last reference
