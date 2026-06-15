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
    "service reads configured visual state families": "get_visual_state_asset_families()" in service and "get_visual_state_family_config" in service,
    "service exposes visual family helper": "static func has_visual_state_family" in service,
    "configured state mapping is validated first": "resolve_configured_state_asset_id" in service and re.search(r"resolve_configured_state_asset_id\(family, candidate_state, surface\).*?if not configured_asset_id\.is_empty\(\):.*?return configured_asset_id.*?_state_candidates", service, re.S) is not None,
    "light base fallback comes from catalog": re.search(r'"base"\s*:\s*"light_off_wall_01"', catalog) is not None and "Compatibility: no light_base_wall asset exists yet" not in service and "family == \"light\" and surface == \"wall\"" not in service,
    "overlay resolution reads configured overlays": "resolve_configured_overlay_asset_ids" in service and re.search(r'"overlays"\s*:\s*\{\s*"on"\s*:\s*\["light_on_wall_pulsar_overlay_01"\]', catalog, re.S) is not None,
    "convention fallback still exists": '"%s_%s_%s_01" % [family, state, surface]' in service and '"%s_%s_%s_pulsar_overlay_01" % [family, state, surface]' in service,
    "unpowered uses base state before off": 'return VISUAL_STATE_BASE' in service and 'POWER_OFF_STATES' in service,
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
