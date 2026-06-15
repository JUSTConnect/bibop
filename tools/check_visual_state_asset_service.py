#!/usr/bin/env python3
"""Smoke checks for the generic powered visual state asset resolver."""
from pathlib import Path
import re
import sys

root = Path(__file__).resolve().parents[1]
service = (root / "scripts/visual/visual_state_asset_service.gd").read_text()
renderer = (root / "scripts/field/room_visual_renderer.gd").read_text()
catalog = (root / "scripts/visual/visual_asset_catalog.gd").read_text()
world_catalog = (root / "scripts/world/world_object_catalog.gd").read_text()
firewall_service = root / "scripts/game/firewall/firewall_service.gd"

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
    "terminal family exists in visual state catalog": re.search(r'"terminal"\s*:\s*\{.*?"category"\s*:\s*"objects".*?"surface"\s*:\s*"floor"', catalog, re.S) is not None,
    "terminal states map through catalog family": all(re.search(pattern, catalog, re.S) is not None for pattern in [r'"base"\s*:\s*"terminal_base_floor_01"', r'"off"\s*:\s*"terminal_off_floor_01"', r'"on"\s*:\s*"terminal_on_floor_01"']),
    "terminal overlays map through catalog family": all(re.search(pattern, catalog, re.S) is not None for pattern in [r'"off"\s*:\s*\["pulsar_overlay_terminal_off_floor_01"\]', r'"on"\s*:\s*\["pulsar_overlay_terminal_on_floor_01"\]']),
    "damaged and error are unavailable off states": re.search(r'UNAVAILABLE_STATES.*"damaged".*"error"', service) is not None,
    "terminal aliases use new base asset while legacy id remains": '"terminal": "terminal_base_floor_01"' in catalog and '"terminal_01": "res://assets/visual/isometric/objects/terminal_01.png"' in catalog,
    "terminal resolution is not renderer hardcoded": all(token not in renderer for token in ["terminal_on_floor_01", "terminal_off_floor_01", "terminal_base_floor_01"]),
    "firewall family exists in visual state catalog": re.search(r'"firewall"\s*:\s*\{.*?"category"\s*:\s*"objects".*?"surface"\s*:\s*"floor"', catalog, re.S) is not None,
    "firewall states map through catalog family": all(re.search(pattern, catalog, re.S) is not None for pattern in [r'"base"\s*:\s*"firewall_base_floor_01"', r'"off"\s*:\s*"firewall_off_floor_01"', r'"on"\s*:\s*"firewall_on_floor_01"']),
    "firewall overlays map through catalog family": all(re.search(pattern, catalog, re.S) is not None for pattern in [r'"off"\s*:\s*\["pulsar_overlay_firewall_off_floor_01"\]', r'"on"\s*:\s*\["pulsar_overlay_firewall_on_floor_01"\]']),
    "firewall archetype opts into visual states": re.search(r'"firewall"\s*:\s*\{.*?"visual_family"\s*:\s*"firewall".*?"visual_surface"\s*:\s*"floor".*?"visual_state_policy"\s*:\s*"powered_three_state".*?"power_visual_state_enabled"\s*:\s*true', world_catalog, re.S) is not None,
    "firewall service stub exists": firewall_service.exists() and "class_name FirewallService" in firewall_service.read_text(),
    "firewall resolution is not renderer hardcoded": all(token not in renderer for token in ["firewall_on_floor_01", "firewall_off_floor_01", "firewall_base_floor_01"]),
}

failed = [name for name, ok in checks.items() if not ok]
if failed:
    print("Visual state asset smoke checks failed:")
    for name in failed:
        print(f"- {name}")
    sys.exit(1)
print(f"Visual state asset smoke checks passed: {len(checks)} checks.")
