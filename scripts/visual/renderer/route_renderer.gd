extends RefCounted
class_name RouteRenderer

const FAMILY_CABLE := "cable"
const FAMILY_AIR_DUCT := "air_duct"
const FAMILY_WATER_PIPE := "water_pipe"

static func normalize_install_mode(object_data: Dictionary) -> String:
	if bool(object_data.get("hidden_installation", object_data.get("is_hidden", false))):
		return "hidden"
	var candidates: Array[String] = [
		str(object_data.get("cable_install_mode", "")),
		str(object_data.get("install_mode", "")),
		str(object_data.get("mount", "")),
		str(object_data.get("route_surface", "")),
		str(object_data.get("placement_mode", "")),
		str(object_data.get("placement", ""))
	]
	for raw_candidate in candidates:
		var mode := raw_candidate.strip_edges().to_lower().replace("-", "_").replace(" ", "_")
		match mode:
			"wall", "wall_mounted", "on_wall":
				return "wall"
			"hidden", "floor_hidden", "under_floor", "embedded_floor":
				return "hidden"
			"floor", "ground", "open_floor":
				return "floor"
	return "floor"

static func normalize_wall_routing_mode(object_data: Dictionary) -> String:
	var candidates: Array[String] = [
		str(object_data.get("route_mode", "")),
		str(object_data.get("wall_routing_mode", "")),
		str(object_data.get("routing_mode", "")),
		str(object_data.get("routing_style", ""))
	]
	for raw_candidate in candidates:
		var mode := raw_candidate.strip_edges().to_lower().replace("-", "_").replace(" ", "_")
		match mode:
			"inner", "inside", "internal", "in_wall", "embedded":
				return "inner"
			"outer", "outside", "external", "surface", "":
				return "outer"
	return "outer"

static func get_health_state(object_data: Dictionary) -> String:
	var state := str(object_data.get("cable_health_state", object_data.get("health_state", object_data.get("state", "normal")))).strip_edges().to_lower()
	if bool(object_data.get("cut", false)) or state == "cut":
		return "cut"
	if bool(object_data.get("broken", false)) or state == "broken":
		return "broken"
	if bool(object_data.get("damaged", false)) or state == "damaged":
		return "damaged"
	return "normal"

static func is_broken_route(object_data: Dictionary) -> bool:
	if bool(object_data.get("is_broken", false)) or bool(object_data.get("broken", false)):
		return true
	for key in ["state", "cable_state", "cable_health_state", "health_state"]:
		if str(object_data.get(key, "")).strip_edges().to_lower() == "broken":
			return true
	return false

static func get_route_family(object_data: Dictionary) -> String:
	var tokens: Array[String] = [
		str(object_data.get("object_type", object_data.get("type", ""))),
		str(object_data.get("object_group", object_data.get("group", ""))),
		str(object_data.get("map_constructor_prefab_id", "")),
		str(object_data.get("prefab_id", "")),
		str(object_data.get("id", ""))
	]
	for raw_token in tokens:
		var token := raw_token.strip_edges().to_lower()
		if token.is_empty():
			continue
		if token.contains("external_air_duct") or token.contains("air_duct"):
			return FAMILY_AIR_DUCT
		if token.contains("external_water_pipe") or token.contains("water_pipe"):
			return FAMILY_WATER_PIPE
		if token == "cable" or token.contains("power_cable") or token.contains("cable_reel") or token.contains("cable"):
			return FAMILY_CABLE
	return ""

static func is_wall_procedural_routed_object(object_data: Dictionary, resolved_mount_mode: String = "") -> bool:
	var placement_mode := str(object_data.get("placement_mode", object_data.get("placement", ""))).strip_edges().to_lower()
	var mount_mode := str(object_data.get("mount", "")).strip_edges().to_lower()
	var install_mode := str(object_data.get("install_mode", "")).strip_edges().to_lower()
	var cable_install_mode := str(object_data.get("cable_install_mode", "")).strip_edges().to_lower()
	var wall_mounted := (
		bool(object_data.get("is_wall_mounted", false))
		or placement_mode in ["wall", "wall_mounted"]
		or mount_mode == "wall"
		or install_mode == "wall"
		or cable_install_mode == "wall"
		or resolved_mount_mode.strip_edges().to_lower() == "wall"
	)
	return wall_mounted and not get_route_family(object_data).is_empty()

