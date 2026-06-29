#!/usr/bin/env python3
"""Permanent read-only CI guard for canonical runtime ownership PRs.

Contract:
- Temporary diagnostic, cleanup, self-patching, and branch-mutating workflows are absent.
- Workflows do not request contents: write.
- Workflows do not commit or push code.
- Workflows do not depend on numeric PR IDs.
- Workflows do not invoke source-rewriting fixer scripts.

This guard is read-only: it reports violations and never edits files, commits, pushes,
or mutates PR branches.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WORKFLOWS = ROOT / ".github" / "workflows"
TEMP_WORKFLOWS = {
    "audit-canonical-runtime.yml",
    "cleanup-canonical-runtime-temp.yml",
    "diagnose-canonical-ownership.yml",
    "diagnose-canonical-runtime-final.yml",
    "patch-task-validation-code.yml",
    "run-canonical-power-cleanup.yml",
}
FORBIDDEN_WORKFLOW_PATTERNS = {
    r"(?mi)^\s*contents\s*:\s*write\b": "workflow must not request contents: write",
    r"\bgit\s+push\b": "workflow must not push code",
    r"\bgit\s+commit\b": "workflow must not commit code",
    r"\b1203\b": "workflow must not depend on numeric PR IDs",
    r"\b1204\b": "workflow must not depend on numeric PR IDs",
    r"(?i)\b(fix|fixer|patch|rewrite|self[-_ ]?patch)\b.*\b(\.gd|scripts/|res://|src/)": "workflow must not invoke source-rewriting fixers",
}


def rel(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def add(errors: list[str], path: Path, line_no: int | None, message: str) -> None:
    location = rel(path) if line_no is None else f"{rel(path)}:{line_no}"
    errors.append(f"{location}: {message}")


def check_workflows(errors: list[str]) -> None:
    if not WORKFLOWS.exists():
        errors.append(".github/workflows is missing")
        return
    for workflow in sorted(WORKFLOWS.glob("*.yml")):
        text = workflow.read_text(encoding="utf-8")
        if workflow.name in TEMP_WORKFLOWS:
            add(errors, workflow, None, "temporary canonical runtime workflow must be removed")
        for pattern, message in FORBIDDEN_WORKFLOW_PATTERNS.items():
            for match in re.finditer(pattern, text):
                line_no = text.count("\n", 0, match.start()) + 1
                add(errors, workflow, line_no, message)


def main() -> int:
    errors: list[str] = []
    check_workflows(errors)
    if errors:
        print("Canonical runtime CI ownership violations:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1
    print("OK: canonical runtime CI ownership contract holds")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
