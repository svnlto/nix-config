# Questions / Prompts

Doc: <https://copier.readthedocs.io/en/stable/configuring/>.

Every non-`_` key in `copier.yml` is a question. The shorthand
`key: value` is sugar for `{default: value, type: yaml}`.

## Full shape

```yaml
<name>:
  type: <bool|float|int|json|path|str|yaml>   # default: yaml
  help: <text shown with the prompt>
  default: <value or templated string>
  choices: <list | dict | templated string>
  multiselect: <true|false>
  multiline: <true|false>
  secret: <true|false>
  placeholder: <string, shown only while empty>
  when: <bool or templated string>
  ask: <bool or templated string>
  validator: <jinja template>
  qmark: <custom prompt mark>
```

## Types

Valid `type`: `bool`, `float`, `int`, `json`, `path`, `str`, `yaml`.
**Default is `yaml`** — so a bare `key: value` parses the answer as YAML.
Set `type: str` explicitly when you want a literal string.

## Semantics that bite

- `choices`: a list, or a dict where the **key is shown and the value is
  used**; a `null` value means value == key. Can be built from a
  templated string. When choices are dynamic AND you use a `validator`,
  wrap the validator in `{% raw %}...{% endraw %}`.
- `when`: if it evaluates false the question is skipped and its answer is
  **not recorded**, but its `default` still enters the render context.
  Templated strings are parsed as booleans.
- `validator`: a Jinja template that renders **nothing when valid**, and
  an error message otherwise. Example:

  ```yaml
  cloud_region:
    type: str
    validator: "{% if cloud != 'AWS' %}Requires cloud == AWS{% endif %}"
  ```

- `secret: true`: masks input, **requires a `default`, and the answer is
  NOT saved** to the answers file (so it is re-asked / re-defaulted each
  run). `_secret_questions` is the list-form equivalent.
- `multiselect: true`: answer becomes a list of the declared type.
- `placeholder`: must be a string; no multiline placeholders.
- `ask`: hides the question from the default run unless `--ask` is
  passed.
- Most options are Jinja-templatable, but the rendered value must be a
  string and valid YAML. **Interactive answers are not Jinja-rendered.**

## Example (typed, conditional, validated)

```yaml
project_name:
  type: str
  help: Human-readable service name
project_slug:
  type: str
  default: "{{ project_name | lower | replace(' ', '-') }}"
transport:
  type: str
  help: Primary transport
  choices:
    "REST (net/http + chi)": http
    gRPC: grpc
  default: http
enable_metrics:
  type: bool
  default: true
metrics_port:
  type: int
  default: 9090
  when: "{{ enable_metrics }}"
```