static func get_wall_routed_height_source_px(object_data: Dictionary) -> float:
	match get_route_family(object_data):
		FAMILY_CABLE:
			return 50.0
		FAMILY_AIR_DUCT, FAMILY_WATER_PIPE:
			return 400.0
	return 50.0

static func get_wall_face_occluder_delta(face: String) -> Vector2i:
	match face.strip_edges().to_lower():
		"sw":
			return Vector2i(0, 1)
		"se":
			return Vector2i(1, 0)
	return Vector2i.ZERO

static func get_wall_visual_axis_for_side(side: String) -> Vector2:
	match side.strip_edges().to_lower():
		"sw":
			return Vector2(1.0, -0.5).normalized()
		"se":
			return Vector2(1.0, 0.5).normalized()
	return Vector2.RIGHT

static func build_wall_face_segment(visual_center: Vector2, tile_half_size: Vector2, face: String, cable_height_px: float = 50.0) -> Dictionary:
	var normalized_face := face.strip_edges().to_lower()
	var bottom_a: Vector2
	var bottom_b: Vector2
	match normalized_face:
		"se":
			bottom_a = visual_center + Vector2(0.0, tile_half_size.y)
			bottom_b = visual_center + Vector2(tile_half_size.x, 0.0)
		_:
			bottom_a = visual_center + Vector2(-tile_half_size.x, 0.0)
			bottom_b = visual_center + Vector2(0.0, tile_half_size.y)
	var y_offset := Vector2(0.0, -cable_height_px)
	var start_edge := bottom_a + y_offset
	var end_edge := bottom_b + y_offset
	var mid_point := start_edge.lerp(end_edge, 0.5)
	var axis := end_edge - start_edge
	var normal := Vector2.UP
	if axis.length() > 0.001:
		normal = Vector2(-axis.y, axis.x).normalized()
	return {
		"face": normalized_face,
		"start_edge": start_edge,
		"mid": mid_point,
		"end_edge": end_edge,
		"normal": normal
	}

static func build_wall_route_segment(visual_center: Vector2, tile_half_size: Vector2, side: String) -> Dictionary:
	var normalized_side := side.strip_edges().to_lower()
	var start: Vector2
	var end: Vector2
	if normalized_side == "se":
		start = visual_center + Vector2(0.0, -tile_half_size.y * 0.10)
		end = visual_center + Vector2(tile_half_size.x * 0.55, tile_half_size.y * 0.15)
	else:
		start = visual_center + Vector2(-tile_half_size.x * 0.55, tile_half_size.y * 0.15)
		end = visual_center + Vector2(0.0, -tile_half_size.y * 0.10)
	var direction := end - start
	var normal := Vector2.ZERO
	if direction.length() > 0.001:
		normal = Vector2(-direction.y, direction.x).normalized()
	return {"start": start, "end": end, "side": normalized_side, "normal": normal}

static func build_wall_cable_commands(start_edge: Vector2, end_edge: Vector2, normal: Vector2, profile: Dictionary, broken: bool) -> Array[Dictionary]:
	var commands: Array[Dictionary] = []
	var axis := end_edge - start_edge
	if axis.length() <= 0.001:
		return commands
	if not broken:
		commands.append(_cable_segment(start_edge, end_edge, profile))
		return commands
	axis = axis.normalized()
	var mid_point := start_edge.lerp(end_edge, 0.5)
	var gap_half := 9.0
	var left_gap := mid_point - axis * gap_half
	var right_gap := mid_point + axis * gap_half
	commands.append(_cable_segment(start_edge, left_gap, profile))
	commands.append(_cable_segment(right_gap, end_edge, profile))
	commands.append(_cable_segment(left_gap - axis * 5.0, left_gap, profile))
	commands.append(_cable_segment(right_gap, right_gap + axis * 5.0, profile))
	var safe_normal := normal
	if safe_normal.length() <= 0.001:
		safe_normal = Vector2.UP
	else:
		safe_normal = safe_normal.normalized()
	var hang_dir := (Vector2.DOWN * 0.86 + safe_normal * 0.14).normalized()
	var left_tip := left_gap + hang_dir * 7.0
	var right_tip := right_gap + hang_dir * 7.0
	commands.append(_line(left_gap, left_tip, Color(0.025, 0.025, 0.03, 0.96), 2.6))
	commands.append(_line(right_gap, right_tip, Color(0.025, 0.025, 0.03, 0.96), 2.6))
	var perp := Vector2(-hang_dir.y, hang_dir.x).normalized()
	commands.append(_line(left_gap + perp * 0.5, left_tip + perp * 0.8, Color(0.95, 0.22, 0.16, 0.95), 1.0))
	commands.append(_line(left_gap - perp * 0.5, left_tip - perp * 0.6, Color(0.95, 0.78, 0.22, 0.95), 1.0))
	commands.append(_line(right_gap + perp * 0.5, right_tip + perp * 0.8, Color(0.95, 0.22, 0.16, 0.95), 1.0))
	commands.append(_line(right_gap - perp * 0.5, right_tip - perp * 0.6, Color(0.95, 0.78, 0.22, 0.95), 1.0))
	return commands

