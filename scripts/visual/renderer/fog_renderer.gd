extends RefCounted
class_name FogRenderer

const FOG_OUTLINE_COLOR: Color = Color(0.5, 0.6, 0.75, 0.75)


static func get_fog_color(context: Dictionary) -> Color:
	if _read_bool(context, "visible", false):
		return Color(0.0, 0.0, 0.0, clampf(_read_float(context, "visible_alpha", 0.0), 0.0, 1.0))
	if _read_bool(context, "explored", false):
		return Color(0.03, 0.05, 0.08, clampf(_read_float(context, "explored_alpha", 0.18), 0.0, 1.0))
	return Color(0.01, 0.01, 0.02, clampf(_read_float(context, "unexplored_alpha", 0.42), 0.0, 1.0))


static func build_cell_overlay_commands(context: Dictionary) -> Array[Dictionary]:
	var fog_color: Color = _read_color(context, "fog_color", Color.TRANSPARENT)
	if fog_color.a <= 0.0:
		return []
	var diamond_points: PackedVector2Array = _read_points(context, "diamond_points")
	if diamond_points.size() < 4:
		return []
	var commands: Array[Dictionary] = [_polygon_command(diamond_points, fog_color, 0)]
	if _read_bool(context, "draw_outlines", false):
		var order: int = 1
		for edge_index in range(diamond_points.size()):
			var next_index: int = (edge_index + 1) % diamond_points.size()
			commands.append(_line_command(diamond_points[edge_index], diamond_points[next_index], FOG_OUTLINE_COLOR, 1.0, false, order))
			order += 1
	return commands


static func build_wall_overlay_commands(context: Dictionary) -> Array[Dictionary]:
	var fog_color: Color = _read_color(context, "fog_color", Color.TRANSPARENT)
	if fog_color.a <= 0.0:
		return []
	var left_face: PackedVector2Array = _read_points(context, "left_face")
	var right_face: PackedVector2Array = _read_points(context, "right_face")
	var top_face: PackedVector2Array = _read_points(context, "top_face")
	if left_face.size() < 4 or right_face.size() < 4 or top_face.size() < 4:
		return []
	var commands: Array[Dictionary] = [
		_polygon_command(left_face, fog_color, 0),
		_polygon_command(right_face, fog_color, 1),
		_polygon_command(top_face, fog_color, 2),
	]
	if _read_bool(context, "draw_outlines", false):
		var order: int = 3
		for edge_index in range(top_face.size()):
			var next_top_index: int = (edge_index + 1) % top_face.size()
			commands.append(_line_command(top_face[edge_index], top_face[next_top_index], FOG_OUTLINE_COLOR, 1.0, false, order))
			order += 1
	return commands


static func _read_color(context: Dictionary, key: String, default_value: Color) -> Color:
	if not context.has(key):
		return default_value
	var value: Variant = context.get(key)
	if typeof(value) == TYPE_COLOR:
		return Color(value)
	return default_value


static func _read_points(context: Dictionary, key: String) -> PackedVector2Array:
	if not context.has(key):
		return PackedVector2Array()
	var value: Variant = context.get(key)
	if typeof(value) == TYPE_PACKED_VECTOR2_ARRAY:
		return PackedVector2Array(value)
	if typeof(value) != TYPE_ARRAY:
		return PackedVector2Array()
	var points := PackedVector2Array()
	for point_variant in Array(value):
		if typeof(point_variant) != TYPE_VECTOR2:
			return PackedVector2Array()
		points.append(Vector2(point_variant))
	return points


static func _read_bool(context: Dictionary, key: String, default_value: bool) -> bool:
	if not context.has(key):
		return default_value
	var value: Variant = context.get(key)
	if typeof(value) == TYPE_BOOL:
		return value
	return default_value


static func _read_float(context: Dictionary, key: String, default_value: float) -> float:
	if not context.has(key):
		return default_value
	var value: Variant = context.get(key)
	if typeof(value) == TYPE_FLOAT or typeof(value) == TYPE_INT:
		return float(value)
	return default_value


static func _polygon_command(points: PackedVector2Array, color: Color, order: int) -> Dictionary:
	return {"kind": "polygon", "points": points, "color": color, "order": order}


static func _line_command(start: Vector2, end: Vector2, color: Color, width: float, antialiased: bool, order: int) -> Dictionary:
	return {"kind": "line", "start": start, "end": end, "color": color, "width": width, "antialiased": antialiased, "order": order}
