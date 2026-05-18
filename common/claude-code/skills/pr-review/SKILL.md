---
name: pr-review
description: "Use when reviewing a pull request or your current branch before merging. Triggers: PR URL (GitHub or Azure DevOps), 'review my branch', 'review this PR', local branch review, pre-merge check. Auto-detects platform from URL or git remote."
---

# PR Review

Single-pass structured review for GitHub and Azure DevOps PRs, or local branch diffs.

## Entry Modes

**URL provided** — parse to detect platform, fetch PR:

- `github.com/.../pull/N` → `gh pr view N --json title,body,commits,files`
- `dev.azure.com/.../pullrequest/N` → `az repos pr show --id N`

**No URL (local branch)** — auto-detect from remote:

```bash
REMOTE=$(git remote get-url origin 2>/dev/null)
# github.com → gh
# dev.azure.com or visualstudio.com → az
# neither → pure git diff
```

Check for existing PR on current branch:

- GitHub: `gh pr view --json number,title,body 2>/dev/null`
- ADO: `az repos pr list --source-branch "$(git branch --show-current)"`

## Context Gathering

Collect ALL of these before starting the review:

```bash
# 1. Base branch
BASE=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@refs/remotes/origin/@@' || echo "main")

# 2. Diff and stats
git diff --stat "$BASE"...HEAD
git diff "$BASE"...HEAD

# 3. Commit log
git log "$BASE"..HEAD --oneline

# 4. PR description (if PR exists)
# gh pr view --json body  OR  az repos pr show --id N

# 5. CLAUDE.md files in the repo
# find . -name "CLAUDE.md" -not -path "./.git/*"
```

Read changed files in full (not just the diff) to understand surrounding context.

## Review Checklist

One thorough pass. For each item, cite `file:line` references.

| Area | Check |
|------|-------|
| **PR alignment** | Changes match PR description / commit messages? Scope creep? |
| **Code quality** | Separation of concerns, error handling, DRY, edge cases |
| **Architecture** | Sound design, integrates cleanly, no unnecessary coupling |
| **Security** | Injection, secrets in code, auth/authz, OWASP top 10 |
| **Testing** | Tests present, cover real behavior, edge cases, no mock abuse |
| **Production readiness** | Migrations, backward compat, no debug code, no TODOs |
| **CLAUDE.md compliance** | Project conventions, commit format, style rules |

## Output Format

```markdown
## PR Review: <title or branch name>
Platform: GitHub | Azure DevOps | Local only
Base: <base> ← <branch> (N commits, M files changed)

### Strengths
[Specific things done well with file:line references]

### Issues

#### Critical (Must Fix)
[Bugs, security issues, data loss, broken functionality]

#### Important (Should Fix)
[Architecture problems, missing error handling, test gaps]

#### Minor (Nice to Have)
[Style, optimization, documentation]

For each issue:
- **file:line** — what's wrong — why it matters — how to fix

### Assessment
**Ready to merge?** [Yes | No | With fixes]
**Reasoning:** 1-2 sentence technical verdict
```

Omit empty severity sections. If no issues found at a severity level, skip it.

## Severity Calibration

- **Critical** — would cause an incident, data loss,
  or security vulnerability in production
- **Important** — won't break prod immediately but will
  cause pain (missing validation, poor error handling,
  test gaps that mask regressions)
- **Minor** — style, naming, micro-optimizations;
  author can ignore

When in doubt, go one level lower. Not everything is Critical.

## Red Flags

- Empty PR description with large diff → flag as Important
- New dependencies without justification → flag
- Secrets, tokens, or credentials in diff → flag as Critical
- Tests deleted without replacement → flag as Important
- Files > 500 lines changed without tests → flag

## Platform Command Reference

### GitHub (`gh`)

```bash
gh pr view N --json title,body,headRefName,baseRefName,commits,files,reviews
gh pr diff N
gh pr checks N
```

### Azure DevOps (`az`)

```bash
az repos pr show --id N \
  --query "{title:title,description:description,
    sourceRefName:sourceRefName,
    targetRefName:targetRefName,status:status}"
az repos pr list --source-branch BRANCH \
  --status active \
  --query "[0].pullRequestId" -o tsv
az repos pr work-items list --id N
az repos pr policy list --id N
```

### Local Only (no platform)

```bash
git diff main...HEAD
git log main..HEAD --oneline
git diff --stat main...HEAD
```
