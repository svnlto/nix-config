---
name: config-audit
description: >-
  Use when asked to audit configs, check config freshness,
  verify tool configs are up to date, or after upgrading
  nix flake inputs.
---

# Config Audit

Check every tool configured in `common/` against its
**installed** version. Find deprecated keys, broken
references, and notable new options. Offer to fix
what's broken.

## Critical rule

**Audit against the INSTALLED version, not the latest
upstream release.** Packages are pinned via nixpkgs —
the installed version may be significantly older than
the latest GitHub release. Run the version command
FIRST, then check config validity for THAT version.
Use `tool --help`, `tool -c` (default config dump),
or version-specific docs — not latest release notes.

Verify every claim before reporting:

- Run `tool -c` or `tool --help` to confirm whether
  a config key exists
- Check the tool's default config output for the
  installed version
- Do NOT assume a key is removed just because it's
  absent from latest release notes
- GitHub releases are useful for NEW_OPTION
  suggestions only, not for MUST_FIX/SHOULD_FIX

## Tool registry

<!-- markdownlint-disable MD013 -->

| Dir | Version cmd | Dump cmd | Repo |
|-----|-------------|----------|------|
| `ghostty` | `ghostty +version` | `ghostty +show-config --default` | `ghostty-org/ghostty` |
| `lazygit` | `lazygit --version` | `lazygit -c` | `jesseduffield/lazygit` |
| `k9s` | `k9s version` | — | `derailed/k9s` |
| `herdr` | `herdr --version` | — | `ogulcancelik/herdr` |
| `neovim` | `nvim --version` | — | `neovim/neovim` |
| `gh-dash` | `gh extension list` | — | `dlvhdr/gh-dash` |
| `pi` | `pi --version` | — | `earendil-works/pi` |
| `zsh` | `oh-my-posh --version` | — | `JanDeDobbeleer/oh-my-posh` |
| `git` | `git --version` | — | — |
| `ssh` | `ssh -V` | — | — |
| `programs` | — | — | — |

<!-- markdownlint-enable MD013 -->

If a `common/` directory exists that isn't in this
table, audit it anyway — read the nix file, identify
the tool, and check its docs.

## How to audit

Dispatch one `general-purpose` agent per tool, ALL in
a single message for parallel execution.

Each agent prompt:

> Read config files in `{repo_root}/common/{tool}/`
> and check against the INSTALLED version.
>
> IMPORTANT: Run `{version_cmd}` FIRST. All findings
> must be valid for the INSTALLED version, not latest
> upstream. Use `{dump_cmd}` if available to verify
> which keys the installed version recognizes.
> Use `gh api repos/{repo}/releases` ONLY for
> suggesting new options, never for claiming keys
> are removed.
>
> Find: (1) deprecated/removed keys,
> (2) invalid structure, (3) broken references,
> (4) redundant defaults, (5) notable new options.
>
> Categorize: MUST_FIX (broken, verified against
> installed version), SHOULD_FIX (deprecated but
> working), CLEANUP (redundant), NEW_OPTION
> (available in latest upstream).
>
> Report: `[CATEGORY] file:line — description`.
> Concise, no preamble.

For neovim, also check plugin references and API
deprecations. For `programs/`, check Home Manager
module option validity.

## Output format

Compile all agent results into one prioritized table:

| Priority | Tool | File | Issue |
|----------|------|------|-------|
| Must fix | ... | ... | ... |
| Should fix | ... | ... | ... |
| Cleanup | ... | ... | ... |

List new options separately. Then offer to apply
must-fix and should-fix items.

Do NOT modify files during the audit — only after
presenting findings and getting approval.
