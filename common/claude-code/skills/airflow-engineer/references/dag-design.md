# DAG Design Patterns

## Idempotency

Every task must produce the same result on re-run:

- **UPSERT, not INSERT.** `INSERT` duplicates data on retry.
- **Partition reads by `data_interval_start`/`data_interval_end`.** Never
  query "latest" data or use `datetime.now()` — both break idempotency
  and make backfills unpredictable.
- **Delete-then-write** is acceptable if the delete and write target the
  same partition key atomically.

```python
# ❌ Non-idempotent
def load(**ctx):
    db.execute("INSERT INTO target SELECT * FROM staging")

# ✅ Idempotent
def load(**ctx):
    start = ctx["data_interval_start"]
    end = ctx["data_interval_end"]
    db.execute("""
        DELETE FROM target WHERE ts >= %s AND ts < %s;
        INSERT INTO target SELECT * FROM staging WHERE ts >= %s AND ts < %s
    """, (start, end, start, end))
```

## Atomicity

Tasks are transactions: complete entirely or not at all. Never produce
partial results. If a task writes to multiple targets, wrap in a
transaction or write to a staging location and swap atomically.

## Task Granularity

One logical step per task. Monolithic tasks that extract, clean,
transform, and load are an anti-pattern — they prevent partial retries
and hide failures.

**Tradeoff**: too-fine-grained tasks create scheduler overhead. Aim for
**5–30 minute task duration** as a sweet spot.

```python
# ❌ Monolithic
extract_clean_transform_load = PythonOperator(task_id="do_everything", ...)

# ✅ Granular
extract >> clean >> transform >> load
```

## DAG Structure

- **Linear chains** (`A -> B -> C`) schedule faster than deeply nested
  trees. The scheduler resolves dependencies per-level; deeper trees
  mean more scheduling rounds.
- **One DAG per file.** Each file is parsed by one FileProcessor; many
  DAGs per file limits parallelism.
- **TaskGroups** replace SubDAGs (removed in Airflow 3). They group
  tasks visually without the operational overhead of a child DAG run.
- **Assets and Data Aware Scheduling** (Airflow 3) let downstream DAGs
  trigger on data availability rather than time or explicit triggers.

## XCom Discipline

- XCom is for **metadata** (row counts, file paths, status flags), not
  bulk data. Default backend stores in the metadata DB.
- For large payloads, write to object storage and pass the path via XCom.
- In Airflow 3, workers cannot access the metadata DB directly — XCom
  goes through the Execution API.

## Source Attribution

Verified against:

- [Airflow official best practices](https://airflow.apache.org/docs/apache-airflow/stable/best-practices.html)
- [Airflow Summit 2024 — DAG Design Patterns](https://airflowsummit.org/slides/2024/98-Exploring-DAG-Design-Patterns-in-Apache-Airflow.pdf)
