#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OBJECT_RENDERER = ROOT / "scripts/visual/renderer/object_renderer.gd"
WORKFLOW = ROOT / ".github/workflows/renderer-component-gate.yml"
errors: list[str] = []


def read(path: Path) -> str:
    if not path.exists():
        errors.append(f"missing required file: {path.relative_to(ROOT)}")
        return ""
    return path.read_text(encoding="utf-8")


source = read(OBJECT_RENDERER)
workflow = read(WORKFLOW)

for token in (
    "CanonicalVisualDescriptorServiceRef",
    "static func get_canonical_visual_asset_key",
    "CanonicalVisualDescriptorServiceRef.build_descriptor",
    "CanonicalVisualDescriptorServiceRef.is_valid_descriptor",
    "CanonicalVisualDescriptorServiceRef.FIELD_VISUAL_ASSET_ID",
    "get_canonical_visual_asset_key(object_data)",
):
    if token not in source:
        errors.append(f"missing ObjectRenderer descriptor token: {token}")

if "python tools/check_object_renderer_visual_descriptor_path.py" not in workflow:
    errors.append("Renderer Component Gate does not run ObjectRenderer descriptor path check")

if errors:
    print("ObjectRenderer descriptor path gate FAILED:")
    for error in errors:
        print(f" - {error}")
    raise SystemExit(1)

print("ObjectRenderer descriptor path gate OK")
