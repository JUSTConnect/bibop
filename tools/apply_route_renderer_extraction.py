#!/usr/bin/env python3
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
RENDERER = ROOT / "scripts/field/room_visual_renderer.gd"
BOUNDARY = ROOT / "tools/check_room_visual_renderer_component_boundary.py"
WORKFLOW = ROOT / ".github/workflows/renderer-component-gate.yml"


def replace_func(source: str, name: str, replacement: str) -> str:
    pattern = re.compile(rf"(?ms)^func {re.escape(name)}\s*\(.*?(?=^func |\Z)")
    match = pattern.search(source)
    if not match:
        raise RuntimeError(f"missing function: {name}")
    return source[:match.start()] + replacement.rstrip() + "\n\n" + source[match.end():]


renderer = RENDERER.read_text(encoding="utf-8")
preload = 'const RouteRendererRef = preload("res://scripts/visual/renderer/route_renderer.gd")'
if preload not in renderer:
    renderer = renderer.replace(
        'const ObjectRendererRef = preload("res://scripts/visual/renderer/object_renderer.gd")',
        'const ObjectRendererRef = preload("res://scripts/visual/renderer/object_renderer.gd")\n' + preload,
    )

if "func _draw_route_commands(" not in renderer:
    marker = "func get_wall_routing_mode(object_data: Dictionary) -> String:"
    dispatcher = '''func _draw_route_commands(commands: Array[Dictionary], fallback_profile: Dictionary = {}) -> bool:
\tfor command in commands:
\t\tmatch str(command.get("kind", "")):
\t\t\t"line":
\t\t\t\tdraw_line(
\t\t\t\t\tVector2(command.get("start", Vector2.ZERO)),
\t\t\t\t\tVector2(command.get("end", Vector2.ZERO)),
\t\t\t\t\tColor(command.get("color", Color.WHITE)),
\t\t\t\t\tfloat(command.get("width", 1.0)),
\t\t\t\t\tbool(command.get("antialiased", true))
\t\t\t\t)
\t\t\t"circle":
\t\t\t\tdraw_circle(
\t\t\t\t\tVector2(command.get("center", Vector2.ZERO)),
\t\t\t\t\tfloat(command.get("radius", 1.0)),
\t\t\t\t\tColor(command.get("color", Color.WHITE))
\t\t\t\t)
\t\t\t"wall_cable_segment":
\t\t\t\tvar profile: Dictionary = fallback_profile
\t\t\t\tif command.get("profile", {}) is Dictionary:
\t\t\t\t\tprofile = Dictionary(command.get("profile", {}))
\t\t\t\tdraw_iso_cable_wall_segment(
\t\t\t\t\tVector2(command.get("start", Vector2.ZERO)),
\t\t\t\t\tVector2(command.get("end", Vector2.ZERO)),
\t\t\t\t\tprofile
\t\t\t\t)
\treturn not commands.is_empty()

'''
    if marker not in renderer:
        raise RuntimeError("missing route dispatcher insertion marker")
    renderer = renderer.replace(marker, dispatcher + marker, 1)

