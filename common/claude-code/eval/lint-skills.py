#!/usr/bin/env python3
"""Tier-1 static lint for Claude Code skills and agents.

Deterministic, no model calls. Validates frontmatter structure so the
`name == directory` bug class (and dangling agent->skill bindings) can never
ship. Wired into pre-commit; safe to run standalone:

    python3 common/claude-code/eval/lint-skills.py

Exits non-zero on any error.
"""

from __future__ import annotations

import sys
from pathlib import Path

# Combined description + when_to_use is truncated at 1536 chars in the skill
# listing (Claude Code docs). We lint the description alone against that cap.
DESC_MAX = 1536

# Agent `skills:` bindings that resolve to upstream repos merged at build time
# (see common/claude-code/default.nix), not the local skills/ tree.
KNOWN_EXTERNAL_SKILLS = {"terraform-skill"}

ROOT = Path(__file__).resolve().parent.parent  # common/claude-code
SKILLS_DIR = ROOT / "skills"
AGENTS_DIR = ROOT / "agents"


def parse_frontmatter(text: str) -> dict[str, str] | None:
    """Return a dict of top-level scalar keys from a leading --- block.

    Handles inline scalars, quoted scalars, and folded/literal blocks
    (`>`, `>-`, `|`). Nested keys (metadata:) are ignored — we only need
    the top-level name/description/skills.
    """
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        return None
    end = next((i for i in range(1, len(lines)) if lines[i].strip() == "---"), None)
    if end is None:
        return None

    body = lines[1:end]
    out: dict[str, str] = {}
    i = 0
    while i < len(body):
        line = body[i]
        # top-level key = no leading whitespace, contains a colon
        if line and not line[0].isspace() and ":" in line:
            key, _, rest = line.partition(":")
            key = key.strip()
            rest = rest.strip()
            if rest in (">", ">-", "|", "|-", ">+", "|+"):
                # folded/literal block: gather more-indented following lines
                collected = []
                i += 1
                while i < len(body) and (body[i] == "" or body[i][0].isspace()):
                    collected.append(body[i].strip())
                    i += 1
                out[key] = " ".join(c for c in collected if c).strip()
                continue
            out[key] = rest.strip().strip('"').strip("'")
        i += 1
    return out


def check(cond: bool, msg: str, errors: list[str]) -> None:
    if not cond:
        errors.append(msg)


def lint_skill(skill_dir: Path, errors: list[str]) -> None:
    md = skill_dir / "SKILL.md"
    label = f"skills/{skill_dir.name}"
    if not md.is_file():
        errors.append(f"{label}: missing SKILL.md")
        return
    fm = parse_frontmatter(md.read_text())
    if fm is None:
        errors.append(f"{label}: missing or unterminated frontmatter")
        return
    name = fm.get("name", "")
    check(bool(name), f"{label}: no `name:` field", errors)
    check(
        name == skill_dir.name,
        f"{label}: name '{name}' != directory '{skill_dir.name}'",
        errors,
    )
    desc = fm.get("description", "")
    check(bool(desc), f"{label}: no `description:` field", errors)
    check(
        len(desc) <= DESC_MAX,
        f"{label}: description {len(desc)} chars > {DESC_MAX} cap",
        errors,
    )


def lint_agent(md: Path, local_skills: set[str], errors: list[str]) -> None:
    label = f"agents/{md.name}"
    stem = md.stem
    fm = parse_frontmatter(md.read_text())
    if fm is None:
        errors.append(f"{label}: missing or unterminated frontmatter")
        return
    name = fm.get("name", "")
    check(bool(name), f"{label}: no `name:` field", errors)
    check(name == stem, f"{label}: name '{name}' != filename '{stem}'", errors)
    desc = fm.get("description", "")
    check(bool(desc), f"{label}: no `description:` field", errors)
    check(
        len(desc) <= DESC_MAX,
        f"{label}: description {len(desc)} chars > {DESC_MAX} cap",
        errors,
    )
    skills_field = fm.get("skills", "")
    check(bool(skills_field), f"{label}: no `skills:` binding", errors)
    for ref in (s.strip() for s in skills_field.split(",") if s.strip()):
        resolves = ref in local_skills or ref in KNOWN_EXTERNAL_SKILLS
        check(
            resolves,
            f"{label}: skills binding '{ref}' resolves to no local skill "
            f"or known-external skill",
            errors,
        )


def main() -> int:
    errors: list[str] = []

    skill_dirs = sorted(p for p in SKILLS_DIR.iterdir() if p.is_dir())
    local_skills = {p.name for p in skill_dirs}
    for d in skill_dirs:
        lint_skill(d, errors)

    for md in sorted(AGENTS_DIR.glob("*.md")):
        lint_agent(md, local_skills, errors)

    n_skills = len(skill_dirs)
    n_agents = len(list(AGENTS_DIR.glob("*.md")))
    if errors:
        print(f"✗ skill/agent lint: {len(errors)} error(s)", file=sys.stderr)
        for e in errors:
            print(f"  - {e}", file=sys.stderr)
        return 1
    print(f"✓ skill/agent lint: {n_skills} skills, {n_agents} agents OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
