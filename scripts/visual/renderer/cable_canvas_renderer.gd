extends RefCounted
class_name CableCanvasRenderer

const RouteRendererRef = preload("res://scripts/visual/renderer/route_renderer.gd")

const BRIDGE_NETWORK_KEYS: Array[String] = [
	"power_network_id", "cable_network_id", "network_id", "connection_id",
	"circuit_id", "cable_chain_id", "power_circuit_id", "chain_id",
	"link_group", "cable_group", "connected_circuit"
]

static func _read_dictionary(value: Variant) -> Dictionary:
	return Dictionary(value) if value is Dictionary else {}

static func _read_vector2(value: Variant, fallback: Vector2 = Vector2.ZERO) -> Vector2:
	if value is Vector2:
		return Vector2(value)
	if value is Vector2i:
		return Vector2(Vector2i(value))
	return fallback

static func _read_color(value: Variant, fallback: Color) -> Color:
	return Color(value) if value is Color else fallback

static func _read_float(value: Variant, fallback: float) -> float:
	return float(value) if value is float or value is int else fallback

static func _read_bool(value: Variant, fallback: bool) -> bool:
	return bool(value) if value is bool else fallback

static func _line(start: Vector2, end: Vector2, color: Color, width: float, order: int = 0) -> Dictionary:
	return {"kind": "line", "order": order, "start": start, "end": end, "color": color, "width": width, "antialiased": true}

static func _circle(center: Vector2, radius: float, color: Color, order: int = 0) -> Dictionary:
	return {"kind": "circle", "order": order, "center": center, "radius": radius, "color": color}

static func _arc(center: Vector2, radius: float, color: Color, width: float, order: int = 0) -> Dictionary:
	return {"kind": "arc", "order": order, "center": center, "radius": radius, "start_angle": 0.0, "end_angle": TAU, "point_count": 20, "color": color, "width": width, "antialiased": true}

static func _polyline(points: PackedVector2Array, color: Color, width: float, order: int = 0) -> Dictionary:
	return {"kind": "polyline", "order": order, "points": points, "color": color, "width": width, "antialiased": true}

static func resolve_line_color(color_id: String, fallback: Color) -> Color:
	match color_id.strip_edges().to_lower():
		"red": return Color(1.0, 0.22, 0.18, fallback.a)
		"blue": return Color(0.22, 0.48, 1.0, fallback.a)
		"green": return Color(0.24, 0.92, 0.42, fallback.a)
		"yellow": return Color(1.0, 0.88, 0.2, fallback.a)
		"orange": return Color(1.0, 0.55, 0.18, fallback.a)
		"purple": return Color(0.72, 0.38, 1.0, fallback.a)
		"white": return Color(0.95, 0.95, 0.92, fallback.a)
	return fallback

static func build_profile(context: Dictionary) -> Dictionary:
	var source_profile := _read_dictionary(context.get("profile", {}))
	var install_mode := str(context.get("install_mode", "floor")).strip_edges().to_lower()
	var valid := _read_bool(context.get("valid", true), true)
	var base_color := _read_color(source_profile.get("base", Color.WHITE), Color.WHITE)
	var accent_color := _read_color(source_profile.get("accent", Color.WHITE), Color.WHITE)
	var outline_color := _read_color(source_profile.get("outline", Color.WHITE), Color.WHITE)
	var line_color_id := str(context.get("line_color_id", "")).strip_edges()
	if not line_color_id.is_empty():
		accent_color = resolve_line_color(line_color_id, accent_color)
		base_color = resolve_line_color(line_color_id, base_color).darkened(0.35)
	if install_mode == "hidden":
		base_color = Color(base_color.r, base_color.g, base_color.b, 0.72)
		accent_color = Color(accent_color.r, accent_color.g, accent_color.b, 0.82)
	elif install_mode == "wall":
		base_color = base_color.lightened(0.08)
		accent_color = accent_color.lightened(0.12)
	if not valid:
		base_color = Color(1.0, 0.25, 0.08, 0.98)
		accent_color = Color(1.0, 0.82, 0.15, 0.98)
		outline_color = Color(0.45, 0.04, 0.02, 0.98)
	var result := source_profile.duplicate(true)
	result["base"] = base_color
	result["accent"] = accent_color
	result["outline"] = outline_color
	result["install_mode"] = install_mode
	return result

