#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SERVICE = ROOT / "scripts/visual/canonical_visual_descriptor_service.gd"
WORKFLOW = ROOT / ".github/workflows/renderer-component-gate.yml"
errors: list[str] = []


def read(path: Path) -> str:
    if not path.exists():
        errors.append(f"missing required file: {path.relative_to(ROOT)}")
        return ""
    return path.read_text(encoding="utf-8")


service = read(SERVICE)
workflow = read(WORKFLOW)

required_tokens = (
    "class_name CanonicalVisualDescriptorService",
    "const VisualAssetCatalogRef = preload(\"res://scripts/visual/visual_asset_catalog.gd\")",
    "const VisualStateAssetServiceRef = preload(\"res://scripts/visual/visual_state_asset_service.gd\")",
    "FIELD_VISUAL_FAMILY",
    "FIELD_VISUAL_SURFACE",
    "FIELD_VISUAL_STATE_POLICY",
    "FIELD_VISUAL_VARIANT",
    "FIELD_VISUAL_ASSET_ID",
    "FIELD_RENDER_CONTRACT",
    "FIELD_MOUNT",
    "FIELD_FACING_SIDE",
    "static func build_descriptor",
    "static func normalize_descriptor",
    "static func validate_descriptor",
    "static func resolve_visual_state_policy",
    "VisualStateAssetServiceRef.get_visual_family",
    "VisualStateAssetServiceRef.get_visual_surface",
    "VisualStateAssetServiceRef.resolve_visual_variant",
    "VisualStateAssetServiceRef.resolve_visual_asset_id",
)
for token in required_tokens:
    if token not in service:
        errors.append(f"CanonicalVisualDescriptorService missing token: {token}")

for forbidden in ("RoomVisualRenderer", "GridManager", "MissionManager", "ResourceLoader", "load(", "draw_"):
    if forbidden in service:
        errors.append(f"CanonicalVisualDescriptorService must stay data-only; found forbidden token: {forbidden}")

workflow_tokens = (
    "Check canonical visual descriptor service",
    "python tools/check_canonical_visual_descriptor_service.py",
)
for token in workflow_tokens:
    if token not in workflow:
        errors.append(f"Renderer Component Gate missing canonical descriptor token: {token}")

if errors:
    print("Canonical visual descriptor gate FAILED:")
    for error in errors:
        print(f" - {error}")
    raise SystemExit(1)

print("Canonical visual descriptor gate OK")
