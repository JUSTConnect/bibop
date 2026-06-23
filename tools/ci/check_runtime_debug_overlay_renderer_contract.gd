extends SceneTree

const Renderer = preload("res://scripts/visual/renderer/runtime_debug_overlay_renderer.gd")

var failures: Array[String] = []


func _initialize() -> void:
	_check_origin_and_helper()
	_check_wall_mount_and_wall_run()
	_check_floor_world_and_fan()
	_check_asset_grounding_and_door()
	_check_wall_debug()
	_check_stability()
	if failures.is_empty():
		print("RuntimeDebugOverlayRenderer contract OK")
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
		center + Vector2(-20.0, 0.0),
	])


func _check_origin_and_helper() -> void:
	_expect(Renderer.build_origin_commands(false).is_empty(), "disabled origin must emit no commands")
	var origin := Renderer.build_origin_commands(true)
	_expect(origin.size() == 1, "origin command count")
	_expect_circle(origin[0], Vector2.ZERO, 3.0, Color(0.8, 0.95, 1.0, 0.75), "origin")
	_assert_schema_and_order(origin, "origin")

	var d := _diamond()
	var helper := Renderer.build_helper_preview_commands(d)
	_expect(helper.size() == 5, "helper command count")
	_expect_polygon(helper[0], d, Color(0.2, 0.8, 1.0, 0.15), "helper fill")
	_expect_line(helper[1], d[0], d[1], Color(0.2, 0.8, 1.0, 0.9), 1.0, false, "helper first edge")
	_expect_line(helper[4], d[3], d[0], Color(0.2, 0.8, 1.0, 0.9), 1.0, false, "helper closing edge")
	_assert_schema_and_order(helper, "helper")


func _check_wall_mount_and_wall_run() -> void:
	var mount := Renderer.build_wall_mount_zone_commands([
		{"center": Vector2(10.0, 20.0), "side": "south"},
		{"center": Vector2(30.0, 40.0), "side": "east"},
	])
	_expect(mount.size() == 4, "wall mount command count")
	_expect_circle(mount[0], Vector2(10.0, 20.0), 2.8, Color(0.35, 0.98, 0.86, 0.95), "wall mount marker")
	_expect_text(mount[1], Vector2(13.0, 16.0), "S", 12.0, 10, Color(0.9, 0.98, 1.0, 0.9), "wall mount label")
	_expect_text(mount[3], Vector2(33.0, 36.0), "E", 12.0, 10, Color(0.9, 0.98, 1.0, 0.9), "wall mount second label")
	_assert_schema_and_order(mount, "wall mount")

	var wall_run := Renderer.build_wall_run_commands([{
		"shape": "end_cap_north",
		"run_x": true,
		"run_y": true,
		"has_cap": true,
		"label_position": Vector2(4.0, 5.0),
		"edges": [
			{"start": Vector2.ZERO, "end": Vector2.RIGHT, "connected": true},
			{"start": Vector2.RIGHT, "end": Vector2.ONE, "connected": false},
		],
	}])
	_expect(wall_run.size() == 3, "wall run command count")
	_expect_text(wall_run[0], Vector2(4.0, 5.0), "end_cap_north RX RY cap", 96.0, 8, Color(1.0, 0.92, 0.42, 0.95), "wall run label")
	_expect_line(wall_run[1], Vector2.ZERO, Vector2.RIGHT, Color(0.25, 1.0, 0.78, 0.82), 1.2, false, "connected wall run edge")
	_expect_line(wall_run[2], Vector2.RIGHT, Vector2.ONE, Color(1.0, 0.55, 0.2, 0.9), 1.2, false, "disconnected wall run edge")
	_assert_schema_and_order(wall_run, "wall run")


func _check_floor_world_and_fan() -> void:
	var floor := Renderer.build_floor_join_commands([
		{"start": Vector2.ZERO, "end": Vector2.RIGHT, "shown": false},
		{"start": Vector2.RIGHT, "end": Vector2.ONE, "shown": true},
	])
	_expect(floor.size() == 2, "floor join command count")
	_expect_line(floor[0], Vector2.ZERO, Vector2.RIGHT, Color(0.25, 0.9, 1.0, 0.35), 0.65, false, "hidden floor edge")
	_expect_line(floor[1], Vector2.RIGHT, Vector2.ONE, Color(1.0, 0.82, 0.25, 0.92), 1.35, false, "shown floor edge")
	_assert_schema_and_order(floor, "floor join")

	var world := Renderer.build_world_marker_commands([
		{"center": Vector2(20.0, 30.0), "text": "A"},
		{"center": Vector2(40.0, 50.0), "text": "B"},
	])
	_expect(world.size() == 2, "world marker command count")
	_expect_text(world[0], Vector2(8.0, 34.0), "A", 48.0, 14, Color(1.0, 0.95, 0.4), "world marker")
	_expect_text(world[1], Vector2(28.0, 54.0), "B", 48.0, 14, Color(1.0, 0.95, 0.4), "world marker order")
	_assert_schema_and_order(world, "world markers")

	var fan := Renderer.build_fan_marker_commands({"center": Vector2(10.0, 10.0), "direction": Vector2.RIGHT})
	_expect(fan.size() == 2, "fan marker command count")
	_expect_polygon(fan[0], PackedVector2Array([Vector2(28.0, 10.0), Vector2(5.0, 20.0), Vector2(5.0, 0.0)]), Color(0.97, 0.97, 1.0, 0.96), "fan triangle")
	_expect_line(fan[1], Vector2(5.0, 10.0), Vector2(28.0, 10.0), Color(0.18, 0.28, 0.45, 0.9), 2.0, false, "fan direction line")
	_assert_schema_and_order(fan, "fan marker")


