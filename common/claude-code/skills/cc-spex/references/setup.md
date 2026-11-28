# cc-spex project setup

Only for a project the user has asked to set up. Run the checks first and
skip every step that is already done.

## Check what exists

```bash
command -v specify        # CLI on PATH
ls .specify .claude/skills 2>/dev/null
jq '.enabledPlugins' .claude/settings.json 2>/dev/null
cat .specify/spex.json 2>/dev/null
```

- `.specify/` present: spec-kit is initialised. Do not re-run `specify init`.
- `spex@cc-rhuss-marketplace` in `enabledPlugins`: the plugin is enabled.
- `.specify/spex.json` present: extensions are chosen.

## 1. specify CLI

`specify` comes from nix (`spec-kit` in `devPackages`, taken from
`nixpkgs-unstable` via the fresh-tools overlay). If it is missing, the
config has not been switched yet; tell the user to run `just switch`. Do not
install it with `uv tool install` or `pipx`, and do not run
`specify self upgrade` — bump it with `just update-fresh`.

The extension scripts also call `git`, `jq` and `yq` (mikefarah yq-go), all
in `devPackages`. `yq` is optional: without it spex-worktrees ignores a custom
`worktrees.base_path` and uses `.claude/worktrees/`.

## 2. Initialise spec-kit

Pass `--non-interactive` and `--integration claude`, or it silently defaults
to Copilot when there is no TTY. `--force` is needed in any existing repo
(`.git` alone counts as non-empty under `--non-interactive`); it merges and
leaves existing files alone. Add `--extension git` when `spex-worktrees`
will be enabled, since it depends on the spec-kit `git` extension:

```bash
specify init --here --force --non-interactive --integration claude --extension git
```

## 3. Enable the spex plugin for this project

The `cc-rhuss-marketplace` marketplace is declared globally in the nix
config's `settings.json`. Enable the plugin per project, never in the global
`enabledPlugins`: its hooks run on every prompt and every tool call, so a
global enable puts them in every session.

Commit this to the project's `.claude/settings.json` (merge with existing
keys). The marketplace entry makes it work for teammates without the nix
config:

```json
{
  "extraKnownMarketplaces": {
    "cc-rhuss-marketplace": {
      "source": { "source": "github", "repo": "rhuss/cc-rhuss-marketplace" }
    }
  },
  "enabledPlugins": {
    "spex@cc-rhuss-marketplace": true
  }
}
```

Claude Code offers to install the plugin when the session next starts in the
project.

## 4. Choose extensions

The user runs `/spex:init` in the session: a three-question prompt for
quality, workflow, and permissions. Recommend `spex-gates` +
`spex-worktrees` to start. The selection persists to `.specify/spex.json`.
