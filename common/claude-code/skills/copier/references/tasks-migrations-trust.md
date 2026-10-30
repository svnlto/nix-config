# Tasks, Migrations & Trust

Docs: <https://copier.readthedocs.io/en/stable/configuring/> and
<https://copier.readthedocs.io/en/stable/settings/>.

Three features execute arbitrary code and are **disabled by default**:
Jinja extensions, `_tasks`, and `_migrations`. Using any of them without
trust raises an error (CLI exit code **4**) — Copier does not silently
skip them.

## `_tasks`

Run in the destination after rendering. Format: `list` of string /
array / dict.

```yaml
_tasks:
  - "git init"                                   # string → runs via shell
  - [invoke, "--search-root={{ _copier_conf.src_path }}", after-copy]  # array → no shell
  - command: ["{{ _copier_python }}", task.py]   # dict form
    when: "{{ _copier_operation == 'copy' }}"
    working_directory: "{{ project_slug }}"
```

- String entries run through the shell; array entries run without a
  shell (no word-splitting/globbing).
- Dict keys: `command` (required), `when` (optional), `working_directory`
  (optional).
- Guard copy-only vs update with `_copier_operation` (`copy`/`update`).

## `_migrations`

Run only on **updates**, not first copy. Current shape is a list of
dicts; keys: `command` (required), `version` (optional, PEP 440), `when`
(optional), `working_directory` (optional).

```yaml
_migrations:
  - version: v2.0.0
    command: "{{ _copier_python }} migrations/v2.py"
    when: "{{ _stage == 'before' }}"
  - version: v2.0.0
    command: rm -f ./legacy.cfg
    when: "{{ _stage == 'after' }}"
```

- No `version` → runs on every update.
- Each migration receives env vars `$STAGE` (`before`/`after`),
  `$VERSION_FROM`, `$VERSION_TO`; in Jinja, `_stage` is available.
- The old `before:` / `after:` dict format still parses but **emits a
  deprecation warning** — use `command` + `version` + `when`.

## Trust

- Enable unsafe features with `--trust` **or** `--UNSAFE` (both valid;
  API uses `unsafe=True`).
- `unsafe` is NOT settable in `copier.yml` — a template cannot
  self-authorize.
- `--skip-tasks` does not imply `--trust`.

## User settings file

Path: `<CONFIG_ROOT>/settings.yml`, where `CONFIG_ROOT` is:

| OS | Path |
|----|------|
| Linux | `$XDG_CONFIG_HOME/copier` (usually `~/.config/copier`) |
| macOS | `~/Library/Application Support/copier` |
| Windows | `%USERPROFILE%\AppData\Local\copier` (old `...\copier\copier` deprecated since v9.6.0) |

Override with env var `COPIER_SETTINGS_PATH`.

### `trust:` allowlist — pre-authorize templates

```yaml
trust:
  - https://github.com/acme/go-service-template.git   # exact match
  - https://github.com/acme/                           # trailing / → prefix match
  - ~/templates/                                       # local prefix
```

Entries ending in `/` are prefix matches; without a trailing `/` they
match exactly. Prefix matching only works for URL paths of unreserved
chars + `/`.

### `defaults:` — override question defaults by name

```yaml
defaults:
  user_name: "Jane Doe"
  user_email: jane@acme.com
```

Well-known `str` vars authors should reuse so consumer defaults apply:
`user_name`, `user_email`, `github_user`, `gitlab_user`.
