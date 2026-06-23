extends SceneTree

const Renderer = preload("res://scripts/visual/renderer/fog_renderer.gd")

var failures: Array[String] = []


func _initialize() -> void:
	_check_colors()
	_check_cell_commands()
	_check_wall_commands()
	_check_stability()
	if failures.is_empty():
		print("FogRenderer contract OK")
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


func _check_colors() -> void:
	_expect(Renderer.get_fog_color({"visible": true, "explored": true, "visible_alpha": 0.4, "explored_alpha": 0.9}).is_equal_approx(Color(0.0, 0.0, 0.0, 0.4)), "visible state must take precedence over explored")
	_expect(Renderer.get_fog_color({"visible": true, "visible_alpha": -1.0}).is_equal_approx(Color(0.0, 0.0, 0.0, 0.0)), "visible alpha clamps low")
	_expect(Renderer.get_fog_color({"visible": true, "visible_alpha": 2.0}).is_equal_approx(Color(0.0, 0.0, 0.0, 1.0)), "visible alpha clamps high")
	_expect(Renderer.get_fog_color({"explored": true, "explored_alpha": -1.0}).is_equal_approx(Color(0.03, 0.05, 0.08, 0.0)), "explored alpha clamps low")
	_expect(Renderer.get_fog_color({"explored": true, "explored_alpha": 2.0}).is_equal_approx(Color(0.03, 0.05, 0.08, 1.0)), "explored alpha clamps high")
	_expect(Renderer.get_fog_color({"unexplored_alpha": -1.0}).is_equal_approx(Color(0.01, 0.01, 0.02, 0.0)), "unexplored alpha clamps low")
	_expect(Renderer.get_fog_color({"unexplored_alpha": 2.0}).is_equal_approx(Color(0.01, 0.01, 0.02, 1.0)), "unexplored alpha clamps high")
	_expect(Renderer.get_fog_color({"visible": "bad", "explored": true, "explored_alpha": "bad"}).is_equal_approx(Color(0.03, 0.05, 0.08, 0.18)), "malformed color context uses safe typed defaults")


func _check_cell_commands() -> void:
	var diamond := _diamond()
	var fill_only := Renderer.build_cell_overlay_commands({"diamond_points": diamond, "fog_color": Color(0.1, 0.2, 0.3, 0.4), "draw_outlines": false})
	_expect(fill_only.size() == 1, "cell outlines disabled emits one polygon")
	_expect_polygon(fill_only[0], diamond, Color(0.1, 0.2, 0.3, 0.4), "cell fog fill only")
	_assert_schema_and_order(fill_only, "cell fill only")

	var commands := Renderer.build_cell_overlay_commands({"diamond_points": diamond, "fog_color": Color(0.1, 0.2, 0.3, 0.4), "draw_outlines": true})
	_expect(commands.size() == 5, "cell fog command count")
	_expect_polygon(commands[0], diamond, Color(0.1, 0.2, 0.3, 0.4), "cell fog fill")
	_expect_line(commands[1], diamond[0], diamond[1], Color(0.5, 0.6, 0.75, 0.75), 1.0, false, "cell fog first outline")
	_expect_line(commands[4], diamond[3], diamond[0], Color(0.5, 0.6, 0.75, 0.75), 1.0, false, "cell fog closing outline")
	_assert_schema_and_order(commands, "cell fog")

	_expect(Renderer.build_cell_overlay_commands({"diamond_points": PackedVector2Array([Vector2.ZERO, Vector2.RIGHT, Vector2.ONE]), "fog_color": Color.WHITE}).is_empty(), "cell fog rejects polygons with fewer than four points")
	_expect(Renderer.build_cell_overlay_commands({"diamond_points": diamond, "fog_color": Color.TRANSPARENT}).is_empty(), "transparent cell fog emits no commands")
	_expect(Renderer.build_cell_overlay_commands({}).is_empty(), "missing cell context is safe")
	_expect(Renderer.build_cell_overlay_commands({"fog_color": Color.WHITE}).is_empty(), "missing cell geometry is safe")
	_expect(Renderer.build_cell_overlay_commands({"diamond_points": "bad", "fog_color": Color.WHITE}).is_empty(), "malformed cell geometry is safe")
	_expect(Renderer.build_cell_overlay_commands({"diamond_points": diamond, "fog_color": "bad"}).is_empty(), "malformed cell color is safe")
	var array_geometry := Renderer.build_cell_overlay_commands({"diamond_points": [diamond[0], diamond[1], diamond[2], diamond[3]], "fog_color": Color(0.2, 0.2, 0.2, 0.2)})
	_expect(array_geometry.size() == 1, "partial typed cell context with vector array is deterministic")
	_assert_schema_and_order(array_geometry, "cell vector array")