static func build_layered_polyline_commands(points_value: Variant, profile: Dictionary) -> Array[Dictionary]:
	var points := PackedVector2Array()
	if points_value is PackedVector2Array:
		points = PackedVector2Array(points_value)
	elif points_value is Array:
		for point_value in Array(points_value):
			if point_value is Vector2 or point_value is Vector2i:
				points.append(_read_vector2(point_value))
	if points.size() < 2:
		return []
	var shadow_points := PackedVector2Array()
	for point in points:
		shadow_points.append(point + Vector2(0.0, 2.0))
	return [
		_polyline(shadow_points, Color(0.03, 0.02, 0.02, 0.28), 7.0, 0),
		_polyline(points, _read_color(profile.get("outline", Color.WHITE), Color.WHITE), 6.0, 1),
		_polyline(points, _read_color(profile.get("base", Color.WHITE), Color.WHITE), 4.0, 2),
		_polyline(points, _read_color(profile.get("accent", Color.WHITE), Color.WHITE), 1.5, 3),
	]

static func build_hidden_segment_commands(context: Dictionary) -> Array[Dictionary]:
	var start := _read_vector2(context.get("start", Vector2.ZERO))
	var end := _read_vector2(context.get("end", Vector2.ZERO))
	var profile := _read_dictionary(context.get("profile", {}))
	var delta := end - start
	var length := delta.length()
	if length <= 0.1:
		return []
	var commands: Array[Dictionary] = []
	var direction := delta / length
	var cursor := 0.0
	while cursor < length:
		var dash_end := minf(cursor + 7.0, length)
		commands.append_array(build_layered_polyline_commands(PackedVector2Array([start + direction * cursor, start + direction * dash_end]), profile))
		cursor += 12.0
	return commands

static func build_wall_segment_commands(context: Dictionary) -> Array[Dictionary]:
	var start := _read_vector2(context.get("start", Vector2.ZERO))
	var end := _read_vector2(context.get("end", Vector2.ZERO))
	var profile := _read_dictionary(context.get("profile", {}))
	var commands := build_layered_polyline_commands(PackedVector2Array([start, end]), profile)
	commands.append(_line(start + Vector2(0.0, 2.0), end + Vector2(0.0, 2.0), Color(0.0, 0.0, 0.0, 0.18), 2.0, commands.size()))
	return commands

static func build_endpoint_cap_commands(context: Dictionary) -> Array[Dictionary]:
	var center := _read_vector2(context.get("center", Vector2.ZERO))
	var direction := _read_vector2(context.get("direction", Vector2.RIGHT), Vector2.RIGHT)
	if direction.length_squared() <= 0.0001:
		return []
	direction = direction.normalized()
	var normal := Vector2(-direction.y, direction.x).normalized()
	var color := _read_color(context.get("color", Color.WHITE), Color.WHITE)
	return [
		_line(center - normal * 5.0 + direction, center + normal * 5.0 + direction, Color(0.1, 0.03, 0.02, 0.95), 4.4, 0),
		_line(center - normal * 4.0 + direction, center + normal * 4.0 + direction, color, 2.2, 1),
		_line(center, center + direction * 5.0, color.lightened(0.18), 1.2, 2),
	]

static func build_invalid_marker_commands(context: Dictionary) -> Array[Dictionary]:
	var center := _read_vector2(context.get("center", Vector2.ZERO))
	var shape := str(context.get("shape", ""))
	var radius := 7.0 if shape == "invalid_cross" else 6.0
	return [
		_circle(center + Vector2(0.0, -1.0), radius, Color(0.44, 0.04, 0.02, 0.96), 0),
		_line(center + Vector2(-radius * 0.55, -radius * 0.55 - 1.0), center + Vector2(radius * 0.55, radius * 0.55 - 1.0), Color(1.0, 0.82, 0.15, 0.98), 2.2, 1),
		_line(center + Vector2(radius * 0.55, -radius * 0.55 - 1.0), center + Vector2(-radius * 0.55, radius * 0.55 - 1.0), Color(1.0, 0.82, 0.15, 0.98), 2.2, 2),
	]

