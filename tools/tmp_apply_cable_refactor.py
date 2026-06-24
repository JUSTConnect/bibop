#!/usr/bin/env python3
from __future__ import annotations

import re
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RENDERER = ROOT / "scripts/field/room_visual_renderer.gd"
BOUNDARY = ROOT / "tools/check_room_visual_renderer_component_boundary.py"
WORKFLOW = ROOT / ".github/workflows/renderer-component-gate.yml"


def replace_function(source: str, name: str, replacement: str) -> str:
    pattern = re.compile(rf"(?ms)^func {re.escape(name)}\s*\(.*?(?=^func |\Z)")
    matches = list(pattern.finditer(source))
    if len(matches) != 1:
        raise RuntimeError(f"expected one function {name}, found {len(matches)}")
    return source[: matches[0].start()] + replacement.rstrip() + "\n\n" + source[matches[0].end() :]


renderer = RENDERER.read_text(encoding="utf-8")
preload_anchor = 'const RouteRendererRef = preload("res://scripts/visual/renderer/route_renderer.gd")\n'
preload_line = 'const CableCanvasRendererRef = preload("res://scripts/visual/renderer/cable_canvas_renderer.gd")\n'
if preload_line not in renderer:
    if preload_anchor not in renderer:
        raise RuntimeError("RouteRenderer preload anchor missing")
    renderer = renderer.replace(preload_anchor, preload_anchor + preload_line, 1)

renderer = replace_function(renderer, "_draw_route_commands", '''func _draw_route_commands(commands: Array[Dictionary], fallback_profile: Dictionary = {}) -> bool:
	for command in commands:
		match str(command.get("kind", "")):
			"line":
				var start_value: Variant = command.get("start", null)
				var end_value: Variant = command.get("end", null)
				var color_value: Variant = command.get("color", null)
				if start_value is Vector2 and end_value is Vector2 and color_value is Color:
					draw_line(Vector2(start_value), Vector2(end_value), Color(color_value), float(command.get("width", 1.0)), bool(command.get("antialiased", true)))
			"circle":
				var center_value: Variant = command.get("center", null)
				var circle_color_value: Variant = command.get("color", null)
				if center_value is Vector2 and circle_color_value is Color:
					draw_circle(Vector2(center_value), float(command.get("radius", 1.0)), Color(circle_color_value))
			"polyline":
				var raw_points: Variant = command.get("points", PackedVector2Array())
				var polyline_color_value: Variant = command.get("color", null)
				var points := PackedVector2Array()
				if raw_points is PackedVector2Array:
					points = PackedVector2Array(raw_points)
				elif raw_points is Array:
					for point_value in Array(raw_points):
						if point_value is Vector2 or point_value is Vector2i:
							points.append(Vector2(point_value))
				if points.size() >= 2 and polyline_color_value is Color:
					draw_polyline(points, Color(polyline_color_value), float(command.get("width", 1.0)), bool(command.get("antialiased", true)))
			"arc":
				var arc_center_value: Variant = command.get("center", null)
				var arc_color_value: Variant = command.get("color", null)
				if arc_center_value is Vector2 and arc_color_value is Color:
					draw_arc(Vector2(arc_center_value), float(command.get("radius", 1.0)), float(command.get("start_angle", 0.0)), float(command.get("end_angle", TAU)), int(command.get("point_count", 24)), Color(arc_color_value), float(command.get("width", 1.0)), bool(command.get("antialiased", true)))
			"wall_cable_segment":
				var segment_start_value: Variant = command.get("start", null)
				var segment_end_value: Variant = command.get("end", null)
				if not (segment_start_value is Vector2) or not (segment_end_value is Vector2):
					continue
				var profile: Dictionary = fallback_profile
				if command.get("profile", {}) is Dictionary:
					profile = Dictionary(command.get("profile", {}))
				draw_iso_cable_wall_segment(Vector2(segment_start_value), Vector2(segment_end_value), profile)
	return not commands.is_empty()''')

renderer = replace_function(renderer, "_get_line_color_from_id", '''func _get_line_color_from_id(color_id: String, fallback: Color) -> Color:
	return CableCanvasRendererRef.resolve_line_color(color_id, fallback)''')