static func build_wall_break_overlay_commands(segment: Dictionary, profile: Dictionary) -> Array[Dictionary]:
	var commands: Array[Dictionary] = []
	var start_edge := Vector2(segment.get("start_edge", Vector2.ZERO))
	var mid_point := Vector2(segment.get("mid", Vector2.ZERO))
	var end_edge := Vector2(segment.get("end_edge", Vector2.ZERO))
	var normal := Vector2(segment.get("normal", Vector2.UP)).normalized()
	var axis := end_edge - start_edge
	if axis.length() <= 0.001:
		return commands
	axis = axis.normalized()
	var left_gap := mid_point - axis * 7.0
	var right_gap := mid_point + axis * 7.0
	commands.append(_line(left_gap, right_gap, Color(0.14, 0.14, 0.14, 1.0), 8.0))
	commands.append(_cable_segment(left_gap - axis * 7.0, left_gap, profile))
	commands.append(_cable_segment(right_gap, right_gap + axis * 7.0, profile))
	var hang_dir := (Vector2.DOWN * 0.88 + normal * 0.12).normalized()
	var left_tip := left_gap + hang_dir * 7.0
	var right_tip := right_gap + hang_dir * 7.0
	commands.append(_line(left_gap, left_tip, Color(0.03, 0.03, 0.04, 0.96), 3.0))
	commands.append(_line(right_gap, right_tip, Color(0.03, 0.03, 0.04, 0.96), 3.0))
	var perp := Vector2(-hang_dir.y, hang_dir.x).normalized()
	commands.append(_line(left_gap + perp * 0.5, left_tip + perp * 0.8, Color(0.95, 0.25, 0.18, 0.95), 1.0))
	commands.append(_line(left_gap - perp * 0.4, left_tip - perp * 0.6, Color(0.92, 0.78, 0.22, 0.95), 1.0))
	commands.append(_line(right_gap + perp * 0.5, right_tip + perp * 0.8, Color(0.95, 0.25, 0.18, 0.95), 1.0))
	commands.append(_line(right_gap - perp * 0.4, right_tip - perp * 0.6, Color(0.92, 0.78, 0.22, 0.95), 1.0))
	return commands

static func build_wall_broken_end_commands(anchor: Vector2, away_from_gap: Vector2, normal: Vector2, profile: Dictionary) -> Array[Dictionary]:
	var commands: Array[Dictionary] = []
	var tangent := away_from_gap - anchor
	if tangent.length() <= 0.001:
		return commands
	tangent = tangent.normalized()
	var stub_end := anchor + tangent * 10.0
	commands.append(_cable_segment(anchor, stub_end, profile))
	var hang_dir := (Vector2.DOWN * 0.85 + normal * 0.15).normalized()
	var hang_tip := anchor + hang_dir * 7.0
	commands.append(_line(anchor, hang_tip, Color(0.03, 0.03, 0.04, 0.96), 3.0))
	var perp := Vector2(-hang_dir.y, hang_dir.x).normalized()
	commands.append(_line(anchor + perp * 0.8, hang_tip + perp * 1.0, Color(0.95, 0.25, 0.18, 0.95), 1.0))
	commands.append(_line(anchor - perp * 0.6, hang_tip - perp * 0.4, Color(0.92, 0.78, 0.22, 0.95), 1.0))
	commands.append(_line(anchor + perp * 0.2, hang_tip - perp * 0.8, Color(0.86, 0.86, 0.90, 0.95), 1.0))
	return commands

