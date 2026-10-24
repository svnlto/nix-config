# Nix config task runner. Recipes run from the repo root.
# `just` with no args lists everything. Tools come from `nix develop`.

set shell := ["bash", "-euc"]

# `just`'s non-interactive bash doesn't inherit the user's nix.conf experimental
# features, so invoke nix with them explicit (mirrors the pre-commit flake-check).
nix := "nix --extra-experimental-features 'nix-command flakes'"

# List available recipes
default:
    @just --list

# --- build / apply ---------------------------------------------------------

# Apply the config for this host (macOS darwin-rebuild, Linux home-manager)
switch:
    #!/usr/bin/env bash
    set -euo pipefail
    case "$(uname -s)" in
      Darwin)
        sudo /run/current-system/sw/bin/darwin-rebuild switch \
          --flake .#"$(scutil --get LocalHostName)" ;;
      Linux)
        case "$(uname -m)" in
          x86_64)        home-manager switch --flake .#minimal-x86 ;;
          aarch64|arm64) home-manager switch --flake .#minimal-arm ;;
          *) echo "unsupported arch: $(uname -m)" >&2; exit 1 ;;
        esac ;;
      *) echo "unsupported OS: $(uname -s)" >&2; exit 1 ;;
    esac

# Validate the flake without building
check:
    {{ nix }} flake check --no-build

# Update all flake inputs
update:
    {{ nix }} flake update

# Advance only the hand-picked fresh-tools channel
update-fresh:
    {{ nix }} flake update nixpkgs-unstable

# Update every input then apply
upgrade: update switch

# --- quality ---------------------------------------------------------------

# Format all Nix files (RFC style)
fmt:
    nixfmt $(git ls-files '*.nix')

# Run every pre-commit hook against all files
pre-commit:
    pre-commit run --all-files

# --- claude skill/agent evals ---------------------------------------------

# Tier 1: static frontmatter lint (deterministic, no model calls)
lint-skills:
    python3 common/claude-code/eval/lint-skills.py

# Tier 2: routing eval (makes `claude` model calls; on demand). e.g. `just route-eval -v`
route-eval *ARGS:
    common/claude-code/eval/routing/run.sh {{ ARGS }}

# Run every deterministic eval (currently Tier 1)
eval: lint-skills

# --- housekeeping ----------------------------------------------------------

# Garbage-collect store generations older than 7 days
clean:
    nix-collect-garbage --delete-older-than 7d

# Deep clean: collect all + optimise the store
clean-deep:
    nix-collect-garbage -d && {{ nix }} store optimise

# --- morty (Zscaler VM) ----------------------------------------------------

# Build the morty-work golden image via Packer from the WORKING TREE (no push
# needed). <operator_pub> is the SSH public key authorized for svenlito. Pass
# force=1 to rebuild over an existing image.
build-work-vm operator_pub force="":
    #!/usr/bin/env bash
    set -euo pipefail
    command -v packer >/dev/null || { echo "packer missing (nixswitch to install)" >&2; exit 1; }
    [ -f "{{ operator_pub }}" ] || { echo "operator pubkey {{ operator_pub }} not found" >&2; exit 1; }
    if tart list --format json | jq -e '.[]|select(.Name=="morty-work")' >/dev/null; then
      [ -n "{{ force }}" ] || { echo "morty-work exists; pass force=1 to rebuild" >&2; exit 1; }
      tart delete morty-work
    fi
    tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
    tar czf "$tmp/nix-config.tgz" --exclude=.git --exclude=result --exclude='result-*' -C "$(git rev-parse --show-toplevel)" .
    cp "{{ operator_pub }}" "$tmp/operator.pub"
    packer init systems/aarch64-darwin/vm/morty.pkr.hcl
    packer build \
      -var "repo_tar=$tmp/nix-config.tgz" -var "operator_pub=$tmp/operator.pub" \
      systems/aarch64-darwin/vm/morty.pkr.hcl

# CoW-clone the daily VM from the golden image. Never clone morty after sign-in.
spawn-morty:
    #!/usr/bin/env bash
    set -euo pipefail
    tart list --format json | jq -e '.[]|select(.Name=="morty-work")' >/dev/null \
      || { echo "no golden image; run build-work-vm" >&2; exit 1; }
    tart list --format json | jq -e '.[]|select(.Name=="morty")' >/dev/null \
      && { echo "morty exists; delete it first to re-clone" >&2; exit 1; } || true
    tart clone morty-work morty
    echo "spawned morty. Run: tart run morty"
