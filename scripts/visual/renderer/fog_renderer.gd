extends RefCounted
class_name FogRenderer

const FOG_OUTLINE_COLOR: Color = Color(0.5, 0.6, 0.75, 0.75)


static func get_fog_color(context: Dictionary) -> Color:
	if bool(context.get("visible", false)):
		return Color(0.0, 0.0, 0.0, clampf(float(context.get("visible_alpha", 0.0)), 0.0, 1.0))
	if bool(context.get("explored", false)):
		return Color(0.03, 0.05, 0.08, clampf(float(context.get("explored_alpha", 0.18)), 0.0, 1.0))
	return Color(0.01, 0.01, 0.02, clampf(float(context.get("unexplored_alpha", 0.42)), 0.0, 1.0))


static func build_cell_overlay_commands(context: Dictionary) -> Array[Dictionary]:
	var fog_color: Color = Color(context.get("fog_color", Color.TRANSPARENT))
	if fog_color.a <= 0.0:
		return []
	var diamond_points: PackedVector2Array = PackedVector2Array(context.get("diamond_points", PackedVector2Array()))
	if diamond_points.size() < 4:
		return []
	var commands: Array[Dictionary] = [_polygon_command(diamond_points, fog_color, 0)]
	if bool(context.get("draw_outlines", false)):
		var order: int = 1
		for edge_index in range(diamond_points.size()):
			var next_index: int = (edge_index + 1) % diamond_points.size()
			commands.append(_line_command(diamond_points[edge_index], diamond_points[next_index], FOG_OUTLINE_COLOR, 1.0, false, order))
			order += 1
	return commands


static func build_wall_overlay_commands(context: Dictionary) -> Array[Dictionary]:
	var fog_color: Color = Color(context.get("fog_color", Color.TRANSPARENT))
	if fog_color.a <= 0.0:
		return []
	var left_face: PackedVector2Array = PackedVector2Array(context.get("left_face", PackedVector2Array()))
	var right_face: PackedVector2Array = PackedVector2Array(context.get("right_face", PackedVector2Array()))
	var top_face: PackedVector2Array = PackedVector2Array(context.get("top_face", PackedVector2Array()))
	if left_face.size() < 4 or right_face.size() < 4 or top_face.size() < 4:
		return []
	var commands: Array[Dictionary] = [
		_polygon_command(left_face, fog_color, 0),
		_polygon_command(right_face, fog_color, 1),
		_polygon_command(top_face, fog_color, 2),
	]
	if bool(context.get("draw_outlines", false)):
		var order: int = 3
		for edge_index in range(top_face.size()):
			var next_top_index: int = (edge_index + 1) % top_face.size()
			commands.append(_line_command(top_face[edge_index], top_face[next_top_index], FOG_OUTLINE_COLOR, 1.0, false, order))
			order += 1
	return commands


static func _polygon_command(points: PackedVector2Array, color: Color, order: int) -> Dictionary:
	return {"kind": "polygon", "points": points, "color": color, "order": order}


static func _line_command(start: Vector2, end: Vector2, color: Color, width: float, antialiased: bool, order: int) -> Dictionary:
	return {"kind": "line", "start": start, "end": end, "color": color, "width": width, "antialiased": antialiased, "order": order}