replacements = {
    "get_wall_routing_mode": '''func get_wall_routing_mode(object_data: Dictionary) -> String:
\treturn RouteRendererRef.normalize_wall_routing_mode(object_data)''',
    "_get_wall_cable_visual_axis_for_side": '''func _get_wall_cable_visual_axis_for_side(wall_side: String) -> Vector2:
\treturn RouteRendererRef.get_wall_visual_axis_for_side(wall_side)''',
    "_get_wall_cable_face_occluder_delta": '''func _get_wall_cable_face_occluder_delta(face: String) -> Vector2i:
\treturn RouteRendererRef.get_wall_face_occluder_delta(face)''',
    "_is_wall_cable_broken": '''func _is_wall_cable_broken(object_data: Dictionary) -> bool:
\treturn RouteRendererRef.is_broken_route(object_data)''',
    "_draw_wall_cable_broken_overlay_segment": '''func _draw_wall_cable_broken_overlay_segment(start_edge: Vector2, end_edge: Vector2, normal: Vector2, profile: Dictionary) -> void:
\t_draw_route_commands(RouteRendererRef.build_wall_cable_commands(start_edge, end_edge, normal, profile, true), profile)''',
    "_draw_wall_cable_break_overlay": '''func _draw_wall_cable_break_overlay(cell: Vector2i, face: String, profile: Dictionary) -> bool:
\tif not _is_wall_cable_face_visible(cell, face):
\t\treturn false
\tvar segment: Dictionary = _get_wall_cable_face_line_segment(cell, face)
\treturn _draw_route_commands(RouteRendererRef.build_wall_break_overlay_commands(segment, profile), profile)''',
    "_draw_wall_cable_broken_end": '''func _draw_wall_cable_broken_end(anchor: Vector2, away_from_gap: Vector2, normal: Vector2, profile: Dictionary) -> void:
\t_draw_route_commands(RouteRendererRef.build_wall_broken_end_commands(anchor, away_from_gap, normal, profile), profile)''',
    "_get_wall_cable_face_line_segment": '''func _get_wall_cable_face_line_segment(cell: Vector2i, face: String) -> Dictionary:
\treturn RouteRendererRef.build_wall_face_segment(grid_to_iso(cell), get_iso_tile_half_size(), face, 50.0)''',
    "_draw_wall_cable_face_half_segment": '''func _draw_wall_cable_face_half_segment(start: Vector2, end: Vector2, normal: Vector2, routing_mode: String, profile: Dictionary) -> void:
\tif routing_mode.strip_edges().to_lower() == "inner":
\t\treturn
\t_draw_route_commands(RouteRendererRef.build_wall_cable_commands(start, end, normal, profile, false), profile)''',
    "_draw_wall_cable_face_segment": '''func _draw_wall_cable_face_segment(cell: Vector2i, face: String, routing_mode: String, profile: Dictionary, object_data: Dictionary = {}) -> bool:
\tif not _is_wall_cable_face_visible(cell, face):
\t\treturn false
\tif routing_mode.strip_edges().to_lower() == "inner":
\t\treturn true
\tvar segment: Dictionary = _get_wall_cable_face_line_segment(cell, face)
\tvar commands: Array[Dictionary] = RouteRendererRef.build_wall_cable_commands(
\t\tVector2(segment.get("start_edge", Vector2.ZERO)),
\t\tVector2(segment.get("end_edge", Vector2.ZERO)),
\t\tVector2(segment.get("normal", Vector2.UP)),
\t\tprofile,
\t\tRouteRendererRef.is_broken_route(object_data)
\t)
\t_draw_route_commands(commands, profile)
\treturn true''',
    "_get_wall_routed_object_family": '''func _get_wall_routed_object_family(object_data: Dictionary) -> String:
\treturn RouteRendererRef.get_route_family(object_data)''',
    "is_wall_procedural_routed_object": '''func is_wall_procedural_routed_object(object_data: Dictionary) -> bool:
\treturn RouteRendererRef.is_wall_procedural_routed_object(object_data, _get_object_mount_mode(object_data))''',
    "get_wall_routed_height_source_px": '''func get_wall_routed_height_source_px(object_data: Dictionary) -> float:
\treturn RouteRendererRef.get_wall_routed_height_source_px(object_data)''',
    "get_wall_route_segment_points": '''func get_wall_route_segment_points(visual_center: Vector2, object_data: Dictionary, _source_height_px: float) -> Dictionary:
\treturn RouteRendererRef.build_wall_route_segment(visual_center, get_iso_tile_half_size(), normalize_wall_visual_side(object_data))''',
    "draw_wall_procedural_cable": '''func draw_wall_procedural_cable(segment: Dictionary, routing_mode: String) -> bool:
\treturn _draw_route_commands(RouteRendererRef.build_procedural_route_commands("cable", segment, routing_mode))''',
    "draw_wall_procedural_air_duct": '''func draw_wall_procedural_air_duct(segment: Dictionary, routing_mode: String) -> bool:
\treturn _draw_route_commands(RouteRendererRef.build_procedural_route_commands("air_duct", segment, routing_mode))''',
    "draw_wall_procedural_water_pipe": '''func draw_wall_procedural_water_pipe(segment: Dictionary, routing_mode: String) -> bool:
\treturn _draw_route_commands(RouteRendererRef.build_procedural_route_commands("water_pipe", segment, routing_mode))''',
    "get_cable_install_mode": '''func get_cable_install_mode(object_data: Dictionary) -> String:
\treturn RouteRendererRef.normalize_install_mode(object_data)''',
    "get_cable_health_state": '''func get_cable_health_state(object_data: Dictionary) -> String:
\treturn RouteRendererRef.get_health_state(object_data)''',
    "draw_iso_cable_mode_segment": '''func draw_iso_cable_mode_segment(start: Vector2, end: Vector2, profile: Dictionary) -> void:
\t_draw_route_commands(RouteRendererRef.build_floor_mode_segment_commands(start, end, str(profile.get("install_mode", "floor"))))''',
}
for name, replacement in replacements.items():
    renderer = replace_func(renderer, name, replacement)

plan_pattern = re.compile(
    r'(?ms)\tvar shape: String = str\(topology\.get\("shape", "isolated"\)\).*?\n\tvar base_color: Color ='
)
plan_match = plan_pattern.search(renderer)
if not plan_match:
    raise RuntimeError("missing floor topology planning block")
plan_replacement = '''\tvar route_plan: Dictionary = RouteRendererRef.build_floor_topology_plan(topology)
\tvar shape: String = str(route_plan.get("shape", "isolated"))
\tvar object_links: Dictionary = Dictionary(topology.get("object_links", {}))
\tvar has_switch: bool = bool(route_plan.get("has_switch", false))
\tvar valid: bool = bool(route_plan.get("valid", true))
\tvar active_dirs: Array[String] = []
\tfor direction_variant in Array(route_plan.get("active_dirs", [])):
\t\tactive_dirs.append(str(direction_variant))

\tvar base_color: Color ='''
renderer = renderer[:plan_match.start()] + plan_replacement + renderer[plan_match.end():]
RENDERER.write_text(renderer, encoding="utf-8")

