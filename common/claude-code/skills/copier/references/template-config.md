# Template Config (`copier.yml`)

Doc: <https://copier.readthedocs.io/en/stable/configuring/> and
<https://copier.readthedocs.io/en/stable/creating/>.

A Copier template is a git repo with a `copier.yml` (or `copier.yaml`,
both valid) at its root. Keys starting with `_` are **settings**; every
other key is a **question** (see `questions.md`).

## Settings (`_`-prefixed) and current defaults

| Setting | Type | Default / note |
|---------|------|----------------|
| `_templates_suffix` | str | `.jinja` (Copier ≤5 used `.tmpl`). Only files ending in this suffix are rendered; the suffix is stripped from output. Empty suffix allowed but not default. |
| `_subdirectory` | str | unset → template root is the body. Set it to keep the template's own `copier.yml`/README out of the render. |
| `_exclude` | list[str] | `["copier.yaml","copier.yml","~*","*.py[co]","__pycache__",".git",".DS_Store",".svn"]`. **Defining it REPLACES the default** — re-list what you still need. Becomes `[]` when a real `_subdirectory` is set. |
| `_skip_if_exists` | list[str] | `[]`. Jinja-templatable glob patterns; matched files are never overwritten on copy/update. |
| `_answers_file` | str | `.copier-answers.yml` (relative to destination). Keep it stable across versions or updates lose their baseline. |
| `_envops` | dict | `{"keep_trailing_newline": true}`; otherwise Jinja defaults. Bracket values (`block_start_string: "[%"`) are Copier-5 compat, not defaults. |
| `_jinja_extensions` | list[str] | `[]`. `jinja2_ansible_filters.AnsibleCoreFiltersExtension` is always loaded (gives `to_nice_yaml`, `regex_search`, etc.). Loading extensions is an unsafe feature → needs `--trust`. |
| `_min_copier_version` | str | PEP 440, e.g. `"9.0.0"`. |
| `_secret_questions` | list[str] | `[]`. Alternative to per-question `secret: true`. |
| `_message_before_copy` / `_after_copy` / `_before_update` / `_after_update` | str | Messages shown at each phase (Jinja-templatable). |

`_tasks` and `_migrations` live here too — see
`tasks-migrations-trust.md`.

## Templating `copier.yml` itself

Most setting/question option **values** can be templated with Jinja, but
the value must be a string and valid YAML, and cannot reference a
variable not yet declared. Templating a key (or anything outside a value)
is invalid. Interactive answers are not re-rendered.

## File body and filenames

Jinja renders in both file **contents** and file/dir **names**:

```text
template/
  {{ project_slug }}/
    cmd/{{ project_slug }}/main.go.jinja   # rendered, suffix stripped
    README.md.jinja
    static-logo.png                        # no suffix → copied verbatim
```

- A file is copied unchanged unless it ends with `_templates_suffix`.
- Loop in a name:
  `{% yield item from list_of_items %}{{ item }}{% endyield %}`.
- Escape Jinja with `{% raw %}...{% endraw %}`.

## Wiring the answers file (authoring)

Do **not** write `.copier-answers.yml` as a static file. Add a template
named exactly `{{ _copier_conf.answers_file }}.jinja`:

```jinja
# Changes here will be overwritten by Copier; NEVER EDIT MANUALLY
{{ _copier_answers|to_nice_yaml -}}
```

This renders to the destination's answers file, recording `_commit`,
`_src_path`, and every saved answer — the state `copier update` reads.

## Useful render-context variables

`_copier_conf` (e.g. `_copier_conf.answers_file`, `.src_path`),
`_copier_answers` (saved answers), `_copier_python` (interpreter path),
`_copier_operation` (`copy` or `update`), and in migrations `_stage`
(`before`/`after`).
