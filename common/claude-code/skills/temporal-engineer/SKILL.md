---
name: temporal-engineer
description: Temporal workflow orchestration — durable execution, worker development, testing, versioning, and operations. Use when writing or reviewing Temporal workflows/activities, configuring workers, debugging non-determinism errors, setting up replay testing, versioning with patches, tuning worker performance, operating Temporal clusters, designing entity workflows, platform control planes, multi-tenant patterns, Nexus cross-namespace communication, or saga compensation.
metadata:
  version: "2.0.0"
  domain: distributed-systems
  triggers: temporal, workflow, activity, worker, task queue, durable execution, retry policy, signal, query, update, child workflow, continue-as-new, workflow determinism, non-deterministic error, replay, GetVersion, patched, heartbeat, schedule-to-close, start-to-close, temporal server, temporal cli, temporal cloud, saga, compensation, entity workflow, nexus, multi-tenant, namespace, search attribute, codec, mTLS, schedule, overlap policy, standalone activity, workflow stream, platform control plane, async completion
  role: specialist
  scope: implementation
  output-format: code
  related-skills: sre-engineer, monitoring-expert, kubernetes-specialist, ci-cd, platform-engineer, secrets-management
---

# Temporal Engineer

## Core Philosophy

1. **Workflows are deterministic state machines.** No I/O, no
   randomness, no system clock, no goroutines. All side effects go
   through Activities. Replay must produce identical commands.

2. **Activities are the boundary.** They handle I/O, external calls,
   and non-deterministic operations. Make them idempotent — Temporal
   retries by default. Heartbeat long-running activities.

3. **Durable execution means your code survives crashes.** Temporal
   persists every workflow state transition. Design for this: small
   payloads, explicit timeouts, bounded history via continue-as-new.

4. **Entity Workflows model resources.** One long-running workflow per
   managed resource. Deterministic IDs, compact state, serialized
   mutations via the main loop. Continue-as-new from day one.

## Decision Routing

| Topic | Reference |
|-------|-----------|
| Workflow & activity patterns, determinism, timeouts, limits | `workflow-development.md` |
| Signals, queries, updates, selectors, child workflows | `message-passing.md` |
| Error handling, failure types, saga compensation | `error-handling.md` |
| Unit testing, replay testing, failure injection, load testing | `testing.md` |
| Versioning with patches, worker versioning, safe deploys | `versioning.md` |
| Worker tuning, CLI, observability, namespaces, search attributes | `operations.md` |
| Schedules, Nexus, multi-tenant, entity workflows, platform patterns | `advanced-patterns.md` |
| mTLS, encryption, codec server, RBAC, data protection | `security.md` |

## Quick Reference — System Limits

| Resource | Limit |
|----------|-------|
| Event history per workflow | 51,200 events OR 50 MB (warns at 10,240 / 10 MB) |
| Individual payload | 2 MB |
| gRPC message | 4 MB |
| Concurrent pending activities/signals/children | 2,000 (optimal ≤500) |
| Total signals per workflow | 10,000 |
| In-flight updates | 10 |
| Workflow ID / type / task queue name | 1,000 bytes |
| Custom search attribute value | 2 KB; total per workflow 40 KB |

## Quick Reference — Determinism Rules

| Forbidden in Workflows | Use Instead |
|------------------------|-------------|
| `time.Now()`, `time.Sleep()` | `workflow.Now(ctx)`, `workflow.Sleep(ctx, d)` |
| `rand.Intn()`, `uuid.New()` | `workflow.SideEffect()` |
| HTTP calls, DB queries, file I/O | Activities |
| `go func()` (native goroutines) | `workflow.Go(ctx, func)` |
| Global mutable state | Workflow-local state |
| `select {}` (native channels) | `workflow.NewSelector(ctx)` |
| `sync.Mutex` | `workflow.NewMutex(ctx)` |

## Quick Reference — Anti-Patterns

| Anti-Pattern | Fix |
|-------------|-----|
| No timeout on activities | Always set `StartToCloseTimeout` or `ScheduleToCloseTimeout` |
| Unbounded workflow history | Continue-as-new; check `GetCurrentHistoryLength()` |
| Large payloads in signals/activities | Pass references (IDs, URLs), fetch in activity |
| Non-idempotent activities | Combine Workflow Run ID + Activity ID as idempotency key |
| Ignoring heartbeat for long activities | Set `HeartbeatTimeout`, call `activity.RecordHeartbeat()` |
| Modifying workflow code without versioning | Use `workflow.GetVersion()` or worker versioning |
| Single monolithic activity | Split into focused, independently retryable activities |
| Polling in workflow loops | Use signals or `workflow.Sleep()` with continue-as-new |
| Continue-as-new from signal/update handler | Only call from main workflow method |
| Excessive SDK wrapping | Keep thin — only for security, connectivity, metrics |
| Default retry policy in production | Configure explicit limits; defaults retry indefinitely |
| Merging activities to "save Actions" | Loses per-step visibility, independent retry, failure ID |
| PII in search attributes | Stored unencrypted; use workflow state + queries instead |
| Errors in Go signal handlers | Causes workflow failure; only throw for unrecoverable errors |

## Quick Reference — CLI Essentials

```bash
# Local dev server (persistent)
temporal server start-dev --db-filename /tmp/temporal.db

# Start workflow
temporal workflow start \
    --workflow-id my-wf-123 \
    --type MyWorkflow \
    --task-queue my-queue \
    --input '{"key": "value"}'

# Inspect
temporal workflow describe --workflow-id my-wf-123
temporal workflow list --query 'ExecutionStatus = "Running"'
temporal workflow show --workflow-id my-wf-123 --output json

# Lifecycle
temporal workflow cancel --workflow-id my-wf-123
temporal workflow terminate --workflow-id my-wf-123 --reason "cleanup"
temporal workflow reset --workflow-id my-wf-123 --event-id 10 --reason "fix"

# Signal / Query
temporal workflow signal --workflow-id my-wf-123 \
    --name my-signal --input '"data"'
temporal workflow query --workflow-id my-wf-123 --name get-status
```