boundary = BOUNDARY.read_text(encoding="utf-8")
if 'ROUTE = ROOT / "scripts/visual/renderer/route_renderer.gd"' not in boundary:
    boundary = boundary.replace(
        'OBJECT = ROOT / "scripts/visual/renderer/object_renderer.gd"',
        'OBJECT = ROOT / "scripts/visual/renderer/object_renderer.gd"\nROUTE = ROOT / "scripts/visual/renderer/route_renderer.gd"',
    )
    boundary = boundary.replace(
        'object_renderer = read(OBJECT)',
        'object_renderer = read(OBJECT)\nroute_renderer = read(ROUTE)',
    )
boundary = boundary.replace('if renderer_lines > 6620:', 'if renderer_lines > 6450:')
boundary = boundary.replace('{renderer_lines} > 6620', '{renderer_lines} > 6450')
if 'route_renderer.gd")' not in boundary:
    boundary = boundary.replace(
        '    \'preload("res://scripts/visual/renderer/object_renderer.gd")\',',
        '    \'preload("res://scripts/visual/renderer/object_renderer.gd")\',\n    \'preload("res://scripts/visual/renderer/route_renderer.gd")\',',
    )
route_checks = '''
route_delegates = {
    "get_wall_routing_mode": "RouteRendererRef.normalize_wall_routing_mode",
    "_get_wall_cable_visual_axis_for_side": "RouteRendererRef.get_wall_visual_axis_for_side",
    "_get_wall_cable_face_occluder_delta": "RouteRendererRef.get_wall_face_occluder_delta",
    "_is_wall_cable_broken": "RouteRendererRef.is_broken_route",
    "_get_wall_cable_face_line_segment": "RouteRendererRef.build_wall_face_segment",
    "_draw_wall_cable_broken_overlay_segment": "RouteRendererRef.build_wall_cable_commands",
    "_draw_wall_cable_break_overlay": "RouteRendererRef.build_wall_break_overlay_commands",
    "_draw_wall_cable_broken_end": "RouteRendererRef.build_wall_broken_end_commands",
    "_get_wall_routed_object_family": "RouteRendererRef.get_route_family",
    "is_wall_procedural_routed_object": "RouteRendererRef.is_wall_procedural_routed_object",
    "get_wall_routed_height_source_px": "RouteRendererRef.get_wall_routed_height_source_px",
    "get_wall_route_segment_points": "RouteRendererRef.build_wall_route_segment",
    "draw_wall_procedural_cable": "RouteRendererRef.build_procedural_route_commands",
    "draw_wall_procedural_air_duct": "RouteRendererRef.build_procedural_route_commands",
    "draw_wall_procedural_water_pipe": "RouteRendererRef.build_procedural_route_commands",
    "get_cable_install_mode": "RouteRendererRef.normalize_install_mode",
    "get_cable_health_state": "RouteRendererRef.get_health_state",
    "draw_iso_cable_mode_segment": "RouteRendererRef.build_floor_mode_segment_commands",
    "draw_iso_cable_segment_shape": "RouteRendererRef.build_floor_topology_plan",
}
for name, delegate in route_delegates.items():
    if delegate not in function_body(renderer, name):
        errors.append(f"RoomVisualRenderer {name} must delegate route policy to RouteRenderer")

'''
if 'route_delegates = {' not in boundary:
    boundary = boundary.replace('if "IsoDrawEntryContractRef.less" not in function_body(renderer, "sort_iso_draw_entries"):', route_checks + 'if "IsoDrawEntryContractRef.less" not in function_body(renderer, "sort_iso_draw_entries"):')
boundary = boundary.replace(
    'for component_name, component_source in (("FloorRenderer", floor), ("WallRenderer", wall), ("ObjectRenderer", object_renderer)):',
    'for component_name, component_source in (("FloorRenderer", floor), ("WallRenderer", wall), ("ObjectRenderer", object_renderer), ("RouteRenderer", route_renderer)):',
)
route_contract = '''
for token in (
    "class_name RouteRenderer",
    "static func normalize_install_mode",
    "static func normalize_wall_routing_mode",
    "static func get_route_family",
    "static func build_wall_face_segment",
    "static func build_wall_cable_commands",
    "static func build_floor_mode_segment_commands",
    "static func build_floor_topology_plan",
    "static func build_procedural_route_commands",
):
    if token not in route_renderer:
        errors.append(f"RouteRenderer missing contract: {token}")

'''
if 'RouteRenderer missing contract' not in boundary:
    boundary = boundary.replace('if "[AUTHORED WALL TEST]" in renderer:', route_contract + 'if "[AUTHORED WALL TEST]" in renderer:')
BOUNDARY.write_text(boundary, encoding="utf-8")

workflow = WORKFLOW.read_text(encoding="utf-8")
if "check_route_renderer_contract.gd" not in workflow:
    workflow = workflow.rstrip() + '''
      - name: Check RouteRenderer contract
        run: godot --headless --path . --script res://tools/ci/check_route_renderer_contract.gd
'''
WORKFLOW.write_text(workflow, encoding="utf-8")

print("RouteRenderer extraction applied")
