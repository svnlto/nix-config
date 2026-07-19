# Global Preferences

## Languages & Tools

- Primary: Nix, Go, HCL, Bash, Ansible, Java
- JS package manager: pnpm (never npm or yarn)
- Testing: Vitest or Jest for JS/TS projects

## Code Style

- Functional and declarative over imperative
- Immutable data, pure functions, composition
- Explicit over implicit, simple over abstract
- Clarity over cleverness
- YAGNI
- Comments: default to none. Most changed blocks need zero. Add a
  comment only on the specific line whose "why" is not obvious from
  the code itself — never to restate what the code does, and never
  one-per-block by habit. When you do add one, keep it a single line.

## Work Environment

- Git hosting: Azure DevOps (not GitHub)
  — use ADO conventions for PRs, checks, policies
- SSH keys: RSA required (ADO rejects ED25519)
- Personal repos (like nix config): GitHub

## Documentation Editing

- Edit documents holistically, not piecemeal
- Stay at the requested abstraction level
  — no cost figures, source declarations, status headers,
  or version headers unless explicitly asked
- When a message reads as thinking-aloud or debating
  tradeoffs, ask before treating it as a change request

## Workflow

- Read before modifying — never assume file contents
- Prefer editing existing files over creating new ones
- Question abstractions that don't solve existing problems
- Commit only when explicitly asked
- Verify config tokens/keys against docs or source before trying them — don't trial-and-error

## Agent Dispatch

- When dispatching a subagent, if a skill-bound agent in `~/.claude/agents/`
  matches the task, use that `subagent_type` — not `general-purpose`.
- If no custom agent matches but a skill does, name the skill in the
  subagent's prompt so it loads and follows it.
- Reserve `general-purpose` for tasks no skill or specialist covers.

## Communication Style

Use **caveman lite** mode by default (`/caveman lite`). No filler,
no hedging, no pleasantries — but keep articles and full sentences.
Professional and tight. Drop: "sure", "certainly", "happy to",
"just", "really", "basically", "actually", "simply".

Auto-clarity exception: drop to normal prose for security warnings,
irreversible action confirmations, and when user asks to clarify.

Code, commits, and PRs: write normally. "stop caveman" or "normal mode"
reverts to standard output.

## Superpowers Output

Superpowers specs and plans go to the Obsidian vault, not the project repo:

- Specs: `$HOME/Documents/obsidian-vault/Work/superpowers/specs/`
- Plans: `$HOME/Documents/obsidian-vault/Work/superpowers/plans/`

These files live in an Obsidian vault. When writing specs or
plans, invoke the `obsidian:obsidian-markdown` skill and use
Obsidian Flavored Markdown: frontmatter properties (title,
date, tags, aliases), wikilinks to related specs/plans, and
callouts for key decisions or warnings.

## Obsidian Vault Access

Two-tier access to the vault at `$HOME/Documents/obsidian-vault`:

- **Content read/write — use the filesystem tools** (Read, Write,
  Edit, Grep, Glob). Fastest path: no process spawn, works when
  Obsidian is closed, composes with search. This is the default
  for editing note bodies and creating notes.
- **Graph, index, and daily-note operations — use the
  `obsidian-cli` skill** (native `obsidian` CLI; the app must be
  running). Reach for it only when the filesystem can't do the job
  natively:
  - Wikilink/alias resolution (`file=` matches by link, not path)
  - Backlinks and graph queries (`backlinks`, `links`, `orphans`,
    `deadends`, `unresolved`)
  - Daily notes (`daily:append` respects the daily-note config)
  - Index-aware search (`search`, `search:context`, `format=json`)
  - Frontmatter and metadata (`property:set`, `tags`, `aliases`)

Do not route bulk content editing through the CLI — the filesystem
is more efficient. The Local REST API / claude-code-mcp path is
redundant with the native CLI; prefer the CLI.
