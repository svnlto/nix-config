# Airflow 3.x Migration

## Breaking Changes

### Worker DB Isolation

Workers communicate exclusively through the **Execution API**.
They no longer receive database credentials.

**Impact**: any task code that imports Airflow DB models directly
will break.

```python
# ❌ Breaks in Airflow 3
from airflow.models import Variable
val = Variable.get("my_key")  # no DB access from worker

# ✅ Use Jinja templates (resolved by scheduler, not worker)
PythonOperator(
    task_id="example",
    op_kwargs={"val": "{{ var.value.get('my_key') }}"},
    python_callable=my_func,
)

# ✅ Use the Airflow Python Client for runtime lookups
from airflow.sdk.api.client import Client
client = Client()
val = client.variables.get("my_key")
```

### Removed Features

| Removed | Replacement | Notes |
|---------|-------------|-------|
| SubDAGs | TaskGroups | Visual grouping, no child DAG run overhead |
| SubDAGs (cross-DAG) | Assets + Data Aware Scheduling | Trigger downstream DAGs on data availability |
| SLAs | Deadline Alerts (3.1, AIP-86) | Per-task and per-DAG deadlines with alerting |
| `DebugExecutor` | `dag.test()` | Single-process execution for testing |
| Direct `airflow.models` imports in tasks | Airflow Python Client or hooks | Workers are DB-isolated |

### Assets and Data Aware Scheduling

Replace time-based and explicit cross-DAG triggers:

```python
from airflow.sdk import Asset, DAG, task

my_dataset = Asset("s3://bucket/output/")

# Producer DAG
with DAG("producer", ...) as dag:
    @task(outlets=[my_dataset])
    def produce():
        ...

# Consumer DAG — triggers when asset is updated
with DAG("consumer", schedule=[my_dataset], ...) as dag:
    @task
    def consume():
        ...
```

### Deadline Alerts (replacing SLAs)

```python
from airflow.sdk import DAG
from datetime import timedelta

with DAG(
    "my_dag",
    dag_run_timeout=timedelta(hours=2),
    ...
) as dag:
    ...
```

## Migration Checklist

1. **Audit task code** for direct `airflow.models` / `airflow.settings`
   imports — replace with Jinja templates or Airflow Python Client
2. **Replace SubDAGs** with TaskGroups (same-DAG grouping) or Assets
   (cross-DAG triggering)
3. **Replace SLA callbacks** with Deadline Alerts
4. **Test with `dag.test()`** — replaces DebugExecutor
5. **Review secrets backends** — Airflow 3 adds worker secrets backend
   priority layer
6. **Verify XCom usage** — XCom now goes through Execution API, not
   direct DB

## Source Attribution

Verified against:

- [Upgrading to Airflow 3](https://airflow.apache.org/docs/apache-airflow/stable/installation/upgrading_to_airflow3.html)
- [AWS migration guide](https://aws.amazon.com/blogs/big-data/best-practices-for-migrating-from-apache-airflow-2-x-to-apache-airflow-3-x-on-amazon-mwaa/)