static func build_damage_marker_commands(context: Dictionary) -> Array[Dictionary]:
	var state := str(context.get("health_state", "normal")).strip_edges().to_lower()
	if state not in ["damaged", "broken", "cut"]:
		return []
	var center := _read_vector2(context.get("center", Vector2.ZERO))
	var marker_color := Color(1.0, 0.74, 0.20, 0.96)
	if state == "broken" or state == "cut": marker_color = Color(1.0, 0.22, 0.16, 0.96)
	return [
		_circle(center, 4.0, Color(0.02, 0.02, 0.025, 0.86), 0),
		_line(center + Vector2(-4.0, -4.0), center + Vector2(4.0, 4.0), marker_color, 1.8, 1),
		_line(center + Vector2(-4.0, 4.0), center + Vector2(4.0, -4.0), marker_color, 1.8, 2),
	]

static func build_object_link_commands(context: Dictionary) -> Array[Dictionary]:
	var rows_value: Variant = context.get("rows", [])
	if not (rows_value is Array): return []
	var profile := _read_dictionary(context.get("profile", {}))
	var install_mode := str(profile.get("install_mode", "floor"))
	var base_color := _read_color(profile.get("base", Color.WHITE), Color.WHITE).lightened(0.12)
	var accent_color := _read_color(profile.get("accent", Color.WHITE), Color.WHITE)
	var outline_color := _read_color(profile.get("outline", Color.WHITE), Color.WHITE)
	var commands: Array[Dictionary] = []
	for row_value in Array(rows_value):
		if not (row_value is Dictionary): continue
		var row := Dictionary(row_value)
		var start := _read_vector2(row.get("start", Vector2.ZERO))
		var end := _read_vector2(row.get("end", Vector2.ZERO))
		if start.distance_squared_to(end) <= 0.01: continue
		if install_mode == "hidden":
			commands.append_array(build_hidden_segment_commands({"start": start, "end": end, "profile": profile}))
		else:
			commands.append(_line(start + Vector2(0.0, 1.3), end + Vector2(0.0, 1.3), Color(0.03, 0.02, 0.02, 0.22), 4.0, commands.size()))
			commands.append(_line(start, end, outline_color, 3.0, commands.size()))
			commands.append(_line(start, end, base_color, 1.9, commands.size()))
		commands.append(_circle(end, 2.3, accent_color, commands.size()))
	return commands

static func build_floor_cable_commands(context: Dictionary) -> Array[Dictionary]:
	var route_plan := _read_dictionary(context.get("route_plan", {}))
	var center := _read_vector2(context.get("center", Vector2.ZERO))
	var tile_half_size := _read_vector2(context.get("tile_half_size", Vector2(64.0, 32.0)), Vector2(64.0, 32.0))
	var install_mode := str(context.get("install_mode", "floor")).strip_edges().to_lower()
	var valid := _read_bool(route_plan.get("valid", true), true)
	var profile := build_profile({"profile": _read_dictionary(context.get("profile", {})), "install_mode": install_mode, "line_color_id": str(context.get("line_color_id", "")), "valid": valid})
	var shape := str(route_plan.get("shape", "isolated"))
	var geometry_mode := str(route_plan.get("geometry_mode", "branches"))
	var has_switch := _read_bool(route_plan.get("has_switch", false), false)
	var endpoints := _read_dictionary(context.get("endpoints", {}))
	var direction_vectors := _read_dictionary(context.get("direction_vectors", {}))
	var active_dirs: Array[String] = []
	for direction_value in Array(route_plan.get("active_dirs", [])): active_dirs.append(str(direction_value))
	var commands: Array[Dictionary] = []
	var accent_color := _read_color(profile.get("accent", Color.WHITE), Color.WHITE)
	var outline_color := _read_color(profile.get("outline", Color.WHITE), Color.WHITE)
	if geometry_mode == "isolated" or active_dirs.is_empty():
		var half_width := maxf(tile_half_size.x * 0.12, 7.0)
		commands.append_array(RouteRendererRef.build_floor_mode_segment_commands(center + Vector2(-half_width, 0.0), center + Vector2(half_width, 0.0), install_mode))
		commands.append(_circle(center, 4.5, accent_color, commands.size()))
		commands.append(_arc(center, 7.0, outline_color, 1.4, commands.size()))
	elif geometry_mode == "straight" and active_dirs.size() >= 2:
		commands.append_array(RouteRendererRef.build_floor_mode_segment_commands(_read_vector2(endpoints.get(active_dirs[0], center)), _read_vector2(endpoints.get(active_dirs[1], center)), install_mode))
	elif geometry_mode == "elbow" and active_dirs.size() >= 2:
		var endpoint_a := _read_vector2(endpoints.get(active_dirs[0], center))
		var endpoint_b := _read_vector2(endpoints.get(active_dirs[1], center))
		commands.append_array(RouteRendererRef.build_floor_mode_segment_commands(endpoint_a, center, install_mode))
		commands.append_array(RouteRendererRef.build_floor_mode_segment_commands(center, endpoint_b, install_mode))
		commands.append(_circle(center, 2.7, _read_color(profile.get("base", Color.WHITE), Color.WHITE), commands.size()))
		commands.append(_circle(center + Vector2(0.0, -0.4), 1.2, accent_color, commands.size()))
	else:
		for direction in active_dirs:
			commands.append_array(RouteRendererRef.build_floor_mode_segment_commands(center, _read_vector2(endpoints.get(direction, center)), install_mode))
	commands.append_array(build_object_link_commands({"rows": context.get("object_link_rows", []), "profile": profile}))
	if _read_bool(route_plan.get("endpoint_cap", active_dirs.size() == 1 and not has_switch), false) and active_dirs.size() == 1:
		var direction := active_dirs[0]
		commands.append_array(build_endpoint_cap_commands({"center": _read_vector2(endpoints.get(direction, center)), "direction": _read_vector2(direction_vectors.get(direction, Vector2.RIGHT), Vector2.RIGHT), "color": accent_color}))
	if _read_bool(route_plan.get("invalid_marker", not valid), false):
		commands.append_array(build_invalid_marker_commands({"center": center, "shape": shape}))
	elif _read_bool(route_plan.get("junction_marker", valid and shape.begins_with("junction") and not has_switch), false):
		commands.append(_circle(center, 3.6, accent_color, commands.size()))
	commands.append_array(build_damage_marker_commands({"center": center, "health_state": context.get("health_state", "normal")}))
	if _read_bool(context.get("debug_outlines", false), false):
		for direction in active_dirs: commands.append(_line(center, _read_vector2(endpoints.get(direction, center)), outline_color, 1.0, commands.size()))
	return commands

