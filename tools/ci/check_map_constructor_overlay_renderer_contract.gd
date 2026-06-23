extends SceneTree

const Renderer = preload("res://scripts/visual/renderer/map_constructor_overlay_renderer.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_check_core_passes()
	_check_arrows_invalid_order_and_stability()
	if failures.is_empty():
		print("MapConstructorOverlayRenderer contract OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _diamond(center: Vector2) -> PackedVector2Array:
	return PackedVector2Array([center + Vector2(0.0, -10.0), center + Vector2(20.0, 0.0), center + Vector2(0.0, 10.0), center + Vector2(-20.0, 0.0)])

func _check_core_passes() -> void:
	var d := _diamond(Vector2.ZERO)
	var commands := Renderer.build_commands({
		"selected_points": d,
		"hover_points": d,
		"preview_points": d,
		"preview_mode": "normal",
		"room_walls": [{"points": d, "center": Vector2(10.0, 10.0)}],
		"room_door_centers": [Vector2(20.0, 20.0)],
		"room_terminal_centers": [Vector2(30.0, 30.0)],
		"room_floor_point_sets": [d],
		"multi_select_point_sets": [d, _diamond(Vector2(100.0, 0.0))],
		"validation_markers": [
			{"center": Vector2(1.0, 1.0), "severity": "info"},
			{"center": Vector2(2.0, 2.0), "expected_invalid": true, "severity": "error"},
			{"center": Vector2(3.0, 3.0), "severity": "error"},
			{"center": Vector2(4.0, 4.0), "severity": "warning"},
		],
		"links": [{"start": Vector2(1.0, 2.0), "end": Vector2(3.0, 4.0)}, {"start": Vector2(5.0, 6.0), "end": Vector2(7.0, 8.0), "broken": true}],
		"power_links": [{"start": Vector2(9.0, 10.0), "end": Vector2(11.0, 12.0)}]
	})
	_expect(commands.size() == 40, "complete command count changed")
	_expect_polygon(commands[0], d, Color(1.0, 0.92, 0.24, 0.11), "selected fill")
	_expect_line(commands[1], d[0], d[1], Color(1.0, 0.92, 0.24, 0.95), 2.4, false, "selected edge")
	_expect_line(commands[4], d[3], d[0], Color(1.0, 0.92, 0.24, 0.95), 2.4, false, "selected closing edge")
	_expect_line(commands[5], d[0], d[1], Color(0.72, 0.92, 1.0, 0.45), 1.2, false, "hover edge")
	_expect_polygon(commands[9], d, Color(0.35, 1.0, 0.85, 0.16), "normal preview fill")
	_expect_line(commands[10], d[0], d[1], Color(0.45, 1.0, 0.92, 1.0), 2.2, false, "normal preview stroke")
	_expect_line(commands[14], d[0], d[1], Color(0.95, 0.74, 0.28, 0.42), 1.5, false, "wall outline")
	_expect_circle(commands[18], Vector2(10.0, 2.0), 2.1, Color(0.45, 0.9, 1.0, 0.76), "wall marker")
	_expect_circle(commands[19], Vector2(15.0, 11.0), 2.8, Color(1.0, 0.76, 0.28, 0.88), "door marker")
	_expect_circle(commands[20], Vector2(35.0, 21.0), 2.8, Color(0.44, 0.9, 1.0, 0.88), "terminal marker")
	_expect_line(commands[21], d[0], d[1], Color(0.56, 0.78, 0.96, 0.48), 1.15, false, "floor outline")
	_expect_line(commands[25], d[0], d[1], Color(0.75, 0.85, 1.0, 0.8), 1.4, false, "multi select first")
	_expect_line(commands[29], Vector2(100.0, -10.0), Vector2(120.0, 0.0), Color(0.75, 0.85, 1.0, 0.8), 1.4, false, "multi select second order")
	_expect_circle(commands[33], Vector2(1.0, 1.0), 6.0, Color(0.62, 0.8, 1.0, 0.95), "validation info")
	_expect_circle(commands[34], Vector2(2.0, 2.0), 6.0, Color(0.74, 0.66, 0.86, 0.95), "validation expected precedence")
	_expect_circle(commands[35], Vector2(3.0, 3.0), 6.0, Color(1.0, 0.3, 0.3, 0.95), "validation error")
	_expect_circle(commands[36], Vector2(4.0, 4.0), 6.0, Color(1.0, 0.74, 0.3, 0.95), "validation warning")
	_expect_line(commands[37], Vector2(1.0, 2.0), Vector2(3.0, 4.0), Color(0.9, 0.58, 1.0, 0.85), 1.8, false, "normal link")
	_expect_line(commands[38], Vector2(5.0, 6.0), Vector2(7.0, 8.0), Color(1.0, 0.3, 0.3, 0.9), 1.8, false, "broken link")
	_expect_line(commands[39], Vector2(9.0, 10.0), Vector2(11.0, 12.0), Color(0.45, 0.9, 1.0, 0.65), 1.2, false, "power link")
	_check_preview_mode("blocked", Color(1.0, 0.35, 0.25, 0.2), Color(1.0, 0.55, 0.3, 1.0))
	_check_preview_mode("destructive", Color(1.0, 0.62, 0.22, 0.17), Color(1.0, 0.7, 0.3, 1.0))

func _check_preview_mode(mode: String, fill: Color, stroke: Color) -> void:
	var d := _diamond(Vector2.ZERO)
	var commands := Renderer.build_commands({"preview_points": d, "preview_mode": mode})
	_expect_polygon(commands[0], d, fill, "%s preview fill" % mode)
	_expect_line(commands[1], d[0], d[1], stroke, 2.2, false, "%s preview stroke" % mode)

func _check_arrows_invalid_order_and_stability() -> void:
	var commands := Renderer.build_commands({"selected_points": PackedVector2Array([Vector2.ZERO]), "wall_side_arrows": [
		{"center": Vector2.ZERO, "wall_side": "north", "mode": "preview"},
		{"center": Vector2.ZERO, "wall_side": "east", "mode": "selected"},
		{"center": Vector2.ZERO, "wall_side": "south", "mode": "preview"},
		{"center": Vector2.ZERO, "wall_side": "west", "mode": "selected"},
		{"center": Vector2.ZERO, "wall_side": "other", "mode": "preview"},
	]})
	_expect(commands.size() == 10, "invalid projected input should emit no selected command")
	_expect_line(commands[0], Vector2.ZERO, Vector2(0.0, -16.0), Color(0.82, 0.95, 1.0, 1.0), 2.0, false, "north arrow")
	_expect_circle(commands[1], Vector2(0.0, -16.0), 3.0, Color(0.82, 0.95, 1.0, 1.0), "north arrow tip")
	_expect_line(commands[2], Vector2.ZERO, Vector2(16.0, 0.0), Color(1.0, 0.88, 0.35, 1.0), 2.0, false, "east arrow")
	_expect_line(commands[4], Vector2.ZERO, Vector2(0.0, 16.0), Color(0.82, 0.95, 1.0, 1.0), 2.0, false, "south arrow")
	_expect_line(commands[6], Vector2.ZERO, Vector2(-16.0, 0.0), Color(1.0, 0.88, 0.35, 1.0), 2.0, false, "west arrow")
	_expect_line(commands[8], Vector2.ZERO, Vector2(0.0, -16.0), Color(0.82, 0.95, 1.0, 1.0), 2.0, false, "default arrow")
	for index in range(commands.size()):
		_expect(int(commands[index].get("order", -1)) == index, "orders must be monotonic")
		_expect(commands[index].has("kind") and commands[index].has("color") and commands[index].has("order"), "command missing required fields")
	var context := {"wall_side_arrows": [{"center": Vector2.ZERO, "wall_side": "north", "mode": "preview"}]}
	_expect(str(Renderer.build_commands(context)) == str(Renderer.build_commands(context)), "identical input must produce stable output")

func _expect_polygon(command: Dictionary, points: PackedVector2Array, color: Color, label: String) -> void:
	_expect(str(command.get("kind", "")) == "polygon", "%s kind" % label)
	_expect(PackedVector2Array(command.get("points", PackedVector2Array())) == points, "%s points" % label)
	_expect(Color(command.get("color", Color.BLACK)).is_equal_approx(color), "%s color" % label)

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

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
