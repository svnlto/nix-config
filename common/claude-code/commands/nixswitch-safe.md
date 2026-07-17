---
description: Apply Nix config safely — stage untracked flake files, flake check, then switch
argument-hint: "[--show-trace]"
allowed-tools: Bash(git status:*), Bash(git add:*), Bash(nix flake check:*), Bash(nixswitch:*), Bash(darwin-rebuild:*), Bash(hmswitch:*)
---

# Safe nixswitch

Working tree of the Nix flake:

!`git -C ~/.config/nix status --short`

Apply the Nix configuration safely. Nix flakes ignore untracked files, so a new
file that is not `git add`-ed is silently invisible to the build (see CLAUDE.md
pitfall #2). Steps:

1. If the status above shows untracked (`??`) or modified `.nix`/config files
   in the flake, stage them with `git add` first. Do NOT commit.
2. Run `nix flake check $ARGUMENTS`. If it fails, stop and report the error —
   do not switch on a broken flake.
3. On success, run `nixswitch` (auto-detects host) and report the outcome.

Never run `git commit` or `git push` here — staging only.