func _check_asset_grounding_and_door() -> void:
	var expected_rect := Rect2(1.0, 2.0, 30.0, 40.0)
	var actual_rect := Rect2(3.0, 4.0, 20.0, 25.0)
	var asset := Renderer.build_asset_alignment_commands({
		"asset_key": "crate",
		"anchor_position": Vector2(10.0, 20.0),
		"expected_rect": expected_rect,
		"actual_rect": actual_rect,
	})
	_expect(asset.size() == 7, "asset alignment command count")
	_expect_rect(asset[0], expected_rect, Color(1.0, 0.78, 0.22, 0.18), true, 1.0, false, "asset expected fill")
	_expect_rect(asset[1], expected_rect, Color(1.0, 0.78, 0.22, 0.95), false, 1.0, false, "asset expected outline")
	_expect_rect(asset[2], actual_rect, Color(0.2, 0.9, 1.0, 0.72), false, 1.0, false, "asset actual outline")
	_expect_circle(asset[5], Vector2(10.0, 20.0), 2.5, Color(1.0, 0.25, 0.25, 0.95), "asset anchor")
	_expect_text(asset[6], Vector2(3.0, -1.0), "crate", 40.0, 9, Color(1.0, 0.95, 0.78, 0.95), "asset label")
	_assert_schema_and_order(asset, "asset alignment")

	var d := _diamond()
	var grounding := Renderer.build_grounding_commands({"footprint_polygon": d, "visual_center": Vector2(5.0, 6.0), "grounding_type": "wall_mounted"})
	_expect(grounding.size() == 7, "grounding command count")
	_expect_polygon(grounding[0], d, Color(0.28, 0.7, 0.95, 0.08), "grounding footprint")
	_expect_circle(grounding[5], Vector2(5.0, 6.0), 2.0, Color(0.96, 0.96, 0.2, 0.95), "grounding center")
	_expect_text(grounding[6], Vector2(9.0, 0.0), "WM", 18.0, 10, Color(0.95, 1.0, 0.98, 0.95), "grounding label")
	_assert_schema_and_order(grounding, "grounding")

	var door := Renderer.build_door_opening_commands({
		"threshold_polygon": d,
		"insert_center": Vector2(10.0, 11.0),
		"adjacent_wall_centers": [Vector2(20.0, 21.0), Vector2(30.0, 31.0)],
		"orientation": "axis_y",
	})
	_expect(door.size() == 6, "door overlay command count")
	_expect_polygon(door[0], d, Color(0.2, 0.85, 1.0, 0.16), "door threshold fill")
	_expect_polyline(door[1], d, Color(0.35, 0.95, 1.0, 0.92), 1.2, true, "door threshold outline")
	_expect_circle(door[2], Vector2(10.0, 11.0), 3.5, Color(1.0, 0.3, 0.9, 0.95), "door insert")
	_expect_circle(door[4], Vector2(30.0, 31.0), 3.0, Color(0.95, 0.74, 0.28, 0.95), "door adjacent wall")
	_expect_text(door[5], Vector2(15.0, 4.0), "axis_y", 64.0, 9, Color(0.95, 1.0, 1.0, 0.95), "door orientation")
	_assert_schema_and_order(door, "door opening")


func _check_wall_debug() -> void:
	var d := _diamond()
	var commands := Renderer.build_wall_debug_commands({
		"show_topology": true,
		"topology": "corner_ne",
		"topology_position": Vector2(1.0, 2.0),
		"mount_zones": [{"points": d, "fill_color": Color(0.1, 0.2, 0.3, 0.4), "edge_color": Color(0.5, 0.6, 0.7, 0.8), "draw_outline": true}],
	})
	_expect(commands.size() == 3, "wall debug command count")
	_expect_text(commands[0], Vector2(1.0, 2.0), "corner_ne", 56.0, 9, Color(0.95, 0.96, 1.0, 0.9), "wall topology")
	_expect_polygon(commands[1], d, Color(0.1, 0.2, 0.3, 0.4), "mount band fill")
	_expect_polyline(commands[2], d, Color(0.5, 0.6, 0.7, 0.8), 1.1, true, "mount band outline")
	_assert_schema_and_order(commands, "wall debug")


func _check_stability() -> void:
	var context := {"center": Vector2(2.0, 3.0), "direction": Vector2(0.0, -1.0)}
	_expect(str(Renderer.build_fan_marker_commands(context)) == str(Renderer.build_fan_marker_commands(context)), "identical input must be stable")


