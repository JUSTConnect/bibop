#!/usr/bin/env python3
from __future__ import annotations

import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WORKFLOW = ROOT / ".github/workflows/renderer-component-gate.yml"

FINAL_WORKFLOW = '''name: Renderer Component Gate

on:
  pull_request:
  push:
    branches: [main]

jobs:
  renderer-component-gate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.x"
      - uses: chickensoft-games/setup-godot@v2
        with:
          version: 4.6.3
          use-dotnet: false
          include-templates: false
      - name: Check renderer component boundary
        run: python tools/check_room_visual_renderer_component_boundary.py
      - name: Check CableCanvasRenderer boundary
        run: python tools/check_cable_canvas_renderer_boundary.py
      - name: Import project
        run: godot --headless --path . --import
      - name: Check projection contract
        run: godot --headless --path . --script res://tools/ci/check_renderer_projection_contract.gd
      - name: Check FloorRenderer contract
        run: godot --headless --path . --script res://tools/ci/check_floor_renderer_contract.gd
      - name: Check WallRenderer contract
        run: godot --headless --path . --script res://tools/ci/check_wall_renderer_contract.gd
      - name: Check ObjectRenderer policy contract
        run: godot --headless --path . --script res://tools/ci/check_object_renderer_contract.gd
      - name: Check ObjectPrimitiveRenderer contract
        run: godot --headless --path . --script res://tools/ci/check_object_primitive_renderer_contract.gd
      - name: Check ObjectTextureDispatchPolicy contract
        run: godot --headless --path . --script res://tools/ci/check_object_texture_dispatch_policy_contract.gd
      - name: Check DoorCanvasRenderer contract
        run: godot --headless --path . --script res://tools/ci/check_door_canvas_renderer_contract.gd
      - name: Check RouteRenderer contract
        run: godot --headless --path . --script res://tools/ci/check_route_renderer_contract.gd
      - name: Check CableCanvasRenderer contract
        run: godot --headless --path . --script res://tools/ci/check_cable_canvas_renderer_contract.gd
      - name: Check OverlayRenderer contract
        run: godot --headless --path . --script res://tools/ci/check_overlay_renderer_contract.gd
      - name: Check MapConstructorOverlayRenderer contract
        run: godot --headless --path . --script res://tools/ci/check_map_constructor_overlay_renderer_contract.gd
      - name: Check FogRenderer contract
        run: godot --headless --path . --script res://tools/ci/check_fog_renderer_contract.gd
'''


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
    ".github/workflows/tmp-apply-cable-refactor.yml",
    "docs/codex_prompts/.keep_tmp_1158",
    "tools/tmp_apply_cable_refactor.py",
):
    target = ROOT / relative
    if target.is_file():
        target.unlink()
        removed.append(relative)

WORKFLOW.write_text(FINAL_WORKFLOW, encoding="utf-8")

self_path = Path(__file__)
self_path.unlink()
removed.append(str(self_path.relative_to(ROOT)))

print("Cleaned generated and temporary cable-refactor files:")
for relative in removed:
    print(" -", relative)
