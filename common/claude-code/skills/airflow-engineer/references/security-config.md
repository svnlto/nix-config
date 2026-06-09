# Security & Configuration

## Secrets Backend Precedence

With an alternative secrets backend enabled:

1. **Secrets backend** — searched first
2. **Environment variables** — `AIRFLOW_CONN_*`, `AIRFLOW_VAR_*`
3. **Metastore database** — searched last

Without a secrets backend: environment variables first, then metastore.

**Read/write inconsistency**: writes always update the metastore, but
reads return the first match from the precedence chain. Duplicate keys
across backends mean you write to one place and read from another.

**Recommendation**: pick one authoritative source per secret type and
don't duplicate keys across backends.

### Backend Implementation

Backends subclass `BaseSecretsBackend` with methods for:

- `get_connection()` — connection lookup
- `get_variable()` — variable lookup
- `get_config()` — configuration lookup

Airflow 3.x adds a worker secrets backend priority layer for
the Execution API architecture.

## Trust Model (Airflow 3.x)

Four tiers, most to least privileged:

| Tier | Access |
|------|--------|
| **Deployment Manager** | Airflow config, infra, backends |
| **DAG Author** | Arbitrary code on workers, DAG Processor, Triggerer |
| **Authenticated UI User** | Web UI, trigger DAGs, view logs |
| **Non-authenticated User** | Nothing (unless explicitly exposed) |

### DAG Author Security

DAG authors can execute arbitrary code — **this is intended behavior,
not a vulnerability**. Mitigations:

- **Require PR reviews** before DAGs reach production
- **Static analysis** to detect suspicious patterns (os.system,
  subprocess, socket, requests to unexpected hosts)
- **Separate environments** for dev/staging/production

### Isolation Boundaries

- **Workers** (Airflow 3.x): strongly isolated from metadata DB.
  Communicate exclusively through Execution API. No DB credentials.
- **DAG File Processor / Triggerer**: weaker isolation. Software
  guards prevent accidental DB access, but deliberate malicious code
  in DAGs can retrieve credentials from parent processes.

## Source Attribution

Verified against:

- [Airflow secrets docs](https://airflow.apache.org/docs/apache-airflow/stable/security/secrets/index.html)
- [Airflow security model](https://airflow.apache.org/docs/apache-airflow/stable/security/security_model.html)
