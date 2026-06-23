extends SceneTree

const OverlayRendererRef = preload("res://scripts/visual/renderer/overlay_renderer.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_check_mouse_selection_commands()
	_check_interaction_rects()
	_check_interaction_commands()
	if failures.is_empty():
		print("OverlayRenderer contract OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _check_mouse_selection_commands() -> void:
	var diamond: PackedVector2Array = PackedVector2Array([Vector2(0.0, -10.0), Vector2(20.0, 0.0), Vector2(0.0, 10.0), Vector2(-20.0, 0.0)])
	var commands: Array[Dictionary] = OverlayRendererRef.build_mouse_selection_commands({
		"route_point_sets": [diamond],
		"selected_points": diamond,
		"action_points": diamond,
		"wall_anchor_points": diamond,
		"attached_wall_points": diamond,
		"has_wall_object_center": true,
		"wall_object_center": Vector2(50.0, 60.0)
	})
	_expect(commands.size() == 9, "mouse selection command count changed")
	_expect(str(commands[0].get("kind", "")) == "polygon", "route fill ordering changed")
	_expect(Color(commands[0].get("color", Color.BLACK)).is_equal_approx(Color(0.29, 0.75, 0.95, 0.14)), "route fill color changed")
	_expect(str(commands[1].get("kind", "")) == "polyline", "route outline primitive changed")
	_expect(is_equal_approx(float(commands[1].get("width", 0.0)), 1.6), "route outline width changed")
	_expect(Color(commands[3].get("color", Color.BLACK)).is_equal_approx(Color(0.8, 0.97, 1.0, 1.0)), "selected outline color changed")
	_expect(Color(commands[5].get("color", Color.BLACK)).is_equal_approx(Color(0.99, 0.75, 0.45, 1.0)), "action outline color changed")
	_expect(Color(commands[6].get("color", Color.BLACK)).is_equal_approx(Color(0.35, 0.92, 1.0, 1.0)), "wall anchor color changed")
	_expect(Color(commands[7].get("color", Color.BLACK)).is_equal_approx(Color(1.0, 0.8, 0.35, 1.0)), "attached wall color changed")
	var marker: Dictionary = commands[commands.size() - 1]
	_expect(str(marker.get("kind", "")) == "polyline", "wall object marker primitive changed")
	_expect(bool(marker.get("closed", false)), "wall object marker must be closed")
	_expect(PackedVector2Array(marker.get("points", PackedVector2Array()))[0].is_equal_approx(Vector2(50.0, 51.0)), "wall object marker radius changed")


func _check_interaction_rects() -> void:
	var base_context: Dictionary = {
		"kind": "world_object",
		"object_type": "terminal",
		"default_center": Vector2(100.0, 80.0),
		"wall_center": Vector2(100.0, 62.5),
		"tile_half_size": Vector2(64.0, 36.0),
		"wall_height": 50.0,
		"object_marker_height": 24.0,
		"time_seconds": 0.0
	}
	var default_rect: Rect2 = OverlayRendererRef.build_interaction_target_rect(base_context)
	_expect(default_rect.size.is_equal_approx(Vector2(46.08, 44.52)), "default interaction size changed")
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


func _check_interaction_commands() -> void:
	var commands: Array[Dictionary] = OverlayRendererRef.build_interaction_target_commands({
		"kind": "world_object",
		"object_type": "terminal",
		"default_center": Vector2(100.0, 80.0),
		"wall_center": Vector2(100.0, 62.5),
		"tile_half_size": Vector2(64.0, 36.0),
		"wall_height": 50.0,
		"object_marker_height": 24.0,
		"time_seconds": 0.0
	})
	_expect(commands.size() == 16, "interaction corner command count changed")
	_expect(is_equal_approx(OverlayRendererRef.get_interaction_pulse(0.0), 0.65), "interaction pulse baseline changed")
	_expect(str(commands[0].get("kind", "")) == "line", "interaction command primitive changed")
	_expect(Color(commands[0].get("color", Color.BLACK)).is_equal_approx(Color(0.02, 0.05, 0.07, 0.4878)), "interaction shadow color changed")
	_expect(Color(commands[2].get("color", Color.BLACK)).is_equal_approx(Color(0.2, 0.9, 1.0, 0.6775)), "interaction color changed")
	_expect(is_equal_approx(float(commands[0].get("width", 0.0)), 4.65), "interaction shadow width changed")
	_expect(is_equal_approx(float(commands[2].get("width", 0.0)), 2.65), "interaction color width changed")
	_expect(Vector2(commands[0].get("start", Vector2.ZERO)).is_equal_approx(Vector2(70.96, 51.74)), "interaction first corner start changed")
	_expect(Vector2(commands[0].get("end", Vector2.ZERO)).x > Vector2(commands[0].get("start", Vector2.ZERO)).x, "interaction first horizontal direction changed")
	_expect(Vector2(commands[4].get("end", Vector2.ZERO)).x < Vector2(commands[4].get("start", Vector2.ZERO)).x, "interaction second horizontal direction changed")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