func _assert_schema_and_order(commands: Array[Dictionary], label: String) -> void:
	for index in range(commands.size()):
		var command: Dictionary = commands[index]
		var kind: String = str(command.get("kind", ""))
		_expect(int(command.get("order", -1)) == index, "%s order %d" % [label, index])
		_expect(command.has("color") and command.has("kind") and command.has("order"), "%s common schema" % label)
		match kind:
			"polygon":
				_expect(command.has("points"), "%s polygon schema" % label)
			"polyline":
				_expect(command.has("points") and command.has("width") and command.has("antialiased"), "%s polyline schema" % label)
			"line":
				_expect(command.has("start") and command.has("end") and command.has("width") and command.has("antialiased"), "%s line schema" % label)
			"circle":
				_expect(command.has("center") and command.has("radius"), "%s circle schema" % label)
			"text":
				_expect(command.has("position") and command.has("text") and command.has("width") and command.has("font_size") and command.has("alignment"), "%s text schema" % label)
			"rect":
				_expect(command.has("rect") and command.has("filled") and command.has("width") and command.has("antialiased"), "%s rect schema" % label)
			_:
				_expect(false, "%s unsupported kind %s" % [label, kind])


func _expect_polygon(command: Dictionary, points: PackedVector2Array, color: Color, label: String) -> void:
	_expect(str(command.get("kind", "")) == "polygon", "%s kind" % label)
	_expect(PackedVector2Array(command.get("points", PackedVector2Array())) == points, "%s points" % label)
	_expect(Color(command.get("color", Color.BLACK)).is_equal_approx(color), "%s color" % label)


func _expect_polyline(command: Dictionary, points: PackedVector2Array, color: Color, width: float, antialiased: bool, label: String) -> void:
	_expect(str(command.get("kind", "")) == "polyline", "%s kind" % label)
	_expect(PackedVector2Array(command.get("points", PackedVector2Array())) == points, "%s points" % label)
	_expect(Color(command.get("color", Color.BLACK)).is_equal_approx(color), "%s color" % label)
	_expect(is_equal_approx(float(command.get("width", 0.0)), width), "%s width" % label)
	_expect(bool(command.get("antialiased", not antialiased)) == antialiased, "%s antialiased" % label)


func _expect_line(command: Dictionary, start: Vector2, end: Vector2, color: Color, width: float, antialiased: bool, label: String) -> void:
	_expect(str(command.get("kind", "")) == "line", "%s kind" % label)
	_expect(Vector2(command.get("start", Vector2.ZERO)).is_equal_approx(start), "%s start" % label)
	_expect(Vector2(command.get("end", Vector2.ZERO)).is_equal_approx(end), "%s end" % label)
	_expect(Color(command.get("color", Color.BLACK)).is_equal_approx(color), "%s color" % label)
	_expect(is_equal_approx(float(command.get("width", 0.0)), width), "%s width" % label)
	_expect(bool(command.get("antialiased", not antialiased)) == antialiased, "%s antialiased" % label)


func _expect_circle(command: Dictionary, center: Vector2, radius: float, color: Color, label: String) -> void:
	_expect(str(command.get("kind", "")) == "circle", "%s kind" % label)
	_expect(Vector2(command.get("center", Vector2.ZERO)).is_equal_approx(center), "%s center" % label)
	_expect(is_equal_approx(float(command.get("radius", 0.0)), radius), "%s radius" % label)
	_expect(Color(command.get("color", Color.BLACK)).is_equal_approx(color), "%s color" % label)


func _expect_text(command: Dictionary, position: Vector2, text: String, width: float, font_size: int, color: Color, label: String) -> void:
	_expect(str(command.get("kind", "")) == "text", "%s kind" % label)
	_expect(Vector2(command.get("position", Vector2.ZERO)).is_equal_approx(position), "%s position" % label)
	_expect(str(command.get("text", "")) == text, "%s text" % label)
	_expect(is_equal_approx(float(command.get("width", 0.0)), width), "%s width" % label)
	_expect(int(command.get("font_size", 0)) == font_size, "%s font size" % label)
	_expect(Color(command.get("color", Color.BLACK)).is_equal_approx(color), "%s color" % label)


func _expect_rect(command: Dictionary, rect: Rect2, color: Color, filled: bool, width: float, antialiased: bool, label: String) -> void:
	_expect(str(command.get("kind", "")) == "rect", "%s kind" % label)
	_expect(Rect2(command.get("rect", Rect2())).is_equal_approx(rect), "%s rect" % label)
	_expect(Color(command.get("color", Color.BLACK)).is_equal_approx(color), "%s color" % label)
	_expect(bool(command.get("filled", not filled)) == filled, "%s filled" % label)
	_expect(is_equal_approx(float(command.get("width", 0.0)), width), "%s width" % label)
	_expect(bool(command.get("antialiased", not antialiased)) == antialiased, "%s antialiased" % label)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
