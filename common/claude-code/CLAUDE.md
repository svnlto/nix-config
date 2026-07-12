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
- Comments: single line only, explaining why not what

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