renderer = replace_function(renderer, "draw_iso_cable_segment_shape", '''func draw_iso_cable_segment_shape(cell: Vector2i, topology: Dictionary, profile: Dictionary, visual_center: Vector2, object_data: Dictionary = {}) -> void:
	var install_mode: String = get_cable_install_mode(object_data)
	var health_state: String = get_cable_health_state(object_data)
	if install_mode == "hidden" and not is_map_constructor_editor_render():
		return
	var cable_center: Vector2 = visual_center + Vector2(0.0, -4.0)
	if install_mode == "wall" and _cell_has_wall_for_iso_cable(cell):
		cable_center = _get_iso_cable_wall_center(visual_center)
		if draw_wall_cable_visual_path(cell, object_data, visual_center, profile, topology):
			_draw_route_commands(CableCanvasRendererRef.build_damage_marker_commands({"center": _get_wall_cable_rail_anchor(cell, get_cable_wall_side(object_data)), "health_state": health_state}))
			return
	var route_plan: Dictionary = RouteRendererRef.build_floor_topology_plan(topology)
	var endpoints: Dictionary = {}
	var direction_vectors: Dictionary = {}
	for direction_variant in Array(route_plan.get("active_dirs", [])):
		var direction := str(direction_variant)
		endpoints[direction] = _get_iso_cable_branch_endpoint_for_visual_center(cell, direction, cable_center)
		direction_vectors[direction] = _get_iso_cable_screen_direction(direction)
	var object_link_rows: Array[Dictionary] = []
	for direction_variant in Dictionary(topology.get("object_links", {})).keys():
		var direction := str(direction_variant)
		var screen_direction := _get_iso_cable_screen_direction(direction)
		if screen_direction.length_squared() <= 0.0001:
			continue
		var direction_vector := screen_direction.normalized()
		object_link_rows.append({"direction": direction, "start": cable_center + direction_vector * minf(screen_direction.length() * 0.18, 12.0), "end": cable_center + direction_vector * minf(screen_direction.length() * 0.34, 22.0)})
	_draw_route_commands(CableCanvasRendererRef.build_floor_cable_commands({
		"center": cable_center,
		"tile_half_size": get_iso_tile_half_size(),
		"profile": profile,
		"install_mode": install_mode,
		"line_color_id": str(object_data.get("line_color_id", object_data.get("color_id", ""))),
		"route_plan": route_plan,
		"endpoints": endpoints,
		"direction_vectors": direction_vectors,
		"object_link_rows": object_link_rows,
		"health_state": health_state,
		"debug_outlines": debug_draw_iso_object_outlines,
	}))''')

renderer = replace_function(renderer, "draw_iso_cable_mode_polyline", '''func draw_iso_cable_mode_polyline(points: Array[Vector2], profile: Dictionary) -> void:
	for index in range(maxi(points.size() - 1, 0)):
		draw_iso_cable_mode_segment(points[index], points[index + 1], profile)''')
renderer = replace_function(renderer, "draw_iso_cable_hidden_segment", '''func draw_iso_cable_hidden_segment(start: Vector2, end: Vector2, profile: Dictionary) -> void:
	_draw_route_commands(CableCanvasRendererRef.build_hidden_segment_commands({"start": start, "end": end, "profile": profile}))''')
renderer = replace_function(renderer, "draw_iso_cable_wall_segment", '''func draw_iso_cable_wall_segment(start: Vector2, end: Vector2, profile: Dictionary) -> void:
	_draw_route_commands(CableCanvasRendererRef.build_wall_segment_commands({"start": start, "end": end, "profile": profile}))''')
renderer = replace_function(renderer, "get_cable_bridge_network_id", '''func get_cable_bridge_network_id(object_data: Dictionary) -> String:
	return CableCanvasRendererRef.extract_bridge_network_id(object_data)''')