func _check_wall_commands() -> void:
	var left := _diamond(Vector2(0.0, 10.0))
	var right := _diamond(Vector2(20.0, 10.0))
	var top := _diamond(Vector2(10.0, 0.0))
	var fill_only := Renderer.build_wall_overlay_commands({"left_face": left, "right_face": right, "top_face": top, "fog_color": Color(0.2, 0.3, 0.4, 0.5), "draw_outlines": false})
	_expect(fill_only.size() == 3, "wall outlines disabled emits three polygons")
	_expect_polygon(fill_only[0], left, Color(0.2, 0.3, 0.4, 0.5), "wall left polygon order")
	_expect_polygon(fill_only[1], right, Color(0.2, 0.3, 0.4, 0.5), "wall right polygon order")
	_expect_polygon(fill_only[2], top, Color(0.2, 0.3, 0.4, 0.5), "wall top polygon order")
	_assert_schema_and_order(fill_only, "wall fill only")

	var commands := Renderer.build_wall_overlay_commands({"left_face": left, "right_face": right, "top_face": top, "fog_color": Color(0.2, 0.3, 0.4, 0.5), "draw_outlines": true})
	_expect(commands.size() == 7, "wall fog command count")
	_expect_polygon(commands[0], left, Color(0.2, 0.3, 0.4, 0.5), "wall left fog")
	_expect_polygon(commands[1], right, Color(0.2, 0.3, 0.4, 0.5), "wall right fog")
	_expect_polygon(commands[2], top, Color(0.2, 0.3, 0.4, 0.5), "wall top fog")
	_expect_line(commands[3], top[0], top[1], Color(0.5, 0.6, 0.75, 0.75), 1.0, false, "wall top outline")
	_expect_line(commands[4], top[1], top[2], Color(0.5, 0.6, 0.75, 0.75), 1.0, false, "wall outline only top face second edge")
	_expect_line(commands[5], top[2], top[3], Color(0.5, 0.6, 0.75, 0.75), 1.0, false, "wall outline only top face third edge")
	_expect_line(commands[6], top[3], top[0], Color(0.5, 0.6, 0.75, 0.75), 1.0, false, "wall closing outline")
	_assert_schema_and_order(commands, "wall fog")

	_expect(Renderer.build_wall_overlay_commands({"left_face": left, "right_face": right, "top_face": top, "fog_color": Color.TRANSPARENT}).is_empty(), "transparent wall fog emits no commands")
	_expect(Renderer.build_wall_overlay_commands({"left_face": PackedVector2Array([Vector2.ZERO]), "right_face": right, "top_face": top, "fog_color": Color.WHITE}).is_empty(), "invalid left face is safe")
	_expect(Renderer.build_wall_overlay_commands({"left_face": left, "right_face": PackedVector2Array([Vector2.ZERO]), "top_face": top, "fog_color": Color.WHITE}).is_empty(), "invalid right face is safe")
	_expect(Renderer.build_wall_overlay_commands({"left_face": left, "right_face": right, "top_face": PackedVector2Array([Vector2.ZERO]), "fog_color": Color.WHITE}).is_empty(), "invalid top face is safe")
	_expect(Renderer.build_wall_overlay_commands({}).is_empty(), "missing wall context is safe")
	_expect(Renderer.build_wall_overlay_commands({"left_face": left, "fog_color": Color.WHITE}).is_empty(), "partial wall context is safe")
	_expect(Renderer.build_wall_overlay_commands({"left_face": "bad", "right_face": right, "top_face": top, "fog_color": Color.WHITE}).is_empty(), "malformed wall geometry is safe")
	_expect(Renderer.build_wall_overlay_commands({"left_face": left, "right_face": right, "top_face": top, "fog_color": "bad"}).is_empty(), "malformed wall color is safe")


func _check_stability() -> void:
	var diamond := _diamond()
	var cell_context := {"diamond_points": diamond, "fog_color": Color(0.1, 0.2, 0.3, 0.4), "draw_outlines": true}
	_expect(str(Renderer.build_cell_overlay_commands(cell_context)) == str(Renderer.build_cell_overlay_commands(cell_context)), "identical cell input must be stable")
	var wall_context := {"left_face": _diamond(Vector2(0.0, 10.0)), "right_face": _diamond(Vector2(20.0, 10.0)), "top_face": _diamond(Vector2(10.0, 0.0)), "fog_color": Color(0.2, 0.3, 0.4, 0.5), "draw_outlines": true}
	_expect(str(Renderer.build_wall_overlay_commands(wall_context)) == str(Renderer.build_wall_overlay_commands(wall_context)), "identical wall input must be stable")


func _assert_schema_and_order(commands: Array[Dictionary], label: String) -> void:
	for index in range(commands.size()):
		var command: Dictionary = commands[index]
		var kind: String = str(command.get("kind", ""))
		_expect(int(command.get("order", -1)) == index, "%s order %d" % [label, index])
		match kind:
			"polygon":
				_expect(command.has("points") and command.has("color") and command.has("order"), "%s polygon schema" % label)
			"line":
				_expect(command.has("start") and command.has("end") and command.has("color") and command.has("width") and command.has("antialiased") and command.has("order"), "%s line schema" % label)
			_:
				_expect(false, "%s unsupported kind %s" % [label, kind])


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


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
