extends SceneTree

const OverlayRendererRef = preload("res://scripts/visual/renderer/overlay_renderer.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_check_mouse_selection_commands()
	_check_mouse_selection_without_wall_object()
	_check_interaction_rects()
	_check_interaction_pulse()
	_check_interaction_commands()
	_check_stable_output()
	if failures.is_empty():
		print("OverlayRenderer contract OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _diamond(center: Vector2 = Vector2.ZERO) -> PackedVector2Array:
	return PackedVector2Array([
		center + Vector2(0.0, -10.0),
		center + Vector2(20.0, 0.0),
		center + Vector2(0.0, 10.0),
		center + Vector2(-20.0, 0.0)
	])


func _base_context() -> Dictionary:
	return {
		"kind": "world_object",
		"object_type": "terminal",
		"default_center": Vector2(100.0, 80.0),
		"wall_center": Vector2(100.0, 62.5),
		"tile_half_size": Vector2(64.0, 36.0),
		"wall_height": 50.0,
		"object_marker_height": 24.0,
		"time_seconds": 0.0
	}


func _check_mouse_selection_commands() -> void:
	var first: PackedVector2Array = _diamond(Vector2.ZERO)
	var second: PackedVector2Array = _diamond(Vector2(100.0, 0.0))
	var commands: Array[Dictionary] = OverlayRendererRef.build_mouse_selection_commands({
		"route_point_sets": [first, second],
		"selected_points": first,
		"action_points": first,
		"wall_anchor_points": first,
		"attached_wall_points": first,
		"has_wall_object_center": true,
		"wall_object_center": Vector2(50.0, 60.0)
	})
	_expect(commands.size() == 29, "mouse selection command count changed")
	_expect_polygon(commands[0], first, Color(0.29, 0.75, 0.95, 0.14), "first route fill")
	_expect_line(commands[1], first[0], first[1], Color(0.29, 0.75, 0.95, 0.45), 1.6, false, "first route outline edge 0")
	_expect_line(commands[4], first[3], first[0], Color(0.29, 0.75, 0.95, 0.45), 1.6, false, "first route outline closing edge")
	_expect_polygon(commands[5], second, Color(0.29, 0.75, 0.95, 0.14), "second route fill")
	_expect_line(commands[6], second[0], second[1], Color(0.29, 0.75, 0.95, 0.45), 1.6, false, "second route input order")
	_expect_polygon(commands[10], first, Color(0.85, 0.93, 1.0, 0.09), "selected fill")
	_expect_line(commands[11], first[0], first[1], Color(0.8, 0.97, 1.0, 1.0), 2.6, false, "selected outline")
	_expect_polygon(commands[15], first, Color(0.98, 0.66, 0.35, 0.24), "action fill")
	_expect_line(commands[16], first[0], first[1], Color(0.99, 0.75, 0.45, 1.0), 2.8, false, "action outline")
	_expect_line(commands[20], first[0], first[1], Color(0.35, 0.92, 1.0, 1.0), 2.8, false, "wall anchor outline")
	_expect_line(commands[24], first[0], first[1], Color(1.0, 0.8, 0.35, 1.0), 2.8, false, "attached wall outline")
	var marker: Dictionary = commands[28]
	_expect(str(marker.get("kind", "")) == "polyline", "wall object marker primitive changed")
	_expect(not bool(marker.get("closed", true)), "wall object marker must remain open")
	_expect(bool(marker.get("antialiased", false)), "wall object marker antialiasing changed")
	_expect(is_equal_approx(float(marker.get("width", 0.0)), 2.8), "wall object marker width changed")
	_expect(Color(marker.get("color", Color.BLACK)).is_equal_approx(Color(1.0, 0.96, 0.3, 1.0)), "wall object marker color changed")
	var marker_points: PackedVector2Array = PackedVector2Array(marker.get("points", PackedVector2Array()))
	_expect(marker_points.size() == 4, "wall object marker point count changed")
	_expect(marker_points[0].is_equal_approx(Vector2(50.0, 51.0)), "wall object marker top point changed")
	_expect(marker_points[1].is_equal_approx(Vector2(59.0, 60.0)), "wall object marker right point changed")
	_expect(marker_points[2].is_equal_approx(Vector2(50.0, 69.0)), "wall object marker bottom point changed")
	_expect(marker_points[3].is_equal_approx(Vector2(41.0, 60.0)), "wall object marker left point changed")


func _check_mouse_selection_without_wall_object() -> void:
	var commands: Array[Dictionary] = OverlayRendererRef.build_mouse_selection_commands({
		"route_point_sets": [],
		"selected_points": PackedVector2Array(),
		"action_points": PackedVector2Array(),
		"wall_anchor_points": PackedVector2Array(),
		"attached_wall_points": PackedVector2Array(),
		"has_wall_object_center": false,
		"wall_object_center": Vector2(50.0, 60.0)
	})
	_expect(commands.is_empty(), "unresolved wall object center must not emit marker")


func _check_interaction_rects() -> void:
	var base_context: Dictionary = _base_context()
	var default_rect: Rect2 = OverlayRendererRef.build_interaction_target_rect(base_context)
	_expect(default_rect.get_center().is_equal_approx(Vector2(100.0, 80.0)), "default interaction center changed")
	_expect(default_rect.size.is_equal_approx(Vector2(46.08, 43.92)), "default interaction size changed")
	var wall_context: Dictionary = base_context.duplicate(true)
	wall_context["kind"] = "wall"
	var wall_rect: Rect2 = OverlayRendererRef.build_interaction_target_rect(wall_context)
	_expect(wall_rect.get_center().is_equal_approx(Vector2(100.0, 62.5)), "wall interaction center changed")
	_expect(wall_rect.size.is_equal_approx(Vector2(60.8, 60.7)), "wall interaction size changed")
	var cable_context: Dictionary = base_context.duplicate(true)
	cable_context["kind"] = "cable"
	_expect(OverlayRendererRef.build_interaction_target_rect(cable_context).size.is_equal_approx(Vector2(55.04, 20.88)), "cable interaction size changed")
	var item_context: Dictionary = base_context.duplicate(true)
	item_context["kind"] = "item"
	_expect(OverlayRendererRef.build_interaction_target_rect(item_context).size.is_equal_approx(Vector2(33.28, 22.32)), "item interaction size changed")


func _check_interaction_pulse() -> void:
	_expect(is_equal_approx(OverlayRendererRef.get_interaction_pulse(0.0), 0.65), "interaction pulse baseline changed")
	_expect(is_equal_approx(OverlayRendererRef.get_interaction_pulse(PI / 10.0), 1.0), "interaction pulse peak changed")
	_expect(is_equal_approx(OverlayRendererRef.get_interaction_pulse(3.0 * PI / 10.0), 0.30), "interaction pulse trough changed")


func _check_interaction_commands() -> void:
	var commands: Array[Dictionary] = OverlayRendererRef.build_interaction_target_commands(_base_context())
	_expect(commands.size() == 16, "interaction corner command count changed")
	_expect_line(commands[0], Vector2(70.96, 52.04), Vector2(84.3808, 52.04), Color(0.02, 0.05, 0.07, 0.4878), 4.65, true, "corner 0 horizontal shadow")
	_expect_line(commands[1], Vector2(70.96, 52.04), Vector2(70.96, 65.4608), Color(0.02, 0.05, 0.07, 0.4878), 4.65, true, "corner 0 vertical shadow")
	_expect_line(commands[2], Vector2(70.96, 52.04), Vector2(84.3808, 52.04), Color(0.2, 0.9, 1.0, 0.6775), 2.65, true, "corner 0 horizontal color")
	_expect_line(commands[3], Vector2(70.96, 52.04), Vector2(70.96, 65.4608), Color(0.2, 0.9, 1.0, 0.6775), 2.65, true, "corner 0 vertical color")
	_expect_line(commands[4], Vector2(129.04, 52.04), Vector2(115.6192, 52.04), Color(0.02, 0.05, 0.07, 0.4878), 4.65, true, "corner 1 horizontal shadow")
	_expect_line(commands[5], Vector2(129.04, 52.04), Vector2(129.04, 65.4608), Color(0.02, 0.05, 0.07, 0.4878), 4.65, true, "corner 1 vertical shadow")
	_expect_line(commands[8], Vector2(129.04, 107.96), Vector2(115.6192, 107.96), Color(0.02, 0.05, 0.07, 0.4878), 4.65, true, "corner 2 direction")
	_expect_line(commands[12], Vector2(70.96, 107.96), Vector2(84.3808, 107.96), Color(0.02, 0.05, 0.07, 0.4878), 4.65, true, "corner 3 direction")
	for command in commands:
		_expect(command.has("kind") and command.has("start") and command.has("end") and command.has("color") and command.has("width") and command.has("antialiased") and command.has("order"), "interaction command missing required field")


func _check_stable_output() -> void:
	var context: Dictionary = _base_context()
	var first: Array[Dictionary] = OverlayRendererRef.build_interaction_target_commands(context)
	var second: Array[Dictionary] = OverlayRendererRef.build_interaction_target_commands(context)
	_expect(str(first) == str(second), "identical interaction input must produce stable output")
	var mouse_context: Dictionary = {"route_point_sets": [_diamond()], "has_wall_object_center": false}
	_expect(str(OverlayRendererRef.build_mouse_selection_commands(mouse_context)) == str(OverlayRendererRef.build_mouse_selection_commands(mouse_context)), "identical mouse input must produce stable output")


func _expect_polygon(command: Dictionary, points: PackedVector2Array, color: Color, label: String) -> void:
	_expect(str(command.get("kind", "")) == "polygon", "%s kind changed" % label)
	_expect(PackedVector2Array(command.get("points", PackedVector2Array())) == points, "%s points changed" % label)
	_expect(Color(command.get("color", Color.BLACK)).is_equal_approx(color), "%s color changed" % label)
	_expect(command.has("order"), "%s order missing" % label)


func _expect_line(command: Dictionary, start: Vector2, end: Vector2, color: Color, width: float, antialiased: bool, label: String) -> void:
	_expect(str(command.get("kind", "")) == "line", "%s kind changed" % label)
	_expect(Vector2(command.get("start", Vector2.ZERO)).is_equal_approx(start), "%s start changed" % label)
	_expect(Vector2(command.get("end", Vector2.ZERO)).is_equal_approx(end), "%s end changed" % label)
	_expect(Color(command.get("color", Color.BLACK)).is_equal_approx(color), "%s color changed" % label)
	_expect(is_equal_approx(float(command.get("width", 0.0)), width), "%s width changed" % label)
	_expect(bool(command.get("antialiased", not antialiased)) == antialiased, "%s antialiasing changed" % label)
	_expect(command.has("order"), "%s order missing" % label)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
