---
name: airflow-engineer
description: Apache Airflow DAG development, testing, performance tuning, security, and operations. Use when writing or reviewing DAGs, configuring Airflow, optimizing scheduler performance, setting up CI/CD for DAGs, managing secrets backends, or migrating to Airflow 3.x.
metadata:
  version: "1.0.0"
  domain: data-engineering
  triggers: airflow, DAG, dag_id, data pipeline, task idempotency, airflow scheduler, airflow secrets, airflow testing, dag.test, airflow 3, airflow migration, airflow security, airflow performance, parse time, min_file_process_interval, TaskGroup, SubDAG, data aware scheduling, assets, deadline alerts
  role: specialist
  scope: implementation
  output-format: code
  related-skills: sre-engineer, datadog-advisor, devsecops-expert, secrets-management, ci-cd
---

# Airflow Engineer

## Core Philosophy

1. **Tasks are transactions.** Each task completes entirely or not at
   all. Use UPSERT, partition by `data_interval_start`, never
   `datetime.now()`. Re-runs must produce identical results.

2. **Parse time is the bottleneck.** Top-level DAG code runs every
   `min_file_process_interval` seconds. No DB calls, no network, no
   `Variable.get()` at module level. Defer to Jinja or execution time.

3. **DAG authors are trusted users.** They execute arbitrary code on
   workers, DAG File Processor, and Triggerer. Treat DAG deployment
   like code deployment: PR reviews, static analysis, gated CI/CD.

## Decision Routing

| Topic | Reference |
|-------|-----------|
| Task design, idempotency, atomicity, granularity | `dag-design.md` |
| Testing strategies, `dag.test()`, CI/CD pipelines | `testing-cicd.md` |
| Scheduler tuning, parse-time hygiene, worker scaling | `performance-tuning.md` |
| Secrets backends, trust model, DAG author security | `security-config.md` |
| Airflow 3.x breaking changes, migration checklist | `airflow3-migration.md` |

## Quick Reference — Anti-Patterns

| Anti-Pattern | Fix |
|-------------|-----|
| `Variable.get()` at module level | Use `{{ var.value.get('foo') }}` in templates |
| `INSERT` in tasks | Replace with `UPSERT` for idempotency |
| `datetime.now()` in task logic | Use `data_interval_start` / `data_interval_end` |
| Monolithic extract-transform-load task | Split into one task per logical step |
| SubDAGs (removed in Airflow 3) | Use `TaskGroup` or Assets |
| Direct DB import in task code | Use Airflow Python Client or DB hooks |
| Many DAGs per file | One DAG per file for scalability |
| Deeply nested DAG structures | Prefer linear `A -> B -> C` chains |

## Quick Reference — Airflow 3.x

| Removed | Replacement |
|---------|-------------|
| SubDAGs | TaskGroups, Assets, Data Aware Scheduling |
| SLAs | Deadline Alerts (3.1, AIP-86) |
| Direct metadata DB access in tasks | Execution API (workers have no DB creds) |
| `from airflow.models import ...` in tasks | Airflow Python Client or DB hooks |
