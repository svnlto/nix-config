# Pipeline Configuration

A Vector pipeline is a directed graph of components. Every
component has a unique id and a `type`, and downstream
components declare their upstreams by id via the `inputs`
field. There is no separate wiring section — the graph is
defined implicitly by those `inputs` lists.

## Topology model

Three component kinds make up every pipeline:

- **`sources`** — ingest events (files, sockets, agents,
  APIs). They have no `inputs`; they are the graph roots.
- **`transforms`** — parse, filter, route, aggregate, or
  reshape events. Each lists the ids feeding it in `inputs`.
- **`sinks`** — emit events to a destination (console,
  object store, log/metric backend). Each also lists
  `inputs`.

An `inputs` entry is the id of a source or transform. Fan-in
(several ids in one `inputs`) and fan-out (one id referenced
by several components) both work. A minimal end-to-end
pipeline — source, `remap` transform, console sink:

```yaml
sources:
  in:
    type: demo_logs
    format: json
    interval: 1

transforms:
  parse:
    type: remap
    inputs:
      - in
    source: |
      . = parse_json!(.message)

sinks:
  out:
    type: console
    inputs:
      - parse
    encoding:
      codec: json
```

Some transforms expose named output streams addressed as
`<id>.<output>`. `route` names each branch, and any
transform that can drop events exposes a `.dropped` output
when `reroute_dropped: true`:

```yaml
sinks:
  dead_letter:
    type: console
    inputs:
      - parse.dropped   # events remap dropped via abort
    encoding:
      codec: json
```

## Core transforms

- **`remap`** — transform events with VRL (the workhorse).
- **`filter`** — pass only events matching a VRL condition.
- **`route`** — split one stream into named branches by
  VRL conditions.
- **`reduce`** — aggregate multiple events into one (e.g.
  merge multi-line stack traces).
- **`throttle`** — rate-limit events per time window.
- **`sample`** — keep a deterministic fraction of events.

`remap` runs a VRL program supplied inline via `source`, or
from disk via `file` / `files`. Set `drop_on_abort: true`
(with optional `reroute_dropped: true`) to send aborted
events to the `.dropped` output. VRL syntax lives in
`references/vrl.md` — not repeated here.

```yaml
transforms:
  clean:
    type: remap
    inputs:
      - in
    drop_on_abort: true
    reroute_dropped: true
    source: |
      . = parse_json!(.message)
      .level = downcase!(.level)
```

`route` defines a map of branch name to VRL condition; each
matching event is copied to every branch whose condition is
true. Reference a branch downstream as `<route-id>.<branch>`:

```yaml
transforms:
  by_level:
    type: route
    inputs:
      - clean
    route:
      errors: '.level == "error"'
      other: '.level != "error"'

sinks:
  errors_out:
    type: console
    inputs:
      - by_level.errors
    encoding:
      codec: json
  other_out:
    type: console
    inputs:
      - by_level.other
    encoding:
      codec: json
```

`filter` takes a single VRL `condition`; `throttle` takes
`threshold` and `window_secs`; `sample` takes `rate` (keeps
`1/rate` of events); `reduce` takes `group_by`,
`merge_strategies`, and `starts_when`/`ends_when`.

## Config layout

Vector accepts YAML, TOML, and JSON — pick one per project
for readability (YAML shown throughout here). The three
formats are interchangeable and can be mixed.

- **Single file** — `vector --config /etc/vector/vector.yaml`.
  The default path when none is given is
  `/etc/vector/vector.yaml`.
- **Multiple files** — pass `--config` more than once, or
  point `--config-dir <dir>` at a directory. Vector merges
  every config file in the directory into one topology, so
  the id namespace is global across files (ids must be
  unique everywhere). Split by concern (sources.yaml,
  transforms.yaml, sinks.yaml) to keep files small.
- **Format flags** — `--config-yaml`, `--config-toml`,
  `--config-json` force a parser when the extension is
  ambiguous.

Any option value supports environment-variable
interpolation with `${VAR}` (or bare `$VAR`):

```yaml
sinks:
  out:
    type: console
    inputs:
      - parse
    encoding:
      # Default when unset or empty.
      codec: "${CODEC:-json}"
```

Defaulting and requiring follow shell-like rules: `:-`
supplies a default when the variable is unset or empty (`-`
only when unset); `:?` errors out when unset or empty (`?`
only when unset), causing Vector to exit with the given
message.

## Validation

`vector validate <config>` parses and type-checks the
topology, verifies component options, and runs sink health
checks before exiting — run it in CI on every config:

```bash
vector validate /etc/vector/vector.yaml
```

Useful flags: `--no-environment` skips health/connectivity
checks (offline validation), and `--deny-warnings` fails on
warnings. With no path it validates the default config path.

`vector test <config>` runs config-level unit tests declared
under a top-level `tests` key. Each test inserts synthetic
events at a named transform (`insert_at`) and asserts on the
output of a named component (`extract_from`) using VRL
conditions:

```yaml
tests:
  - name: "drops debug logs"
    inputs:
      - type: log
        insert_at: clean
        log_fields:
          message: '{"level":"DEBUG","msg":"noise"}'
    outputs:
      - extract_from: clean
        conditions:
          - type: vrl
            source: 'assert_eq!(.level, "debug")'
```

Use `no_outputs_from: [<id>]` to assert an event is dropped
(e.g. filtered out) rather than emitted. Test-authoring VRL
(`assert!`, `assert_eq!`) is covered in `references/vrl.md`.
