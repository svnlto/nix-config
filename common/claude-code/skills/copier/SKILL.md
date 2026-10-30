---
name: copier
description: >-
  Authoring and consuming Copier project templates (the Python
  scaffolding tool). Use when writing or reviewing a copier.yml / copier.yaml,
  designing question schemas, templating files and filenames with Jinja,
  wiring tasks or migrations, or when generating and UPDATING a project
  from a template (copier copy / update / recopy, .copier-answers.yml,
  conflict resolution, trust). Triggers: copier.yml, copier copy, copier
  update, .copier-answers.yml, _subdirectory, _templates_suffix, _tasks,
  _migrations, _answers_file, scaffold a project, update a project from
  its template. NOT cookiecutter — that is a different, one-shot tool with
  no update path.
metadata:
  version: "1.0.0"
  domain: devops
  triggers: copier, copier.yml, copier.yaml, copier copy, copier update, copier recopy, .copier-answers.yml, project scaffold, project template, template update, template migration, _subdirectory, _templates_suffix, _tasks, _migrations, jinja template, scaffolding tool
  role: specialist
  scope: implementation
  output-format: code
  related-skills: cli-developer, bash-script-generator
---

# Copier

Copier is a Python library + CLI that renders a project from a Jinja
template and — unlike cookiecutter — can **update** an already-generated
project when the template changes, via a three-way merge keyed on an
answers file. This skill covers both authoring templates and consuming
them.

## Core Rules

1. **RTFM — verify, don't recall.** Copier's keyword defaults and flags
   have shifted across majors. Open the doc page before stating a
   setting, type, flag, or default. Doc base:
   `https://copier.readthedocs.io/en/stable/`. Cite the path you used.
1. **Version-aware.** Behavior differs by Copier major (5 → 9+). Check
   the installed version (`copier --version`) and the template's
   `_min_copier_version`. Latest releases are on PyPI — confirm there,
   don't hardcode a number.
1. **The answers file is load-bearing.** `copier update` only works
   because every generated project carries `.copier-answers.yml` with
   `_commit` and `_src_path`. Author it via the `.jinja` wiring; never
   edit it by hand.
1. **Updates need git tags.** A template must be a git repo with tags
   (compared by PEP 440) for `copier update` to have a version to move
   to. An untagged template cannot be updated cleanly.
1. **Unsafe features are opt-in.** Tasks, migrations, and Jinja
   extensions execute code and are disabled unless the consumer passes
   `--trust` (or legacy `--UNSAFE`). Without trust Copier errors (exit
   code 4) — it does not silently skip.

## Decision Routing

| Topic | Reference |
|-------|-----------|
| `copier.yml` settings (`_`-keys), suffix, subdirectory, exclude, answers-file wiring | `references/template-config.md` |
| Question schema — types, choices, when, validator, secret, multiselect | `references/questions.md` |
| `copier copy` / `update` / `recopy`, answers file, versioning, conflict resolution | `references/generate-update.md` |
| `_tasks`, `_migrations`, trust (`--trust`/`--UNSAFE`), user `settings.yml` | `references/tasks-migrations-trust.md` |

## Stale → Current (correct on sight)

| Stale (do not emit) | Current |
|---------------------|---------|
| `_templates_suffix: .tmpl` (Copier 5 default) | default is `.jinja` |
| default conflict writes `.rej` files | default is `--conflict inline` (markers); `.rej` is opt-in (`--conflict rej`) |
| `_exclude` extends the built-in default | `_exclude` **replaces** the default list |
| `_migrations` with `before:` / `after:` keys | dict with `command` / `version` / `when`; `before`/`after` still parse but warn |
| no-trust just skips tasks silently | no-trust is an **error** (exit 4) |
| only `copier.yaml` is valid | both `copier.yml` and `copier.yaml` work |
| `--UNSAFE` is the only trust flag | `--trust` and `--UNSAFE` both work (API: `unsafe=True`) |

## Anti-Patterns

| Anti-pattern | Fix |
|--------------|-----|
| Reciting a setting/flag/default from memory | Open the doc; cite the path |
| Hand-writing `.copier-answers.yml` | Author `{{ _copier_conf.answers_file }}.jinja` with `{{ _copier_answers\|to_nice_yaml -}}` |
| `copier update` on a dirty worktree | Commit/stash first — update applies a patch |
| Shipping an untagged template and expecting updates | Tag releases (PEP 440); update targets the latest tag |
| `_exclude` list that forgets the built-in entries | It replaces, not extends — re-list what you still need |
| Removing/renaming a question without a migration | Add a `_migrations` entry; keep `_answers_file` path stable |
| Assuming tasks ran without `--trust` | They error (exit 4); consumer must trust the source |

## Workflow

1. Identify the mode: **authoring** a template (editing `copier.yml` /
   template body) or **consuming** one (`copy`/`update` in a destination).
1. Route the task through the table above and open the cited reference.
1. For any doc-backed claim (setting, type, flag, default), open the
   current page and confirm before writing.
1. Author minimal and update-safe: stable `_answers_file`, tagged
   releases, migrations for breaking changes. For consuming: clean
   worktree, review merged hunks, re-commit.
1. Report the exact config/commands and the doc paths you relied on.
