extends RefCounted
class_name RuntimeDebugOverlayRenderer


static func build_origin_commands(enabled: bool) -> Array[Dictionary]:
	if not enabled:
		return []
	return [_circle_command(Vector2.ZERO, 3.0, Color(0.8, 0.95, 1.0, 0.75), 0)]


static func build_helper_preview_commands(points: PackedVector2Array) -> Array[Dictionary]:
	var commands: Array[Dictionary] = []
	if points.size() < 3:
		return commands
	commands.append(_polygon_command(points, Color(0.2, 0.8, 1.0, 0.15), 0))
	var order: int = 1
	for index in range(points.size()):
		var next_index: int = (index + 1) % points.size()
		commands.append(_line_command(points[index], points[next_index], Color(0.2, 0.8, 1.0, 0.9), 1.0, false, order))
		order += 1
	return commands


static func build_wall_mount_zone_commands(rows: Array) -> Array[Dictionary]:
	var commands: Array[Dictionary] = []
	var order: int = 0
	for row_variant in rows:
		var row: Dictionary = Dictionary(row_variant)
		if not row.has("center"):
			continue
		var center: Vector2 = Vector2(row.get("center", Vector2.ZERO))
		var side: String = str(row.get("side", ""))
		commands.append(_circle_command(center, 2.8, Color(0.35, 0.98, 0.86, 0.95), order))
		order += 1
		commands.append(_text_command(center + Vector2(3.0, -4.0), side.substr(0, 1).to_upper(), 12.0, 10, 0, Color(0.9, 0.98, 1.0, 0.9), order))
		order += 1
	return commands


static func build_wall_run_commands(rows: Array) -> Array[Dictionary]:
	var commands: Array[Dictionary] = []
	var order: int = 0
	for row_variant in rows:
		var row: Dictionary = Dictionary(row_variant)
		if row.has("label_position"):
			var label: String = str(row.get("shape", "unknown"))
			if bool(row.get("run_x", false)):
				label += " RX"
			if bool(row.get("run_y", false)):
				label += " RY"
			if bool(row.get("has_cap", false)) and label.begins_with("end_cap_"):
				label += " cap"
			commands.append(_text_command(Vector2(row.get("label_position", Vector2.ZERO)), label, 96.0, 8, 0, Color(1.0, 0.92, 0.42, 0.95), order))
			order += 1
		for edge_variant in Array(row.get("edges", [])):
			var edge: Dictionary = Dictionary(edge_variant)
			if not edge.has("start") or not edge.has("end"):
				continue
			var edge_color: Color = Color(0.25, 1.0, 0.78, 0.82)
			if not bool(edge.get("connected", false)):
				edge_color = Color(1.0, 0.55, 0.2, 0.9)
			commands.append(_line_command(Vector2(edge.get("start", Vector2.ZERO)), Vector2(edge.get("end", Vector2.ZERO)), edge_color, 1.2, false, order))
			order += 1
	return commands


static func build_floor_join_commands(rows: Array) -> Array[Dictionary]:
	var commands: Array[Dictionary] = []
	var order: int = 0
	for row_variant in rows:
		var row: Dictionary = Dictionary(row_variant)
		if not row.has("start") or not row.has("end"):
			continue
		var edge_color: Color = Color(0.25, 0.9, 1.0, 0.35)
		var edge_width: float = 0.65
		if bool(row.get("shown", false)):
			edge_color = Color(1.0, 0.82, 0.25, 0.92)
			edge_width = 1.35
		commands.append(_line_command(Vector2(row.get("start", Vector2.ZERO)), Vector2(row.get("end", Vector2.ZERO)), edge_color, edge_width, false, order))
		order += 1
	return commands


static func build_world_marker_commands(rows: Array) -> Array[Dictionary]:
	var commands: Array[Dictionary] = []
	var order: int = 0
	for row_variant in rows:
		var row: Dictionary = Dictionary(row_variant)
		if not row.has("center"):
			continue
		var marker: String = str(row.get("text", ""))
		if marker.is_empty():
			continue
		commands.append(_text_command(Vector2(row.get("center", Vector2.ZERO)) + Vector2(-12.0, 4.0), marker, 48.0, 14, 0, Color(1.0, 0.95, 0.4), order))
		order += 1
	return commands


