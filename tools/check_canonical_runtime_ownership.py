#!/usr/bin/env python3
"""Permanent read-only CI guard for canonical runtime ownership PRs.

Contract:
- Temporary, diagnostic, cleanup, self-patching, and branch-mutating workflows are absent.
- Workflows do not request contents: write.
- Workflows do not commit or push code.
- Workflows do not compare against numeric pull-request IDs.
- Workflows do not invoke source-rewriting commands or fixer scripts.

This guard scans workflow YAML only. It is strictly read-only: it reports
violations and never edits files, commits, pushes, or mutates PR branches.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path
from typing import Iterable

ROOT = Path(__file__).resolve().parents[1]
WORKFLOWS = ROOT / ".github" / "workflows"
WORKFLOW_EXTENSIONS = ("*.yml", "*.yaml")
TEMPORARY_NAME_PATTERN = re.compile(
    r"(?i)(?:^|[-_])(audit|cleanup|diagnose|diagnostic|fix|fixer|patch|rewrite|self[-_]?patch|temp|temporary)(?:[-_]|$)"
)
CANONICAL_RUNTIME_NAME_PATTERN = re.compile(r"(?i)(canonical|runtime|ownership)")
FORBIDDEN_WORKFLOW_PATTERNS: tuple[tuple[str, str], ...] = (
    (r"(?mi)^\s*contents\s*:\s*write\b", "workflow must not request contents: write"),
    (r"\bgit\s+push\b", "workflow must not push code"),
    (r"\bgit\s+commit\b", "workflow must not commit code"),
    (
        r"(?i)\b(?:github\.event\.pull_request\.number|pull_request\.number|pr_number|pull_request_number|issue\.number|number)\b\s*(?:==|!=|>=|<=|>|<|=)\s*['\"]?\d+['\"]?",
        "workflow must not compare against numeric pull-request IDs",
    ),
    (r"(?i)\bsed\s+(?:-[^\n]*i\b|--in-place\b)", "workflow must not rewrite files with sed -i"),
    (r"(?i)\bperl\s+-[^\n\s]*p[^\n\s]*i\b", "workflow must not rewrite files with perl -pi"),
    (r"\bgit\s+apply\b", "workflow must not apply patches"),
    (r"(?m)(?:^|\s)patch(?:\s|$)", "workflow must not invoke patch commands"),
    (r"\.write_text\s*\(", "workflow must not write files with Path.write_text"),
    (r"\.write_bytes\s*\(", "workflow must not write files with Path.write_bytes"),
    (r"(?i)\bopen\s*\([^\n)]*,\s*['\"][waxt]\+?['\"]", "workflow must not open files for writing"),
    (
        r"(?m)(?:>|>>)\s*(?:\./)?(?:\.github/|scripts/|tools/|scenes/|assets/|data/|docs/|project\.godot\b|[^\s]+\.(?:gd|tscn|tres|godot|py|yml|yaml)\b)",
        "workflow must not redirect output into repository source files",
    ),
    (
        r"(?i)\b(?:python3?|uv\s+run\s+python|bash|sh)\b[^\n]*(?:^|[/_\-])(fix|fixer|patch|rewrite|apply|self[-_]?patch)[^\n]*(?:\.py|\.sh)\b",
        "workflow must not invoke fixer/apply scripts that rewrite repository files",
    ),
)


def rel(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def add(errors: list[str], path: Path, line_no: int | None, message: str) -> None:
    location = rel(path) if line_no is None else f"{rel(path)}:{line_no}"
    errors.append(f"{location}: {message}")


def workflow_files() -> Iterable[Path]:
    if not WORKFLOWS.exists():
        return []
    files: list[Path] = []
    for extension in WORKFLOW_EXTENSIONS:
        files.extend(WORKFLOWS.glob(extension))
    return sorted(set(files))


def check_workflow_name(workflow: Path, errors: list[str]) -> None:
    stem = workflow.stem.lower()
    if TEMPORARY_NAME_PATTERN.search(stem) and CANONICAL_RUNTIME_NAME_PATTERN.search(stem):
        add(errors, workflow, None, "temporary/diagnostic/cleanup/self-patching canonical runtime workflow must be removed")


def check_workflow_body(workflow: Path, errors: list[str]) -> None:
    text = workflow.read_text(encoding="utf-8")
    for pattern, message in FORBIDDEN_WORKFLOW_PATTERNS:
        for match in re.finditer(pattern, text):
            line_no = text.count("\n", 0, match.start()) + 1
            add(errors, workflow, line_no, message)


def check_workflows(errors: list[str]) -> None:
    if not WORKFLOWS.exists():
        errors.append(".github/workflows is missing")
        return
    for workflow in workflow_files():
        check_workflow_name(workflow, errors)
        check_workflow_body(workflow, errors)


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
