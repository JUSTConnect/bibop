#!/usr/bin/env python3
"""Smoke-check wall-routing utility metadata and renderer/validator hooks."""
from pathlib import Path
import re, sys

catalog = Path("scripts/world/world_object_catalog.gd").read_text()
renderer = Path("scripts/field/room_visual_renderer.gd").read_text()
ui = Path("scripts/ui/map_constructor/map_constructor_property_controls.gd").read_text()
validator = Path("scripts/game/routing/wall_routing_validation_service.gd").read_text()
issues = []
for object_id, kind, label in [("external_air_duct", "air_duct", "Air Duct"), ("external_water_pipe", "water_pipe", "Water Pipe")]:
    m = re.search(rf'"{object_id}"\s*:\s*\{{(?P<body>.*?)\n\t"(?:module_external|external_air_duct)"', catalog, re.S)
    if object_id == "external_air_duct":
        m = re.search(rf'"{object_id}"\s*:\s*\{{(?P<body>.*?)\n\t"module_external"', catalog, re.S)
    if not m:
        issues.append(f"missing catalog entry for {object_id}"); continue
    body = m.group('body')
    for token in [f'"route_mode":"inner"', f'"routing_kind":"{kind}"', f'"routing_label":"{label}"', '"visual_family":"wall_routing_utility"', '"wall_routing_visual_enabled":true']:
        if token not in body:
            issues.append(f"{object_id} missing {token}")
    schema = re.search(r'"property_schema"\s*:\s*\[(.*?)\]\}', body, re.S)
    if not schema or not schema.group(1).lstrip().startswith('{"field":"route_mode"'):
        issues.append(f"{object_id} route_mode is not first schema field")
    if '"visible_if":{"field":"route_mode","equals":"inner"}' not in body:
        issues.append(f"{object_id} missing wall_side visible_if")

for token in ["visible_if", "continue", "draw_wall_routing_utility", "draw_inner_wall_route_port", "draw_outer_wall_route_surface", "return draw_wall_routing_utility(cell, object_data, visual_center)"]:
    if token not in (ui + renderer):
        issues.append(f"missing UI/renderer token {token}")
for token in ["Inner routing sides must be different.", "No matching neighboring routing port on %s.", "Neighbor routing kind mismatch", "Neighbor routing mode mismatch", "Neighbor port side mismatch", "_opposite_side"]:
    if token not in validator:
        issues.append(f"missing validator token {token}")

if issues:
    print("Wall routing utility contract failed:")
    for issue in issues: print(f" - {issue}")
    sys.exit(1)
print("Wall routing utility contract checks passed.")
