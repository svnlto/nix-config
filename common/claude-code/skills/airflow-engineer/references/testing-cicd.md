# Testing & CI/CD

## Testing Levels

### 1. DAG Validation Tests (Minimum Bar)

Check every DAG for import errors. Faster than starting an Airflow
environment and catches syntax errors, missing dependencies, and
broken imports before deployment.

```python
import pytest
from airflow.models import DagBag

@pytest.fixture(scope="session")
def dagbag():
    return DagBag(include_examples=False)

def test_no_import_errors(dagbag):
    assert not dagbag.import_errors, f"Import errors: {dagbag.import_errors}"

def test_dags_have_tags(dagbag):
    for dag_id, dag in dagbag.dags.items():
        assert dag.tags, f"{dag_id} has no tags"
```

### 2. Unit Tests

Test custom operators, hooks, and sensor logic in isolation. Mock
external dependencies (APIs, databases) — the goal is to verify
your logic, not connectivity.

### 3. Integration Tests with `dag.test()`

Introduced in Airflow 2.5.0. Runs a DAG in a single serialized
process — supports IDE debugging and breakpoints. Replaces the
deprecated `DebugExecutor`.

```python
if __name__ == "__main__":
    from my_dags.example_dag import dag
    dag.test()
```

## CI/CD Pipeline Pattern

Two-phase approach (per Google Cloud Composer):

**Phase 1 — Presubmit (on PR):**

- Run DAG validation tests (import errors, structure)
- Run unit tests for custom operators/hooks
- Lint with `ruff` or `flake8` + `yamllint` for config

**Phase 2 — Sync (on merge to main):**

- Deploy validated DAGs to staging environment
- Optionally run `dag.test()` against staging
- Promote to production (sync to DAG bucket/volume)

**Caveat**: CI environments may have different PyPI packages than
production. A local Airflow dev environment (Docker Compose or
Astro CLI) is recommended for thorough validation before merge.

## Source Attribution

Verified against:

- [Astronomer testing docs](https://www.astronomer.io/docs/learn/testing-airflow)
- [Cloud Composer CI/CD](https://docs.cloud.google.com/composer/docs/composer-3/dag-cicd-github)
