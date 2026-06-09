# Performance Tuning

## Parse-Time Hygiene

DAG files are re-parsed every `min_file_process_interval` seconds
(default 30s). Top-level code runs on every parse cycle.

**Never at module level:**

- Database queries
- Network/API calls
- Heavy computation
- `Variable.get()` or `Connection.get()`

```python
# ❌ Runs on every scheduler parse
my_var = Variable.get("my_key")
conn = Connection.get_connection_from_secrets("my_conn")

# ✅ Deferred to task execution via Jinja
BashOperator(
    task_id="example",
    bash_command="echo {{ var.value.get('my_key') }}",
)

# ✅ Deferred to execution via op_kwargs
PythonOperator(
    task_id="example",
    python_callable=my_func,
    op_kwargs={"key": "{{ var.value.get('my_key') }}"},
)
```

**Variable cache** (experimental): enable with
`use_cache=True` and a TTL to reduce DB lookups when
Variables are unavoidable in DAG definition.

## Scheduler Tuning

| Parameter | Default | Guidance |
|-----------|---------|----------|
| `min_file_process_interval` | 30s | Increase to reduce CPU. Files are re-parsed at this interval minimum. |
| `dag_dir_list_interval` | 300s | How often the DAG directory is scanned for new files. |
| `parsing_processes` | 2 | Number of FileProcessor processes. Scale with CPU cores. |
| DAGs per file | — | One DAG per file. Each file gets one FileProcessor; multi-DAG files limit parallelism. |

## DAG Structure Impact

- **Linear chains** (`A -> B -> C`) have less scheduling delay than
  deeply nested trees. The scheduler resolves dependencies level by
  level.
- Avoid unnecessary cross-dependencies between tasks — they increase
  the dependency graph depth.

## Worker Scaling

Workers accept tasks up to their concurrency limit regardless of
available resources. If tasks are resource-intensive:

- **Reduce `worker_autoscale`** below defaults to prevent OOM kills
  and immediate task failures.
- Use **pools** to limit concurrency for resource-heavy tasks (DB
  connections, GPU, external API rate limits).
- Monitor `scheduler_heartbeat` and `dag_processing.total_parse_time`
  metrics to detect bottlenecks.

## Source Attribution

Verified against:

- [Airflow official best practices](https://airflow.apache.org/docs/apache-airflow/stable/best-practices.html)
- [AWS MWAA tuning guide](https://docs.aws.amazon.com/mwaa/latest/userguide/best-practices-tuning.html)
