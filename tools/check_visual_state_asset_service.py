#!/usr/bin/env python3
"""Smoke checks for the generic powered visual state asset resolver."""
from pathlib import Path
import re
import sys

root = Path(__file__).resolve().parents[1]
service = (root / "scripts/visual/visual_state_asset_service.gd").read_text()
renderer = (root / "scripts/field/room_visual_renderer.gd").read_text()
catalog = (root / "scripts/visual/visual_asset_catalog.gd").read_text()

checks = {
    "powered light ON resolves on asset candidate": '"%s_%s_%s_01" % [family, state, surface]' in service and 'VISUAL_STATE_ON := "on"' in service,
    "on light overlay candidate exists": '"%s_%s_%s_pulsar_overlay_01" % [family, state, surface]' in service and '"light_on_wall_pulsar_overlay_01"' in catalog,
    "unpowered uses base state before off": 'return VISUAL_STATE_BASE' in service and 'POWER_OFF_STATES' in service,
    "base fallback can use existing light off asset": re.search(r'"base"\s*:\s*"light_off_wall_01"', catalog) is not None,
    "powered unavailable uses off state": 'UNAVAILABLE_STATES' in service and 'return VISUAL_STATE_OFF' in service,
    "renderer uses generic overlay path": 'draw_visual_state_overlays_for_descriptor' in renderer and 'resolve_overlay_asset_ids' in renderer,
    "renderer no longer calls light overlay drawer": 'draw_light_pulsar_overlay_for_descriptor(object_data, descriptor)' not in renderer,
}

failed = [name for name, ok in checks.items() if not ok]
if failed:
    print("Visual state asset smoke checks failed:")
    for name in failed:
        print(f"- {name}")
    sys.exit(1)
print(f"Visual state asset smoke checks passed: {len(checks)} checks.")