static func build_floor_mode_segment_commands(start: Vector2, end: Vector2, install_mode: String) -> Array[Dictionary]:
	if start.distance_squared_to(end) <= 0.01:
		return []
	if install_mode.strip_edges().to_lower() == "hidden":
		var commands := build_dashed_line_commands(start, end, 7.0, 4.0, Color(0.05, 0.055, 0.065, 0.55), 3.0)
		commands.append_array(build_dashed_line_commands(start, end, 5.0, 6.0, Color(0.70, 0.74, 0.78, 0.28), 1.1))
		return commands
	return [
		_line(start + Vector2(0.0, 1.5), end + Vector2(0.0, 1.5), Color(0.01, 0.012, 0.016, 0.34), 7.0),
		_line(start, end, Color(0.06, 0.065, 0.075, 0.98), 5.0),
		_line(start + Vector2(0.0, -0.8), end + Vector2(0.0, -0.8), Color(0.87, 0.73, 0.30, 0.95), 1.5)
	]

static func build_dashed_line_commands(start: Vector2, end: Vector2, dash_length: float, gap_length: float, color: Color, width: float) -> Array[Dictionary]:
	var commands: Array[Dictionary] = []
	var delta := end - start
	var length := delta.length()
	if length <= 0.1:
		return commands
	var direction := delta / length
	var cursor := 0.0
	while cursor < length:
		var dash_end := minf(cursor + dash_length, length)
		commands.append(_line(start + direction * cursor, start + direction * dash_end, color, width))
		cursor += dash_length + gap_length
	return commands

static func build_procedural_route_commands(family: String, segment: Dictionary, routing_mode: String) -> Array[Dictionary]:
	var start := Vector2(segment.get("start", Vector2.ZERO))
	var end := Vector2(segment.get("end", Vector2.ZERO))
	var normal := Vector2(segment.get("normal", Vector2.ZERO))
	var mode := routing_mode.strip_edges().to_lower()
	match family.strip_edges().to_lower():
		FAMILY_CABLE:
			return _build_procedural_cable_commands(start, end, normal, mode)
		FAMILY_AIR_DUCT:
			return _build_procedural_air_duct_commands(start, end, normal, mode)
		FAMILY_WATER_PIPE:
			return _build_procedural_water_pipe_commands(start, end, normal, mode)
	return []

static func get_active_directions(topology: Dictionary) -> Array[String]:
	var connected_dirs := Dictionary(topology.get("connected_dirs", topology.get("neighbors", {})))
	var active: Array[String] = []
	for direction in ["north", "south", "west", "east"]:
		if bool(connected_dirs.get(direction, false)):
			active.append(direction)
	return active

static func build_floor_topology_plan(topology: Dictionary) -> Dictionary:
	var active_dirs := get_active_directions(topology)
	var shape := str(topology.get("shape", "isolated"))
	var has_switch := bool(topology.get("has_circuit_switch", false))
	var valid := bool(topology.get("valid", true))
	var geometry_mode := "branches"
	if active_dirs.is_empty():
		geometry_mode = "isolated"
	elif active_dirs.size() == 2 and not shape.begins_with("junction") and not shape.begins_with("invalid"):
		if (active_dirs.has("east") and active_dirs.has("west")) or (active_dirs.has("north") and active_dirs.has("south")):
			geometry_mode = "straight"
		else:
			geometry_mode = "elbow"
	return {
		"shape": shape,
		"active_dirs": active_dirs,
		"geometry_mode": geometry_mode,
		"has_switch": has_switch,
		"valid": valid,
		"endpoint_cap": active_dirs.size() == 1 and not has_switch,
		"junction_marker": valid and shape.begins_with("junction") and not has_switch,
		"invalid_marker": not valid
	}