renderer = replace_function(renderer, "should_draw_object_cable_bridge", '''func should_draw_object_cable_bridge(object_data: Dictionary, object_cell: Vector2i, cable_data: Dictionary, cable_cell: Vector2i) -> bool:
	var cable_network_id: String = get_cable_bridge_network_id(cable_data)
	if cable_network_id.is_empty() and cable_data.has("objects"):
		for cable_object_variant in Array(cable_data.get("objects", [])):
			if cable_object_variant is Dictionary:
				cable_network_id = get_cable_bridge_network_id(Dictionary(cable_object_variant))
				if not cable_network_id.is_empty():
					break
	return CableCanvasRendererRef.should_emit_bridge({
		"object_cell": object_cell,
		"cable_cell": cable_cell,
		"cable_present": bool(cable_data.get("has_cable", false)) or CableTopologyServiceRef.is_cable_object(cable_data),
		"object_connectable": is_power_cable_bridge_connectable_object(object_data),
		"object_network_id": get_cable_bridge_network_id(object_data),
		"cable_network_id": cable_network_id,
	})''')

renderer = replace_function(renderer, "get_cell_edge_bridge_points", '''func get_cell_edge_bridge_points(from_cell: Vector2i, to_cell: Vector2i) -> Dictionary:
	return CableCanvasRendererRef.build_bridge_points({"object_center": grid_to_iso(from_cell) + Vector2(0.0, -4.0), "cable_center": grid_to_iso(to_cell) + Vector2(0.0, -4.0)})''')
renderer = replace_function(renderer, "draw_object_cable_bridge", '''func draw_object_cable_bridge(object_data: Dictionary, object_cell: Vector2i, cable_data: Dictionary, cable_cell: Vector2i, profile: Dictionary) -> void:
	_draw_route_commands(CableCanvasRendererRef.build_bridge_commands({"object_center": grid_to_iso(object_cell) + Vector2(0.0, -4.0), "cable_center": grid_to_iso(cable_cell) + Vector2(0.0, -4.0), "install_mode": str(profile.get("install_mode", "floor"))}))
	if debug_log_cable_object_bridges:
		print("[CableObjectBridge] object_id=%s object_type=%s object_cell=%s cable_id=%s cable_cell=%s same_chain=true direction=%s" % [str(object_data.get("id", object_data.get("object_id", ""))), str(object_data.get("object_type", object_data.get("type", object_data.get("item_type", "")))), str(object_cell), str(cable_data.get("id", cable_data.get("object_id", cable_data.get("circuit_id", "")))), str(cable_cell), str(cable_cell - object_cell)])''')
renderer = replace_function(renderer, "draw_iso_cable_damage_marker", '''func draw_iso_cable_damage_marker(center: Vector2, health_state: String, _profile: Dictionary = {}) -> void:
	_draw_route_commands(CableCanvasRendererRef.build_damage_marker_commands({"center": center, "health_state": health_state}))''')
renderer = replace_function(renderer, "draw_iso_cable_object_links", '''func draw_iso_cable_object_links(_cell: Vector2i, object_links: Dictionary, cable_center: Vector2, profile: Dictionary) -> void:
	var rows: Array[Dictionary] = []
	for direction_variant in object_links.keys():
		var direction := str(direction_variant)
		var screen_direction := _get_iso_cable_screen_direction(direction)
		if screen_direction.length_squared() <= 0.0001:
			continue
		var direction_vector := screen_direction.normalized()
		rows.append({"direction": direction, "start": cable_center + direction_vector * minf(screen_direction.length() * 0.18, 12.0), "end": cable_center + direction_vector * minf(screen_direction.length() * 0.34, 22.0)})
	_draw_route_commands(CableCanvasRendererRef.build_object_link_commands({"rows": rows, "profile": profile}))''')
renderer = replace_function(renderer, "_draw_iso_cable_polyline", '''func _draw_iso_cable_polyline(points: Array[Vector2], profile: Dictionary) -> void:
	_draw_route_commands(CableCanvasRendererRef.build_layered_polyline_commands(points, profile))''')
renderer = replace_function(renderer, "draw_iso_cable_endpoint_cap", '''func draw_iso_cable_endpoint_cap(center: Vector2, direction: String, color: Color) -> void:
	_draw_route_commands(CableCanvasRendererRef.build_endpoint_cap_commands({"center": center, "direction": _get_iso_cable_screen_direction(direction), "color": color}))''')
