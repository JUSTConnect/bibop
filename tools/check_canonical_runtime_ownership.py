#!/usr/bin/env python3
"""Permanent read-only gate for canonical runtime ownership.

Contract:
- CI workflows remain read-only: no contents: write, git commit, git push, or PR-number special cases.
- Temporary diagnostic/self-patching canonical runtime workflows are absent.
- Runtime code must not write legacy power provenance or cable-reel alias fields.
  Compatibility reads may remain until all callers migrate and tests cover the canonical path.
- The gate reports violations only; it never edits files or mutates branches.
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
RUNTIME_GLOBS = ["scripts/**/*.gd"]
LEGACY_RUNTIME_WRITE_KEYS = {
    "power_state",
    "power_received",
    "power_source_id",
    "physical_connection_source_id",
    "cable_power_connected",
    "external_power_reel_id",
    "external_power_end_index",
    "connected_reel_id",
    "connected_reel_end_index",
    "plugged_cable_end",
}
# Constructor/default catalog normalization is compatibility setup, not runtime mutation.
WRITE_ALLOWLIST = {
    "scripts/game/mission_manager.gd": {6168, 6204},
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
        forbidden_patterns = {
            r"(?mi)^\s*contents\s*:\s*write\b": "workflow must not request contents: write",
            r"\bgit\s+push\b": "workflow must not push code",
            r"\bgit\s+commit\b": "workflow must not commit code",
            r"\b1203\b": "workflow must not depend on numeric PR IDs",
        }
        for pattern, message in forbidden_patterns.items():
            for match in re.finditer(pattern, text):
                line_no = text.count("\n", 0, match.start()) + 1
                add(errors, workflow, line_no, message)


def check_runtime_writes(errors: list[str]) -> None:
    assignment = re.compile(r"\[\s*['\"](?P<key>[^'\"]+)['\"]\s*\]\s*=")
    for glob in RUNTIME_GLOBS:
        for path in sorted(ROOT.glob(glob)):
            text = path.read_text(encoding="utf-8")
            allowed_lines = WRITE_ALLOWLIST.get(rel(path), set())
            for line_no, line in enumerate(text.splitlines(), start=1):
                match = assignment.search(line)
                if not match:
                    continue
                key = match.group("key")
                if key in LEGACY_RUNTIME_WRITE_KEYS and line_no not in allowed_lines:
                    add(errors, path, line_no, f"runtime must not write legacy alias field {key!r}")


def main() -> int:
    errors: list[str] = []
    check_workflows(errors)
    check_runtime_writes(errors)
    if errors:
        print("Canonical runtime ownership violations:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1
    print("OK: canonical runtime ownership contract holds")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