static func _build_procedural_cable_commands(start: Vector2, end: Vector2, normal: Vector2, mode: String) -> Array[Dictionary]:
	var commands: Array[Dictionary] = []
	if mode == "inner":
		commands.append(_line(start + normal * 1.5, end + normal * 1.5, Color(0.01, 0.012, 0.016, 0.46), 6.0))
		commands.append_array(build_dashed_line_commands(start, end, 7.0, 4.0, Color(0.05, 0.055, 0.065, 0.72), 3.5))
		commands.append_array(build_dashed_line_commands(start, end, 5.0, 6.0, Color(0.70, 0.74, 0.78, 0.36), 1.3))
		return commands
	commands.append(_line(start + normal * 1.5, end + normal * 1.5, Color(0.01, 0.012, 0.016, 0.36), 7.0))
	commands.append(_line(start, end, Color(0.06, 0.065, 0.075, 0.98), 5.0))
	commands.append(_line(start - normal * 0.8, end - normal * 0.8, Color(0.87, 0.73, 0.30, 0.95), 1.6))
	for point in [start.lerp(end, 0.18), start.lerp(end, 0.82)]:
		commands.append(_circle(point, 3.0, Color(0.015, 0.017, 0.02, 0.94)))
		commands.append(_circle(point, 1.8, Color(0.48, 0.50, 0.52, 0.96)))
	return commands

static func _build_procedural_air_duct_commands(start: Vector2, end: Vector2, normal: Vector2, mode: String) -> Array[Dictionary]:
	var commands: Array[Dictionary] = []
	if mode == "inner":
		commands.append(_line(start, end, Color(0.01, 0.012, 0.016, 0.84), 13.0))
		commands.append(_line(start + normal * 1.6, end + normal * 1.6, Color(0.21, 0.25, 0.29, 0.38), 7.0))
		commands.append(_circle(start, 5.0, Color(0.01, 0.012, 0.016, 0.82)))
		commands.append(_circle(end, 5.0, Color(0.01, 0.012, 0.016, 0.82)))
		return commands
	commands.append(_line(start + normal * 2.0, end + normal * 2.0, Color(0.04, 0.045, 0.05, 0.46), 16.0))
	commands.append(_line(start, end, Color(0.13, 0.15, 0.17, 0.98), 15.0))
	commands.append(_line(start, end, Color(0.45, 0.51, 0.57, 0.98), 12.0))
	commands.append(_line(start - normal * 2.3, end - normal * 2.3, Color(0.77, 0.84, 0.90, 0.82), 2.0))
	for point in [start.lerp(end, 0.30), start.lerp(end, 0.55), start.lerp(end, 0.80)]:
		commands.append(_line(point - normal * 4.0, point + normal * 4.0, Color(0.22, 0.25, 0.28, 0.72), 1.1))
	return commands

static func _build_procedural_water_pipe_commands(start: Vector2, end: Vector2, normal: Vector2, mode: String) -> Array[Dictionary]:
	var commands: Array[Dictionary] = []
	if mode == "inner":
		commands.append(_line(start + normal, end + normal, Color(0.01, 0.012, 0.016, 0.58), 8.0))
		commands.append(_line(start, end, Color(0.14, 0.36, 0.43, 0.48), 4.0))
		commands.append(_line(start - normal * 0.7, end - normal * 0.7, Color(0.68, 0.88, 0.95, 0.24), 1.2))
		return commands
	commands.append(_line(start + normal * 1.5, end + normal * 1.5, Color(0.02, 0.025, 0.03, 0.38), 12.0))
	commands.append(_line(start, end, Color(0.10, 0.12, 0.14, 0.98), 10.0))
	commands.append(_line(start, end, Color(0.37, 0.69, 0.78, 0.98), 7.0))
	commands.append(_line(start - normal * 1.3, end - normal * 1.3, Color(0.88, 0.97, 1.0, 0.78), 1.5))
	for point in [start.lerp(end, 0.12), start.lerp(end, 0.88)]:
		commands.append(_circle(point, 5.0, Color(0.10, 0.12, 0.14, 0.98)))
		commands.append(_circle(point, 3.3, Color(0.50, 0.76, 0.83, 0.98)))
	return commands

static func _line(start: Vector2, end: Vector2, color: Color, width: float) -> Dictionary:
	return {"kind": "line", "start": start, "end": end, "color": color, "width": width, "antialiased": true}

static func _circle(center: Vector2, radius: float, color: Color) -> Dictionary:
	return {"kind": "circle", "center": center, "radius": radius, "color": color}

static func _cable_segment(start: Vector2, end: Vector2, profile: Dictionary) -> Dictionary:
	return {"kind": "wall_cable_segment", "start": start, "end": end, "profile": profile.duplicate(true)}
