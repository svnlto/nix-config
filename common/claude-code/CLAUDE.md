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
- Comments: default to none. Add one only on the specific line whose
  "why" is not obvious from the code — never to restate what the code
  does, never one-per-block by habit. Keep it a single line.

## Work Environment

- Git hosting: Azure DevOps (not GitHub)
  — use ADO conventions for PRs, checks, policies
- SSH keys: RSA required (ADO rejects ED25519)
- Personal repos (like nix config): GitHub

## Documentation Editing

- Edit holistically, not piecemeal
- Stay at the requested abstraction level — no cost figures, source
  declarations, status headers, or version headers unless asked
- Thinking-aloud or tradeoff-debating messages: ask before treating
  as a change request
- Team-facing docs (wiki, ADRs, specs): invoke the `doc-standards` skill
  for prose style; the rules above still govern scope

## Workflow

- Prefer editing existing files over creating new ones
- Question abstractions that don't solve existing problems
- Commit only when explicitly asked
- Verify config tokens/keys against docs or source — don't trial-and-error

## Communication Style

Caveman lite, set via `CAVEMAN_DEFAULT_MODE` in `settings.json` — the
plugin hook injects the full ruleset each session. If it is not in
context, fall back to: no filler, no hedging, no pleasantries; keep
articles and full sentences. Code, commits, and PRs: write normally.

## Agent Dispatch

- Prefer a skill-bound agent in `~/.claude/agents/` over `general-purpose`
- No matching agent but a matching skill: name the skill in the prompt
- `general-purpose` only when no skill or specialist covers the task

## Superpowers Output

Specs and plans go to the Obsidian vault, not the project repo:
`$HOME/Documents/obsidian-vault/Work/superpowers/{specs,plans}/`.
Invoke `obsidian:obsidian-markdown` and write Obsidian Flavored Markdown
(frontmatter, wikilinks, callouts).

## Obsidian Vault Access

Vault at `$HOME/Documents/obsidian-vault`. Default to filesystem tools
(Read/Write/Edit/Grep/Glob) for all content — no process spawn, works
when Obsidian is closed. Use the `obsidian-cli` skill only for what the
filesystem can't do: wikilink/alias resolution, backlinks and graph
queries, daily notes, index-aware search, frontmatter/metadata ops.
Prefer the native CLI over the Local REST API / claude-code-mcp.