static func build_fan_marker_commands(context: Dictionary) -> Array[Dictionary]:
	if not context.has("center") or not context.has("direction"):
		return []
	var center: Vector2 = Vector2(context.get("center", Vector2.ZERO))
	var direction: Vector2 = Vector2(context.get("direction", Vector2.RIGHT))
	if direction.length_squared() <= 0.0:
		direction = Vector2.RIGHT
	direction = direction.normalized()
	var perpendicular: Vector2 = Vector2(-direction.y, direction.x)
	var tip: Vector2 = center + direction * 18.0
	var base: Vector2 = center - direction * 5.0
	var left: Vector2 = base + perpendicular * 10.0
	var right: Vector2 = base - perpendicular * 10.0
	return [
		_polygon_command(PackedVector2Array([tip, left, right]), Color(0.97, 0.97, 1.0, 0.96), 0),
		_line_command(base, tip, Color(0.18, 0.28, 0.45, 0.9), 2.0, false, 1),
	]


static func build_asset_alignment_commands(context: Dictionary) -> Array[Dictionary]:
	if not context.has("expected_rect") or not context.has("actual_rect") or not context.has("anchor_position"):
		return []
	var expected_rect: Rect2 = Rect2(context.get("expected_rect", Rect2()))
	var actual_rect: Rect2 = Rect2(context.get("actual_rect", Rect2()))
	var anchor_position: Vector2 = Vector2(context.get("anchor_position", Vector2.ZERO))
	var asset_key: String = str(context.get("asset_key", ""))
	return [
		_rect_command(expected_rect, Color(1.0, 0.78, 0.22, 0.18), true, 1.0, false, 0),
		_rect_command(expected_rect, Color(1.0, 0.78, 0.22, 0.95), false, 1.0, false, 1),
		_rect_command(actual_rect, Color(0.2, 0.9, 1.0, 0.72), false, 1.0, false, 2),
		_line_command(anchor_position + Vector2(-4.0, 0.0), anchor_position + Vector2(4.0, 0.0), Color(1.0, 0.25, 0.25, 0.95), 1.5, false, 3),
		_line_command(anchor_position + Vector2(0.0, -4.0), anchor_position + Vector2(0.0, 4.0), Color(1.0, 0.25, 0.25, 0.95), 1.5, false, 4),
		_circle_command(anchor_position, 2.5, Color(1.0, 0.25, 0.25, 0.95), 5),
		_text_command(expected_rect.position + Vector2(2.0, -3.0), asset_key, maxf(expected_rect.size.x, 40.0), 9, 0, Color(1.0, 0.95, 0.78, 0.95), 6),
	]


static func build_grounding_commands(profile: Dictionary) -> Array[Dictionary]:
	var commands: Array[Dictionary] = []
	var order: int = 0
	var footprint: PackedVector2Array = PackedVector2Array(profile.get("footprint_polygon", PackedVector2Array()))
	if footprint.size() >= 3:
		commands.append(_polygon_command(footprint, Color(0.28, 0.7, 0.95, 0.08), order))
		order += 1
		for index in range(footprint.size()):
			var next_index: int = (index + 1) % footprint.size()
			commands.append(_line_command(footprint[index], footprint[next_index], Color(0.28, 0.8, 1.0, 0.65), 1.0, false, order))
			order += 1
	var center: Vector2 = Vector2(profile.get("visual_center", Vector2.ZERO))
	commands.append(_circle_command(center, 2.0, Color(0.96, 0.96, 0.2, 0.95), order))
	order += 1
	var short_label: String = "UN"
	match str(profile.get("grounding_type", "unknown")):
		"floor_standing": short_label = "FS"
		"wall_mounted": short_label = "WM"
		"door_insert": short_label = "DR"
		"floor_pickup": short_label = "IT"
		"cable_like": short_label = "CB"
	commands.append(_text_command(center + Vector2(4.0, -6.0), short_label, 18.0, 10, 0, Color(0.95, 1.0, 0.98, 0.95), order))
	return commands


