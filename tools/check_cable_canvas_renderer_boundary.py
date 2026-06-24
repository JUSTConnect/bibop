#!/usr/bin/env python3
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RENDERER = ROOT / "scripts/field/room_visual_renderer.gd"
COMPONENT = ROOT / "scripts/visual/renderer/cable_canvas_renderer.gd"
CONTRACT = ROOT / "tools/ci/check_cable_canvas_renderer_contract.gd"
WORKFLOW = ROOT / ".github/workflows/renderer-component-gate.yml"
errors: list[str] = []


def read(path: Path) -> str:
    if not path.exists():
        errors.append(f"missing required cable renderer file: {path.relative_to(ROOT)}")
        return ""
    return path.read_text(encoding="utf-8")


def function_body(source: str, name: str) -> str:
    match = re.search(rf"(?ms)^(?:static\s+)?func {re.escape(name)}\s*\(.*?(?=^(?:static\s+)?func |\Z)", source)
    return match.group(0) if match else ""


renderer = read(RENDERER)
component = read(COMPONENT)
contract = read(CONTRACT)
workflow = read(WORKFLOW)

for token in (
    "class_name CableCanvasRenderer", "static func resolve_line_color", "static func build_profile",
    "static func build_layered_polyline_commands", "static func build_hidden_segment_commands",
    "static func build_wall_segment_commands", "static func build_endpoint_cap_commands",
    "static func build_invalid_marker_commands", "static func build_damage_marker_commands",
    "static func build_object_link_commands", "static func build_floor_cable_commands",
    "static func extract_bridge_network_id", "static func should_emit_bridge",
    "static func build_bridge_points", "static func build_bridge_commands",
):
    if token not in component:
        errors.append(f"CableCanvasRenderer missing focused API/token: {token}")

for forbidden in (
    "extends Node", "extends Node2D", "GridManager", "MissionManager", "get_node(", "get_tree(",
    "grid_to_iso(", "ResourceLoader", "Texture2D", "Time", "ThemeDB", "queue_redraw(",
    "draw_line(", "draw_circle(", "draw_colored_polygon(", "draw_rect(", "draw_arc(",
    "draw_polyline(", "draw_texture", "draw_set_transform", "FileAccess", "ResourceSaver",
):
    if forbidden in component:
        errors.append(f"CableCanvasRenderer contains forbidden coordinator/runtime/Canvas dependency: {forbidden}")

if 'preload("res://scripts/visual/renderer/route_renderer.gd")' not in component:
    errors.append("CableCanvasRenderer must reuse RouteRenderer floor segment primitives")
if "RouteRendererRef.build_floor_mode_segment_commands" not in component:
    errors.append("CableCanvasRenderer must delegate floor segment primitives to RouteRenderer")
if 'preload("res://scripts/visual/renderer/cable_canvas_renderer.gd")' not in renderer:
    errors.append("RoomVisualRenderer missing CableCanvasRenderer preload")

segment_body = function_body(renderer, "draw_iso_cable_segment_shape")
for token in (
    "RouteRendererRef.build_floor_topology_plan", "_get_iso_cable_branch_endpoint_for_visual_center",
    "_get_iso_cable_screen_direction", "CableCanvasRendererRef.build_floor_cable_commands", "_draw_route_commands",
):
    if token not in segment_body:
        errors.append(f"RoomVisualRenderer draw_iso_cable_segment_shape missing coordinator/delegate token: {token}")
for forbidden in (
    "draw_line(", "draw_circle(", "draw_arc(", "draw_polyline(",
    "Color(1.0, 0.25, 0.08", "Color(1.0, 0.82, 0.15", "isolated_half_width",
):
    if forbidden in segment_body:
        errors.append(f"RoomVisualRenderer draw_iso_cable_segment_shape retained migrated Canvas/style policy: {forbidden}")