renderer = replace_function(renderer, "draw_iso_cable_elbow", '''func draw_iso_cable_elbow(center: Vector2, dir_a: String, dir_b: String, profile: Dictionary) -> void:
	var endpoints := {dir_a: center + _get_iso_cable_screen_direction(dir_a) * 0.5, dir_b: center + _get_iso_cable_screen_direction(dir_b) * 0.5}
	_draw_route_commands(CableCanvasRendererRef.build_floor_cable_commands({"center": center, "profile": profile, "install_mode": str(profile.get("install_mode", "floor")), "route_plan": {"shape": "elbow", "active_dirs": [dir_a, dir_b], "geometry_mode": "elbow", "has_switch": false, "valid": true}, "endpoints": endpoints, "direction_vectors": {dir_a: _get_iso_cable_screen_direction(dir_a), dir_b: _get_iso_cable_screen_direction(dir_b)}, "object_link_rows": [], "health_state": "normal"}))''')
renderer = replace_function(renderer, "draw_iso_cable_invalid_marker", '''func draw_iso_cable_invalid_marker(center: Vector2, shape: String) -> void:
	_draw_route_commands(CableCanvasRendererRef.build_invalid_marker_commands({"center": center, "shape": shape}))''')

line_count = len(renderer.splitlines())
if line_count > 5653:
    raise RuntimeError(f"RoomVisualRenderer line cap exceeded after migration: {line_count} > 5653")
RENDERER.write_text(renderer, encoding="utf-8")

boundary = BOUNDARY.read_text(encoding="utf-8")
boundary = boundary.replace("ROOM_VISUAL_RENDERER_DOOR_CANVAS_CAP = 5723", "ROOM_VISUAL_RENDERER_CABLE_CANVAS_CAP = 5653")
boundary = boundary.replace("renderer_lines > ROOM_VISUAL_RENDERER_DOOR_CANVAS_CAP", "renderer_lines > ROOM_VISUAL_RENDERER_CABLE_CANVAS_CAP")
boundary = boundary.replace("door Canvas extraction cap", "cable Canvas extraction cap")
boundary = boundary.replace("ROOM_VISUAL_RENDERER_DOOR_CANVAS_CAP}", "ROOM_VISUAL_RENDERER_CABLE_CANVAS_CAP}")
preload_token = '    \'preload("res://scripts/visual/renderer/route_renderer.gd")\',\n'
if 'cable_canvas_renderer.gd' not in boundary:
    if preload_token not in boundary:
        raise RuntimeError("general boundary preload anchor missing")
    boundary = boundary.replace(preload_token, preload_token + '    \'preload("res://scripts/visual/renderer/cable_canvas_renderer.gd")\',\n', 1)
BOUNDARY.write_text(boundary, encoding="utf-8")

workflow = WORKFLOW.read_text(encoding="utf-8")
boundary_step = "      - name: Check renderer component boundary\n        run: python tools/check_room_visual_renderer_component_boundary.py\n"
if "Check CableCanvasRenderer boundary" not in workflow:
    if boundary_step not in workflow:
        raise RuntimeError("renderer workflow boundary step anchor missing")
    workflow = workflow.replace(boundary_step, boundary_step + "      - name: Check CableCanvasRenderer boundary\n        run: python tools/check_cable_canvas_renderer_boundary.py\n", 1)
route_step = "      - name: Check RouteRenderer contract\n        run: godot --headless --path . --script res://tools/ci/check_route_renderer_contract.gd\n"
if "Check CableCanvasRenderer contract" not in workflow:
    if route_step not in workflow:
        raise RuntimeError("renderer workflow route contract anchor missing")
    workflow = workflow.replace(route_step, route_step + "      - name: Check CableCanvasRenderer contract\n        run: godot --headless --path . --script res://tools/ci/check_cable_canvas_renderer_contract.gd\n", 1)
WORKFLOW.write_text(workflow, encoding="utf-8")

for relative in ("tools/tmp_cable_patch_gzb64", "tools/tmp_cable_patch_parts", "tools/tmp_cable_patch_b64"):
    shutil.rmtree(ROOT / relative, ignore_errors=True)

print(f"Applied CableCanvasRenderer migration; RoomVisualRenderer={line_count} lines")
