#!/usr/bin/env python3
"""Static architecture gate for passive air-duct and water-pipe routes."""

from pathlib import Path
import sys

root = Path(__file__).resolve().parents[1]
service = (root / "scripts/game/routing/passive_route_service.gd").read_text()
facade = (root / "scripts/game/cooling/cooling_routing_contour_service.gd").read_text()
catalog = (root / "scripts/world/world_object_catalog.gd").read_text()
mission = (root / "scripts/game/mission_manager.gd").read_text()
inspector = (root / "scripts/ui/map_constructor/map_constructor_inspector.gd").read_text()
validation = (root / "scripts/game/map_constructor_validation_service.gd").read_text()
renderer = (root / "scripts/field/room_visual_renderer.gd").read_text()
airflow = (root / "scripts/game/bipob_airflow_runtime_service.gd").read_text()
workflow = (root / ".github/workflows/passive-route-contract-gate.yml").read_text()

forbidden_catalog_tokens = [
    '"cooling_contour_id":',
    '"cooling_contour_mode":',
    '"cooling_contour_member_ids":',
    '"connected_device_ids":',
    '"test_override":true',
    '"generic_airflow_role":"airflow_path_cell"',
]
forbidden_inspector_tokens = [
    '"Contour mode"',
    '"Contour members"',
    'cooling_contour_member_ids',
    'CoolingRoutingContourServiceRef',
]

checks = [
    ("canonical resolver exists", "class_name PassiveRouteService" in service),
    ("stable route kinds", 'KIND_AIR_DUCT := "air_duct"' in service and 'KIND_WATER_PIPE := "water_pipe"' in service),
    ("exact route-side validation", "CODE_ROUTE_SIDE_DUPLICATE" in service and "CODE_ROUTE_PAIR_TOO_MANY" in service),
    ("physical port compatibility", "CODE_NEIGHBOR_PORT_MISMATCH" in service and "OPPOSITE_SIDE" in service),
    ("deterministic components", "_component_id" in service and "md5_text" in service),
    ("facade delegates only", "PassiveRouteServiceRef.build_topology" in facade and "cooling_contour_mode" not in facade),
    ("catalog exposes three authoring fields", all(f'\"field\":\"{field}\"' in catalog for field in ["mount_side", "route_side_1", "route_side_2"])),
    ("catalog has passive canonical subtypes", '"entity_subtype":"air_duct"' in catalog and '"entity_subtype":"water_pipe"' in catalog),
    ("passive routes have no test override", '"entity_subtype":"air_duct"' in catalog and '"test_override":false' in catalog),
    ("manual/device fields removed from catalog", not any(token in catalog for token in forbidden_catalog_tokens)),
    ("MissionManager stores only route authoring fields", '"mount_side":"string","route_side_1":"string","route_side_2":"string"' in mission),
    ("MissionManager does not expose contour member picker", "cooling_contour_member_ids" not in mission),
    ("inspector uses passive preview", "PassiveRouteServiceRef.build_topology" in inspector and "Normalized route pair" in inspector and "Computed component id" in inspector),
    ("manual contour controls removed", not any(token in inspector for token in forbidden_inspector_tokens)),
    ("validation emits machine codes", "passive_route_%s_%s_%d" in validation and "PassiveRouteServiceRef.collect_issues" in validation),
    ("renderer consumes normalized snapshot", "PassiveRouteServiceRef.get_render_snapshot" in renderer),
    ("airflow recognizes canonical air duct", "PassiveRouteServiceRef.KIND_AIR_DUCT" in airflow),
    ("behavior gate wired", "check_passive_route_service.gd" in workflow),
    ("integration gate wired", "check_passive_route_integration.gd" in workflow),
    ("static gate wired", "python tools/check_cooling_routing_contours.py" in workflow),
]

failed = [name for name, ok in checks if not ok]
for name, ok in checks:
    print(("OK: " if ok else "FAIL: ") + name)
if failed:
    sys.exit(1)