route_dispatcher = function_body(renderer, "_draw_route_commands")
for token in ('"line"', '"circle"', '"polyline"', '"arc"', '"wall_cable_segment"'):
    if token not in route_dispatcher:
        errors.append(f"RoomVisualRenderer route command executor missing command kind: {token}")
for token in ("draw_line(", "draw_circle(", "draw_polyline(", "draw_arc("):
    if token not in route_dispatcher:
        errors.append(f"RoomVisualRenderer route command executor lost Canvas execution token: {token}")

thin_delegates = {
    "_get_line_color_from_id": "CableCanvasRendererRef.resolve_line_color",
    "draw_iso_cable_hidden_segment": "CableCanvasRendererRef.build_hidden_segment_commands",
    "draw_iso_cable_wall_segment": "CableCanvasRendererRef.build_wall_segment_commands",
    "get_cable_bridge_network_id": "CableCanvasRendererRef.extract_bridge_network_id",
    "should_draw_object_cable_bridge": "CableCanvasRendererRef.should_emit_bridge",
    "get_cell_edge_bridge_points": "CableCanvasRendererRef.build_bridge_points",
    "draw_object_cable_bridge": "CableCanvasRendererRef.build_bridge_commands",
    "draw_iso_cable_damage_marker": "CableCanvasRendererRef.build_damage_marker_commands",
    "draw_iso_cable_object_links": "CableCanvasRendererRef.build_object_link_commands",
    "_draw_iso_cable_polyline": "CableCanvasRendererRef.build_layered_polyline_commands",
    "draw_iso_cable_endpoint_cap": "CableCanvasRendererRef.build_endpoint_cap_commands",
    "draw_iso_cable_invalid_marker": "CableCanvasRendererRef.build_invalid_marker_commands",
}
for name, delegate in thin_delegates.items():
    body = function_body(renderer, name)
    if delegate not in body:
        errors.append(f"RoomVisualRenderer {name} must be a thin CableCanvasRenderer delegate")
    for forbidden in ("draw_line(", "draw_circle(", "draw_arc(", "draw_polyline(", "while cursor", "match color_id"):
        if forbidden in body:
            errors.append(f"RoomVisualRenderer {name} retained migrated cable policy: {forbidden}")

bridge_entries = function_body(renderer, "build_iso_cable_object_bridge_draw_entries")
for retained in (
    "_get_runtime_world_objects_for_iso_render", "CableTopologyServiceRef.build_cable_cell_map",
    "is_power_cable_bridge_connectable_object", "CableTopologyServiceRef.get_object_link_cell",
    "should_draw_object_cable_bridge", "IsoDrawEntryContractRef.make_entry",
):
    if retained not in bridge_entries:
        errors.append(f"RoomVisualRenderer lost retained bridge discovery/entry ownership token: {retained}")

renderer_lines = len(renderer.splitlines())
CAP = 5653
if renderer_lines > CAP:
    errors.append(f"RoomVisualRenderer grew beyond cable Canvas extraction cap: {renderer_lines} > {CAP}")

for token in (
    "CableCanvasRenderer contract OK", "_check_isolated_commands", "_check_straight_and_elbow_commands",
    "_check_junction_invalid_and_damage_commands", "_check_hidden_links_and_wall_segments",
    "_check_bridge_policy_and_geometry", "_check_malformed_contexts", "quit(1)",
):
    if token not in contract:
        errors.append(f"CableCanvasRenderer contract missing coverage token: {token}")

for token in (
    "Check CableCanvasRenderer boundary", "python tools/check_cable_canvas_renderer_boundary.py",
    "Check CableCanvasRenderer contract", "res://tools/ci/check_cable_canvas_renderer_contract.gd",
):
    if token not in workflow:
        errors.append(f"Renderer Component Gate missing cable validation token: {token}")

if errors:
    print("CableCanvasRenderer boundary audit FAILED:")
    for error in errors:
        print(" -", error)
    raise SystemExit(1)

print(f"CableCanvasRenderer boundary audit OK ({renderer_lines} RoomVisualRenderer lines)")
