#!/usr/bin/env python3
"""Report selected GDScript safety regressions without invoking Godot."""

from __future__ import annotations

import argparse
from dataclasses import dataclass
from pathlib import Path
import re
import subprocess
import sys


SCAN_ROOTS = (Path("scripts/ui"), Path("scripts/game"), Path("scripts/world"), Path("scripts/bipob"))
UI_ROOT = Path("scripts/ui")
SAFE_UI_HELPER = Path("scripts/ui/map_constructor/map_constructor_ui_safe.gd")
ALLOWED_REVIEW_FILES = {
    Path("tools/check_map_constructor_sections.py"),
    Path("tools/check_gdscript_safety_patterns.py"),
    Path("README.md"),
    Path("docs/dev_review_checklist.md"),
}


@dataclass(frozen=True)
class Finding:
    path: Path
    line: int
    level: str
    message: str

    def render(self) -> str:
        return f"{self.path}:{self.line}: {self.level}: {self.message}"


def gdscript_files(root: Path) -> list[Path]:
    return sorted(path for path in root.rglob("*.gd") if path.is_file()) if root.exists() else []


def matching_lines(path: Path, pattern: re.Pattern[str]) -> list[tuple[int, str]]:
    lines = path.read_text(encoding="utf-8").splitlines()
    return [(number, line) for number, line in enumerate(lines, start=1) if pattern.search(line)]


def check_hard_patterns() -> list[Finding]:
    findings: list[Finding] = []
    all_files = [path for root in SCAN_ROOTS for path in gdscript_files(root)]
    hard_patterns = (
        (re.compile(r"PackedString_safe_ui_array"), "generated PackedString_safe_ui_array token"),
        (re.compile(r"_safe_ui_array\([^\n]*\)\.append\s*\("), "append() called on a temporary _safe_ui_array() result"),
        (re.compile(r"\bfind_nearest_(terminal|door|source|target)\b"), "legacy proximity target discovery; use explicit bindings/resolvers"),
        (re.compile(r"\binfer_.*(display|text|label|name).*\("), "legacy text/display inference; use schema data and stable result codes"),
        (re.compile(r"\b(status|result|state)_from_(text|label|message)\b"), "result/status classification from text is forbidden"),
        (re.compile(r"\bgeneric_fallback\b|\bfallback_generic\b"), "generic fallback profile is forbidden; use complete entity contracts"),
    )
    for path in all_files:
        for pattern, message in hard_patterns:
            for line_number, _line in matching_lines(path, pattern):
                findings.append(Finding(path, line_number, "ERROR", message))

    ui_patterns = (
        (re.compile(r"\bDictionary\s*\(\s*row_variant\s*\)"), "unsafe Dictionary(row_variant) cast in UI code; use a guarded UI helper"),
        (re.compile(r"\bArray\s*\(\s*value\s*\)"), "unsafe Array(value) cast in UI code; use a guarded UI helper"),
    )
    for path in gdscript_files(UI_ROOT):
        if path == SAFE_UI_HELPER:
            continue
        for pattern, message in ui_patterns:
            for line_number, _line in matching_lines(path, pattern):
                findings.append(Finding(path, line_number, "ERROR", message))
    return findings


def check_callback_call_guards() -> list[Finding]:
    """Warn about likely unguarded runtime calls inside inline UI callbacks.

    This is intentionally heuristic: callback boundaries are recognized from the
    usual `.connect(func` form and a same-indent closing `)` line. A nearby null
    check plus matching has_method() call is accepted as a guard.
    """
    findings: list[Finding] = []
    call_pattern = re.compile(r"mission_manager_runtime\.call\(\s*[\"']([^\"']+)[\"']")
    for path in gdscript_files(UI_ROOT):
        lines = path.read_text(encoding="utf-8").splitlines()
        callback_indent: int | None = None
        callback_start = 0
        for index, line in enumerate(lines):
            indent = len(line) - len(line.lstrip(" \t"))
            if ".connect(func" in line:
                callback_indent = indent
                callback_start = index
                continue
            if callback_indent is None:
                continue
            if line.strip() == ")" and indent == callback_indent:
                callback_indent = None
                continue
            match = call_pattern.search(line)
            if not match:
                continue
            method = match.group(1)
            nearby_guard = lines[max(callback_start, index - 10) : index]
            has_null_guard = any(
                "mission_manager_runtime == null" in previous
                or "mission_manager_runtime != null" in previous
                for previous in nearby_guard
            )
            has_method_guard = any(
                "mission_manager_runtime.has_method" in previous and method in previous
                for previous in nearby_guard
            )
            if not (has_null_guard and has_method_guard):
                findings.append(
                    Finding(
                        path,
                        index + 1,
                        "WARNING",
                        f'heuristic: mission_manager_runtime.call("{method}") appears in a UI callback without a nearby null check and matching has_method() guard',
                    )
                )
    return findings


def changed_files() -> set[Path]:
    commands = (
        ("git", "diff", "--name-only", "HEAD"),
        ("git", "ls-files", "--others", "--exclude-standard"),
    )
    paths: set[Path] = set()
    for command in commands:
        result = subprocess.run(command, check=True, capture_output=True, text=True)
        paths.update(Path(line) for line in result.stdout.splitlines() if line.strip())
    return paths


def check_forbidden_file_drift() -> list[Finding]:
    findings: list[Finding] = []
    try:
        paths = changed_files()
    except (OSError, subprocess.CalledProcessError) as error:
        return [Finding(Path("."), 0, "ERROR", f"could not inspect git changes: {error}")]
    for path in sorted(paths - ALLOWED_REVIEW_FILES):
        findings.append(Finding(path, 0, "ERROR", "file is outside the PR 19 review-tooling allowlist"))
    return findings


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--check-allowed-files",
        action="store_true",
        help="also fail if current git changes include files outside the focused PR 19 allowlist",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    hard_findings = check_hard_patterns()
    if args.check_allowed_files:
        hard_findings.extend(check_forbidden_file_drift())
    warnings = check_callback_call_guards()

    for finding in hard_findings + warnings:
        print(finding.render())
    if warnings:
        print(f"WARNING: {len(warnings)} heuristic callback guard finding(s); review manually.")
    if hard_findings:
        print(f"FAIL: found {len(hard_findings)} hard safety-pattern issue(s).")
        return 1
    print("OK: no hard GDScript safety-pattern issues found.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
