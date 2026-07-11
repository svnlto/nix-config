---
name: session
description: Use at the start or end of a work session tied to the Obsidian vault. Triggers for loading context — "resume", "catch me up", "what was I working on". Triggers for saving a session — "compress", "save session", "wrap up", "I'm done for today". Works from any project directory.
---

# Session — Load and Save Vault Context

Load context at the start of a session, or save a searchable session log at
the end. Both operate on the Obsidian vault at an absolute path, so this skill
works from any project's working directory.

**Vault root:** `$HOME/Documents/obsidian-vault`

## Which mode?

Pick the mode from the user's trigger, then follow only that section.

| User says | Mode |
|-----------|------|
| "resume", "catch me up", "what was I working on" | **Load** |
| "compress", "save session", "wrap up", "done for today" | **Save** |

## Load — start of session

1. Read `$HOME/Documents/obsidian-vault/CLAUDE.md`.
2. Interpret optional arguments:
   - No args → load the last 3 session logs
   - Number (e.g. `10`) → load that many session logs
   - Keyword (e.g. `auth`) → load last 3 sessions + search the vault for the keyword
   - Number + keyword (e.g. `5 jira`) → load that many sessions, then search
3. List `$HOME/Documents/obsidian-vault/Session-Logs/` and read the most recent
   log(s) per the args. Read the **Quick Reference** section first — it is
   token-efficient. Only read the full **Raw Session Log** if more detail is needed.
4. If a keyword was provided, also `grep` the vault for that term.
5. Summarise concisely — this is orientation, not a full briefing:
   - Current projects and their status
   - Recent decisions
   - Pending tasks
   - Anything matching the keyword, if provided
6. Ask: "What are you working on today?"

## Save — end of session

1. Ask which categories to preserve (multi-select):
   - Key learnings
   - Solutions & fixes
   - Decisions made
   - Files modified
   - Setup & config
   - Pending tasks
   - Errors & workarounds
2. Determine the domain from context (`work` or `homelab`) and a short session
   slug (e.g. `kaas-argocd-fix`).
3. Write the log to
   `$HOME/Documents/obsidian-vault/Session-Logs/YYYY-MM-DD-<slug>.md`:

   ```markdown
   ---
   type: session
   date: YYYY-MM-DD
   domain: work|homelab
   project: <project-name>
   tags: []
   ---

   # Session: YYYY-MM-DD - <slug>

   ## Quick Reference
   **Topics:**
   **Projects:**
   **Outcome:**

   ## Decisions Made


   ## Key Learnings


   ## Pending Tasks
   - [ ]

   ---

   ## Raw Session Log
   [Full conversation summary for searchability]
   ```

4. Confirm the file was written and show the path.

## Notes

- **Quick Reference** is designed for fast scanning by the Load mode — keep it tight.
- **Raw Session Log** is a prose summary, not a transcript.
- Keep `domain` frontmatter accurate — Load filters by it.
- The date is available in the session context; do not shell out for it.
- Permanent, cross-session learnings belong in the vault `CLAUDE.md`, not a log.
