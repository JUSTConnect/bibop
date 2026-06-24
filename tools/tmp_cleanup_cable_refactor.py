#!/usr/bin/env python3
from __future__ import annotations

import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def changed_paths() -> list[str]:
    output = subprocess.check_output(
        ["git", "diff", "--name-only", "origin/main...HEAD"],
        cwd=ROOT,
        text=True,
    )
    return [line.strip() for line in output.splitlines() if line.strip()]


removed: list[str] = []
for relative in changed_paths():
    if not (relative.endswith(".uid") or relative.endswith(".import")):
        continue
    target = ROOT / relative
    if target.is_file():
        target.unlink()
        removed.append(relative)

for relative in (
    "docs/codex_prompts/.keep_tmp_1158",
    "tools/tmp_apply_cable_refactor.py",
):
    target = ROOT / relative
    if target.is_file():
        target.unlink()
        removed.append(relative)

self_path = Path(__file__)
self_path.unlink()
removed.append(str(self_path.relative_to(ROOT)))

print("Cleaned generated and non-workflow temporary cable-refactor files:")
for relative in removed:
    print(" -", relative)
