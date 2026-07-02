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

for token in (
    "class_name CanonicalVisualDescriptorService",
    "VisualAssetCatalogRef",
    "VisualStateAssetServiceRef",
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
):
    if token not in service:
        errors.append(f"missing service token: {token}")

for token in ("RoomVisualRenderer", "GridManager", "MissionManager", "ResourceLoader", "draw_"):
    if token in service:
        errors.append(f"service must stay data-only; found token: {token}")

if "python tools/check_canonical_visual_descriptor_contract.py" not in workflow:
    errors.append("Renderer Component Gate does not run canonical visual descriptor contract")

if errors:
    print("Canonical visual descriptor contract FAILED:")
    for error in errors:
        print(f" - {error}")
    raise SystemExit(1)

print("Canonical visual descriptor contract OK")