static func build_door_opening_commands(context: Dictionary) -> Array[Dictionary]:
	var commands: Array[Dictionary] = []
	var order: int = 0
	var threshold_polygon: PackedVector2Array = PackedVector2Array(context.get("threshold_polygon", PackedVector2Array()))
	if threshold_polygon.size() >= 3:
		commands.append(_polygon_command(threshold_polygon, Color(0.2, 0.85, 1.0, 0.16), order))
		order += 1
		commands.append(_polyline_command(threshold_polygon, Color(0.35, 0.95, 1.0, 0.92), 1.2, true, order))
		order += 1
	if not context.has("insert_center"):
		return commands
	var insert_center: Vector2 = Vector2(context.get("insert_center", Vector2.ZERO))
	commands.append(_circle_command(insert_center, 3.5, Color(1.0, 0.3, 0.9, 0.95), order))
	order += 1
	for center_variant in Array(context.get("adjacent_wall_centers", [])):
		commands.append(_circle_command(Vector2(center_variant), 3.0, Color(0.95, 0.74, 0.28, 0.95), order))
		order += 1
	commands.append(_text_command(insert_center + Vector2(5.0, -7.0), str(context.get("orientation", "unknown")), 64.0, 9, 0, Color(0.95, 1.0, 1.0, 0.95), order))
	return commands


static func build_wall_debug_commands(context: Dictionary) -> Array[Dictionary]:
	var commands: Array[Dictionary] = []
	var order: int = 0
	if bool(context.get("show_topology", false)) and context.has("topology_position"):
		commands.append(_text_command(Vector2(context.get("topology_position", Vector2.ZERO)), str(context.get("topology", "")), 56.0, 9, 0, Color(0.95, 0.96, 1.0, 0.9), order))
		order += 1
	for zone_variant in Array(context.get("mount_zones", [])):
		var zone: Dictionary = Dictionary(zone_variant)
		var polygon: PackedVector2Array = PackedVector2Array(zone.get("points", PackedVector2Array()))
		if polygon.size() < 3:
			continue
		commands.append(_polygon_command(polygon, Color(zone.get("fill_color", Color(0.6, 0.62, 0.66, 0.35))), order))
		order += 1
		if bool(zone.get("draw_outline", false)):
			commands.append(_polyline_command(polygon, Color(zone.get("edge_color", Color.WHITE)), 1.1, true, order))
			order += 1
	return commands


static func _polygon_command(points: PackedVector2Array, color: Color, order: int) -> Dictionary:
	return {"kind": "polygon", "points": points, "color": color, "order": order}


static func _polyline_command(points: PackedVector2Array, color: Color, width: float, antialiased: bool, order: int) -> Dictionary:
	return {"kind": "polyline", "points": points, "color": color, "width": width, "antialiased": antialiased, "order": order}


static func _line_command(start: Vector2, end: Vector2, color: Color, width: float, antialiased: bool, order: int) -> Dictionary:
	return {"kind": "line", "start": start, "end": end, "color": color, "width": width, "antialiased": antialiased, "order": order}


static func _circle_command(center: Vector2, radius: float, color: Color, order: int) -> Dictionary:
	return {"kind": "circle", "center": center, "radius": radius, "color": color, "order": order}


static func _text_command(position: Vector2, text: String, width: float, font_size: int, alignment: int, color: Color, order: int) -> Dictionary:
	return {"kind": "text", "position": position, "text": text, "width": width, "font_size": font_size, "alignment": alignment, "color": color, "order": order}


static func _rect_command(rect: Rect2, color: Color, filled: bool, width: float, antialiased: bool, order: int) -> Dictionary:
	return {"kind": "rect", "rect": rect, "color": color, "filled": filled, "width": width, "antialiased": antialiased, "order": order}
