extends RefCounted
class_name MapConstructorOverlayRenderer

static func build_commands(context: Dictionary) -> Array[Dictionary]:
	var commands: Array[Dictionary] = []
	var order: int = 0
	order = _append_cell_fill_outline(commands, PackedVector2Array(context.get("selected_points", PackedVector2Array())), Color(1.0, 0.92, 0.24, 0.11), Color(1.0, 0.92, 0.24, 0.95), 2.4, order)
	order = _append_outline(commands, PackedVector2Array(context.get("hover_points", PackedVector2Array())), Color(0.72, 0.92, 1.0, 0.45), 1.2, order)

	var preview_points: PackedVector2Array = PackedVector2Array(context.get("preview_points", PackedVector2Array()))
	if preview_points.size() >= 4:
		var preview_mode: String = str(context.get("preview_mode", "normal"))
		var fill: Color = Color(0.35, 1.0, 0.85, 0.16)
		var stroke: Color = Color(0.45, 1.0, 0.92, 1.0)
		if preview_mode == "blocked":
			fill = Color(1.0, 0.35, 0.25, 0.2)
			stroke = Color(1.0, 0.55, 0.3, 1.0)
		elif preview_mode == "destructive":
			fill = Color(1.0, 0.62, 0.22, 0.17)
			stroke = Color(1.0, 0.7, 0.3, 1.0)
		order = _append_cell_fill_outline(commands, preview_points, fill, stroke, 2.2, order)

	for wall_variant in Array(context.get("room_walls", [])):
		var wall: Dictionary = Dictionary(wall_variant)
		var points: PackedVector2Array = PackedVector2Array(wall.get("points", PackedVector2Array()))
		if points.size() < 4 or not wall.has("center"):
			continue
		order = _append_outline(commands, points, Color(0.95, 0.74, 0.28, 0.42), 1.5, order)
		commands.append(_circle_command(Vector2(wall.get("center", Vector2.ZERO)) + Vector2(0.0, -8.0), 2.1, Color(0.45, 0.9, 1.0, 0.76), order))
		order += 1
	for center_variant in Array(context.get("room_door_centers", [])):
		commands.append(_circle_command(Vector2(center_variant) + Vector2(-5.0, -9.0), 2.8, Color(1.0, 0.76, 0.28, 0.88), order))
		order += 1
	for center_variant in Array(context.get("room_terminal_centers", [])):
		commands.append(_circle_command(Vector2(center_variant) + Vector2(5.0, -9.0), 2.8, Color(0.44, 0.9, 1.0, 0.88), order))
		order += 1
	for points_variant in Array(context.get("room_floor_point_sets", [])):
		order = _append_outline(commands, PackedVector2Array(points_variant), Color(0.56, 0.78, 0.96, 0.48), 1.15, order)
	for points_variant in Array(context.get("multi_select_point_sets", [])):
		order = _append_outline(commands, PackedVector2Array(points_variant), Color(0.75, 0.85, 1.0, 0.8), 1.4, order)
	for marker_variant in Array(context.get("validation_markers", [])):
		var marker: Dictionary = Dictionary(marker_variant)
		if not marker.has("center"):
			continue
		var severity: String = str(marker.get("severity", "info"))
		var color: Color = Color(0.62, 0.8, 1.0, 0.95)
		if bool(marker.get("expected_invalid", false)) or severity.to_lower() == "expected_invalid":
			color = Color(0.74, 0.66, 0.86, 0.95)
		elif severity == "error":
			color = Color(1.0, 0.3, 0.3, 0.95)
		elif severity == "warning":
			color = Color(1.0, 0.74, 0.3, 0.95)
		commands.append(_circle_command(Vector2(marker.get("center", Vector2.ZERO)), 6.0, color, order))
		order += 1
	for link_variant in Array(context.get("links", [])):
		var link: Dictionary = Dictionary(link_variant)
		if not link.has("start") or not link.has("end"):
			continue
		var link_color: Color = Color(0.9, 0.58, 1.0, 0.85)
		if bool(link.get("broken", false)):
			link_color = Color(1.0, 0.3, 0.3, 0.9)
		commands.append(_line_command(Vector2(link.get("start", Vector2.ZERO)), Vector2(link.get("end", Vector2.ZERO)), link_color, 1.8, false, order))
		order += 1
	for power_variant in Array(context.get("power_links", [])):
		var power: Dictionary = Dictionary(power_variant)
		if not power.has("start") or not power.has("end"):
			continue
		commands.append(_line_command(Vector2(power.get("start", Vector2.ZERO)), Vector2(power.get("end", Vector2.ZERO)), Color(0.45, 0.9, 1.0, 0.65), 1.2, false, order))
		order += 1
	for arrow_variant in Array(context.get("wall_side_arrows", [])):
		var arrow: Dictionary = Dictionary(arrow_variant)
		if not arrow.has("center"):
			continue
		var dir: Vector2 = _direction_for_wall_side(str(arrow.get("wall_side", "")))
		var center: Vector2 = Vector2(arrow.get("center", Vector2.ZERO))
		var arrow_color: Color = Color(0.82, 0.95, 1.0, 1.0)
		if str(arrow.get("mode", "preview")) == "selected":
			arrow_color = Color(1.0, 0.88, 0.35, 1.0)
		var tip: Vector2 = center + dir * 16.0
		commands.append(_line_command(center, tip, arrow_color, 2.0, false, order))
		order += 1
		commands.append(_circle_command(tip, 3.0, arrow_color, order))
		order += 1
	return commands

static func _direction_for_wall_side(wall_side: String) -> Vector2:
	match wall_side:
		"east":
			return Vector2(1.0, 0.0)
		"south":
			return Vector2(0.0, 1.0)
		"west":
			return Vector2(-1.0, 0.0)
		_:
			return Vector2(0.0, -1.0)

static func _append_cell_fill_outline(commands: Array[Dictionary], points: PackedVector2Array, fill: Color, stroke: Color, width: float, order: int) -> int:
	if points.size() < 4:
		return order
	commands.append(_polygon_command(points, fill, order))
	order += 1
	return _append_outline(commands, points, stroke, width, order)

static func _append_outline(commands: Array[Dictionary], points: PackedVector2Array, color: Color, width: float, order: int) -> int:
	if points.size() < 4:
		return order
	for edge_index in range(points.size()):
		var next_index: int = (edge_index + 1) % points.size()
		commands.append(_line_command(points[edge_index], points[next_index], color, width, false, order))
		order += 1
	return order

static func _polygon_command(points: PackedVector2Array, color: Color, order: int) -> Dictionary:
	return {"kind": "polygon", "points": points, "color": color, "order": order}

static func _line_command(start: Vector2, end: Vector2, color: Color, width: float, antialiased: bool, order: int) -> Dictionary:
	return {"kind": "line", "start": start, "end": end, "color": color, "width": width, "antialiased": antialiased, "order": order}

static func _circle_command(center: Vector2, radius: float, color: Color, order: int) -> Dictionary:
	return {"kind": "circle", "center": center, "radius": radius, "color": color, "order": order}
