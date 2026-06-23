extends RefCounted
class_name OverlayRenderer

static func build_mouse_selection_commands(context: Dictionary) -> Array[Dictionary]:
	var commands: Array[Dictionary] = []
	var order: int = 0
	var route_point_sets: Array = Array(context.get("route_point_sets", []))
	for route_points_variant in route_point_sets:
		var route_points: PackedVector2Array = PackedVector2Array(route_points_variant)
		if route_points.size() < 4:
			continue
		commands.append(_polygon_command(route_points, Color(0.29, 0.75, 0.95, 0.14), order))
		order += 1
		order = _append_outline_line_commands(commands, route_points, Color(0.29, 0.75, 0.95, 0.45), 1.6, false, order)

	var selected_points: PackedVector2Array = PackedVector2Array(context.get("selected_points", PackedVector2Array()))
	if selected_points.size() >= 4:
		commands.append(_polygon_command(selected_points, Color(0.85, 0.93, 1.0, 0.09), order))
		order += 1
		order = _append_outline_line_commands(commands, selected_points, Color(0.8, 0.97, 1.0, 1.0), 2.6, false, order)

	var action_points: PackedVector2Array = PackedVector2Array(context.get("action_points", PackedVector2Array()))
	if action_points.size() >= 4:
		commands.append(_polygon_command(action_points, Color(0.98, 0.66, 0.35, 0.24), order))
		order += 1
		order = _append_outline_line_commands(commands, action_points, Color(0.99, 0.75, 0.45, 1.0), 2.8, false, order)

	var wall_anchor_points: PackedVector2Array = PackedVector2Array(context.get("wall_anchor_points", PackedVector2Array()))
	if wall_anchor_points.size() >= 4:
		order = _append_outline_line_commands(commands, wall_anchor_points, Color(0.35, 0.92, 1.0, 1.0), 2.8, false, order)

	var attached_wall_points: PackedVector2Array = PackedVector2Array(context.get("attached_wall_points", PackedVector2Array()))
	if attached_wall_points.size() >= 4:
		order = _append_outline_line_commands(commands, attached_wall_points, Color(1.0, 0.8, 0.35, 1.0), 2.8, false, order)

	if bool(context.get("has_wall_object_center", false)):
		var center: Vector2 = Vector2(context.get("wall_object_center", Vector2.ZERO))
		var radius: float = 9.0
		var marker_points: PackedVector2Array = PackedVector2Array([
			center + Vector2(0.0, -radius),
			center + Vector2(radius, 0.0),
			center + Vector2(0.0, radius),
			center + Vector2(-radius, 0.0)
		])
		commands.append(_polyline_command(marker_points, Color(1.0, 0.96, 0.3, 1.0), 2.8, false, true, order))

	return commands


static func build_interaction_target_rect(context: Dictionary) -> Rect2:
	var kind: String = str(context.get("kind", "world_object")).strip_edges().to_lower()
	var object_type: String = str(context.get("object_type", "")).strip_edges().to_lower()
	var center: Vector2 = Vector2(context.get("default_center", Vector2.ZERO))
	var half: Vector2 = Vector2(context.get("tile_half_size", Vector2.ZERO))
	var wall_height: float = float(context.get("wall_height", 0.0))
	var object_marker_height: float = float(context.get("object_marker_height", 0.0))
	var size: Vector2 = Vector2(half.x * 0.72, half.y * 1.05)
	if kind == "wall" or object_type.contains("wall"):
		center = Vector2(context.get("wall_center", center))
		size = Vector2(half.x * 0.95, half.y * 1.2 + wall_height * 0.35)
	elif kind == "cable" or object_type.contains("cable"):
		size = Vector2(half.x * 0.86, half.y * 0.58)
	elif kind == "item":
		size = Vector2(half.x * 0.52, half.y * 0.62)
	else:
		size = Vector2(half.x * 0.72, half.y * 0.92 + object_marker_height * 0.45)
	return Rect2(center - size * 0.5, size)


static func get_interaction_pulse(time_seconds: float) -> float:
	return 0.65 + 0.35 * sin(time_seconds * 5.0)


static func build_interaction_target_commands(context: Dictionary) -> Array[Dictionary]:
	var commands: Array[Dictionary] = []
	var rect: Rect2 = build_interaction_target_rect(context).grow(6.0)
	var pulse: float = get_interaction_pulse(float(context.get("time_seconds", 0.0)))
	var color: Color = Color(0.2, 0.9, 1.0, 0.45 + 0.35 * pulse)
	var shadow: Color = Color(0.02, 0.05, 0.07, color.a * 0.72)
	var corner: float = maxf(10.0, minf(rect.size.x, rect.size.y) * 0.24)
	var width: float = 2.0 + pulse
	var points: Array[Vector2] = [
		rect.position,
		rect.position + Vector2(rect.size.x, 0.0),
		rect.position + rect.size,
		rect.position + Vector2(0.0, rect.size.y)
	]
	var order: int = 0
	for idx in range(points.size()):
		var point: Vector2 = points[idx]
		var sx: float = 1.0 if idx == 0 or idx == 3 else -1.0
		var sy: float = 1.0 if idx == 0 or idx == 1 else -1.0
		commands.append(_line_command(point, point + Vector2(corner * sx, 0.0), shadow, width + 2.0, true, order))
		order += 1
		commands.append(_line_command(point, point + Vector2(0.0, corner * sy), shadow, width + 2.0, true, order))
		order += 1
		commands.append(_line_command(point, point + Vector2(corner * sx, 0.0), color, width, true, order))
		order += 1
		commands.append(_line_command(point, point + Vector2(0.0, corner * sy), color, width, true, order))
		order += 1
	return commands


static func _append_outline_line_commands(commands: Array[Dictionary], points: PackedVector2Array, color: Color, width: float, antialiased: bool, order: int) -> int:
	for edge_index in range(points.size()):
		var next_index: int = (edge_index + 1) % points.size()
		commands.append(_line_command(points[edge_index], points[next_index], color, width, antialiased, order))
		order += 1
	return order


static func _polygon_command(points: PackedVector2Array, color: Color, order: int) -> Dictionary:
	return {"kind": "polygon", "points": points, "color": color, "order": order}


static func _polyline_command(points: PackedVector2Array, color: Color, width: float, closed: bool, antialiased: bool, order: int) -> Dictionary:
	return {"kind": "polyline", "points": points, "color": color, "width": width, "closed": closed, "antialiased": antialiased, "order": order}


static func _line_command(start: Vector2, end: Vector2, color: Color, width: float, antialiased: bool, order: int) -> Dictionary:
	return {"kind": "line", "start": start, "end": end, "color": color, "width": width, "antialiased": antialiased, "order": order}