static func extract_bridge_network_id(object_data: Dictionary) -> String:
	for key in BRIDGE_NETWORK_KEYS:
		var value := str(object_data.get(key, "")).strip_edges()
		if not value.is_empty(): return value
	return ""

static func should_emit_bridge(context: Dictionary) -> bool:
	var object_cell_value: Variant = context.get("object_cell", Vector2i(-1, -1))
	var cable_cell_value: Variant = context.get("cable_cell", Vector2i(-1, -1))
	if not (object_cell_value is Vector2i) or not (cable_cell_value is Vector2i): return false
	var delta := Vector2i(cable_cell_value) - Vector2i(object_cell_value)
	if abs(delta.x) + abs(delta.y) != 1: return false
	if not _read_bool(context.get("cable_present", false), false): return false
	if not _read_bool(context.get("object_connectable", false), false): return false
	var object_network_id := str(context.get("object_network_id", "")).strip_edges()
	var cable_network_id := str(context.get("cable_network_id", "")).strip_edges()
	return not object_network_id.is_empty() and object_network_id == cable_network_id

static func build_bridge_points(context: Dictionary) -> Dictionary:
	var object_center := _read_vector2(context.get("object_center", Vector2.ZERO))
	var cable_center := _read_vector2(context.get("cable_center", Vector2.ZERO))
	var shared_edge := object_center.lerp(cable_center, 0.5)
	return {"from_center": object_center, "from_edge_towards_to": shared_edge, "to_edge_towards_from": shared_edge, "to_center": cable_center}

static func build_bridge_commands(context: Dictionary) -> Array[Dictionary]:
	var points := build_bridge_points(context)
	var install_mode := str(context.get("install_mode", "floor"))
	var commands := RouteRendererRef.build_floor_mode_segment_commands(_read_vector2(points.get("from_center", Vector2.ZERO)), _read_vector2(points.get("from_edge_towards_to", Vector2.ZERO)), install_mode)
	commands.append_array(RouteRendererRef.build_floor_mode_segment_commands(_read_vector2(points.get("to_center", Vector2.ZERO)), _read_vector2(points.get("to_edge_towards_from", Vector2.ZERO)), install_mode))
	return commands
