# VRL — Vector Remap Language

VRL is the expression-oriented language used by Vector's
`remap` transform to parse, enrich, filter, and reshape
events. It is strongly typed and fail-safe: the compiler
rejects a program that could error at runtime unless every
fallible operation is explicitly handled.

The current event is the path `.`. Field paths (`.foo`,
`.a.b`, `.list[0]`) read and write into it. Variables use
bare names (`x = ...`). `|=` merges an object into a target.

## Parsing

Each `parse_*` function is fallible — note the `!` suffix
(see Error handling).

`parse_json` — decode a JSON string into structured data:

```vrl
. = parse_json!(.message)
```

`parse_regex` — extract named capture groups with a regex
literal (`r'...'`):

```vrl
. |= parse_regex!(.message, r'^(?P<method>\w+) (?P<path>\S+)$')
```

`parse_grok` — parse unstructured text with a Grok pattern:

```vrl
. |= parse_grok!(
  .message,
  "%{TIMESTAMP_ISO8601:timestamp} %{LOGLEVEL:level} %{GREEDYDATA:message}"
)
```

`parse_syslog` — parse an RFC 3164/5424 syslog line into
fields (`appname`, `severity`, `timestamp`, ...):

```vrl
. |= parse_syslog!(.message)
```

For multiple candidate formats, `parse_groks!` tries a list
of patterns in order until one matches.

## Enrichment

Enrichment tables (declared under `enrichment_tables` in
Vector config — file, geoip, mmdb, etc.) are queried from
VRL. The condition object must be statically defined so
Vector can build indices at boot.

`get_enrichment_table_record` returns exactly one row and
errors if zero or many match:

```vrl
row = get_enrichment_table_record!("users", {"id": .user_id})
.user_name = row.name
```

`find_enrichment_table_records` returns an array of all
matching rows and supports `select`, `case_sensitive`, and
`wildcard` options:

```vrl
.matches = find_enrichment_table_records!(
  "users",
  {"surname": .surname},
  case_sensitive: false
)
```

Exact and wildcard matches use indices; date-range searches
scan sequentially and are expensive.

## Filtering & reshaping

Assign to a path to add or overwrite a field; assign to `.`
to replace the whole event:

```vrl
.env = "production"
.level = downcase(.level)
```

`del` removes a static path and returns the deleted value,
so it doubles as a rename:

```vrl
del(.debug_field)          # drop a field
.new = del(.old)           # rename old -> new
```

Pass `compact: true` to `del` to cascade-remove parent
objects/arrays left empty. For dynamic (computed) paths use
`remove` instead of `del`.

Restructure by building a fresh object and merging or
replacing:

```vrl
. = {
  "ts":   .timestamp,
  "svc":  .kubernetes.container_name,
  "msg":  .message,
}
```

## PII redaction

Redacting personally identifiable information before it leaves
the network is a primary aggregator job (GDPR/PCI/HIPAA). VRL's
`redact` function masks matches in a string or across a whole
object. Its `filters` and `redactor` arguments must be **static
expressions** — literals, not computed values.

`filters` accepts named filters (`us_social_security_number`),
regex literals, or `pattern` objects. Applied to the whole event,
it walks every string field:

```vrl
. = redact(., filters: [
  "us_social_security_number",
  r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b',   # email
  r'\b(?:\d[ -]*?){13,16}\b',                              # card PAN
])
```

`redactor` sets the replacement. Default is `full` (`[REDACTED]`).
Use `text` for a custom marker, or `sha2`/`sha3` to
**pseudonymize** — hash the value so events stay correlatable
without exposing it (e.g. group by a user across logs while the
raw id never lands in storage):

```vrl
# mask a bearer token with a fixed marker
.headers.authorization = redact(
  .headers.authorization,
  filters: [r'Bearer\s+[A-Za-z0-9._-]+'],
  redactor: {"type": "text", "replacement": "Bearer [REDACTED]"}
)

# pseudonymize the user id (stable hash, base64)
.user_id = redact(
  .user_id,
  filters: [r'.+'],
  redactor: {"type": "sha2", "variant": "SHA-256", "encoding": "base64"}
)
```

Redact as early as correctness allows — ideally at the aggregator
before any sink — so raw PII never reaches a buffer, retry queue,
or disk. Pair `redact` with `del` to drop fields that should never
be collected at all, rather than masking them.

## Error handling

This is VRL's core concept. Operations that can fail are
**fallible**; the compiler forces you to handle them one of
three ways.

**1. `!` — abort on error.** Assert the operation succeeds;
if it fails the whole event is dropped and the error is
logged. Use when failure means the event is unusable:

```vrl
. = parse_json!(.message)
```

**2. Capture the error.** Assign to a `(value, err)` pair
and branch on it. `err` is `null` on success:

```vrl
parsed, err = parse_json(.message)
if err != null {
  .parse_error = err
} else {
  . = parsed
}
```

**3. `??` — coalesce.** Fall back to a default value when
the left side errors:

```vrl
. = parse_json(.message) ?? {}
```

An infallible call written with `!` (or vice versa) is a
compile error — match the suffix to whether the operation
can actually fail.

`abort` stops processing the current event immediately and
drops it. Its message expression must itself be infallible,
so coalesce if needed:

```vrl
if !exists(.message) {
  abort "no message field"
}

.level = to_syslog_level(.severity) ?? "info"
```

## Testing VRL

**REPL — interactive.** Run `vector vrl` with no arguments
to open a REPL and evaluate snippets against a mutable `.`:

```bash
vector vrl
```

**One-shot.** Pass a program with `-p`/`--program` and an
event on stdin (or `-i`/`--input` for a newline-delimited
JSON file); `--print-object` prints the modified event
instead of the final expression:

```bash
echo '{"message":"{\"a\":1}"}' \
  | vector vrl --print-object -p '. = parse_json!(.message)'
```

**Unit tests.** Declare `tests` in the Vector config to
feed inputs into a named transform and assert on outputs
with VRL (`assert_eq!`), then run `vector test config.yaml`:

```yaml
tests:
  - name: "adds environment tag"
    inputs:
      - insert_at: "add_env"
        type: "vrl"
        source: '. = {"message": "hi"}'
    outputs:
      - extract_from: "add_env"
        conditions:
          - type: "vrl"
            source: 'assert_eq!(.env, "production")'
```

For exact signatures and the full function list, verify
against Vector docs (see SKILL.md's Verify First note).
