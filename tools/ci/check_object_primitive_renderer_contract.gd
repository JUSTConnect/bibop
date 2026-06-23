extends SceneTree

const ObjectPrimitiveRendererRef = preload("res://scripts/visual/renderer/object_primitive_renderer.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_check_profiles()
	_check_representative_shapes()
	_check_wall_mounted_shapes()
	_check_floor_base()
	_check_texture_accent()
	_check_malformed_contexts()
	_check_stability()
	if failures.is_empty():
		print("ObjectPrimitiveRenderer contract OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _expect_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s (expected=%s actual=%s)" % [message, var_to_str(expected), var_to_str(actual)])

func _expect_float(actual: float, expected: float, message: String) -> void:
	if not is_equal_approx(actual, expected):
		failures.append("%s (expected=%s actual=%s)" % [message, str(expected), str(actual)])

func _expect_vec(actual: Vector2, expected: Vector2, message: String) -> void:
	if not actual.is_equal_approx(expected):
		failures.append("%s (expected=%s actual=%s)" % [message, str(expected), str(actual)])

func _expect_color(actual: Color, expected: Color, message: String) -> void:
	if not (is_equal_approx(actual.r, expected.r) and is_equal_approx(actual.g, expected.g) and is_equal_approx(actual.b, expected.b) and is_equal_approx(actual.a, expected.a)):
		failures.append("%s (expected=%s actual=%s)" % [message, str(expected), str(actual)])

func _check_schema(commands: Array[Dictionary]) -> void:
	var last_order: int = -1
	for command in commands:
		var kind: String = str(command.get("kind", ""))
		_expect(command.has("order"), "%s command missing order" % kind)
		var order: int = int(command.get("order", -1))
		_expect(order > last_order, "%s command order must increase monotonically" % kind)
		last_order = order
		match kind:
			"polygon":
				for field in ["points", "color", "order"]:
					_expect(command.has(field), "polygon command missing %s" % field)
			"line":
				for field in ["start", "end", "color", "width", "antialiased", "order"]:
					_expect(command.has(field), "line command missing %s" % field)
			"circle":
				for field in ["center", "radius", "color", "order"]:
					_expect(command.has(field), "circle command missing %s" % field)
			"rect":
				for field in ["rect", "color", "filled", "width", "order"]:
					_expect(command.has(field), "rect command missing %s" % field)
			"arc":
				for field in ["center", "radius", "start_angle", "end_angle", "point_count", "color", "width", "antialiased", "order"]:
					_expect(command.has(field), "arc command missing %s" % field)
			"text":
				for field in ["position", "text", "color", "order"]:
					_expect(command.has(field), "text command missing %s" % field)
			_:
				failures.append("unsupported command kind: %s" % kind)

func _context(outlines: bool = false) -> Dictionary:
	return {
		"visual_center": Vector2(100.0, 80.0),
		"diamond": PackedVector2Array([Vector2(100.0, 40.0), Vector2(164.0, 80.0), Vector2(100.0, 120.0), Vector2(36.0, 80.0)]),
		"half_size": Vector2(64.0, 35.5),
		"marker_height": 18.0,
		"profile": {"base": Color(0.2, 0.3, 0.4, 0.5), "accent": Color(0.6, 0.7, 0.8, 0.9), "outline": Color(0.1, 0.2, 0.3, 0.4)},
		"outlines": outlines,
	}

func _check_profiles() -> void:
	var profiles: Dictionary = ObjectPrimitiveRendererRef.get_visual_profiles()
	_expect(profiles.has("door") and profiles.has("terminal") and profiles.has("generic_object"), "representative object profile catalog entries missing")
	_expect_eq(ObjectPrimitiveRendererRef.get_profile("").get("label"), "Generic Object", "empty profile key must safely fall back")
	_expect_eq(ObjectPrimitiveRendererRef.get_profile("missing").get("shape"), "small_marker", "missing profile key must safely fall back")

func _check_shape_case(shape: String, count_without_outlines: int, count_with_outlines: int, key_index: int, key_kind: String) -> Array[Dictionary]:
	var commands: Array[Dictionary] = ObjectPrimitiveRendererRef.build_shape_commands(shape, _context(false))
	var outlined: Array[Dictionary] = ObjectPrimitiveRendererRef.build_shape_commands(shape, _context(true))
	_expect_eq(commands.size(), count_without_outlines, "%s command count without outlines changed" % shape)
	_expect_eq(outlined.size(), count_with_outlines, "%s command count with outlines changed" % shape)
	_check_schema(commands)
	_check_schema(outlined)
	if commands.size() > key_index:
		_expect_eq(str(commands[key_index].get("kind", "")), key_kind, "%s key command kind changed" % shape)
	return commands

func _check_representative_shapes() -> void:
	var slab: Array[Dictionary] = _check_shape_case("slab", 2, 6, 0, "polygon")
	_expect_vec(PackedVector2Array(slab[0]["points"])[0], Vector2(100.0, 56.8), "slab first point changed")
	_expect_vec(Vector2(slab[1]["start"]), Vector2(63.52, 72.0), "slab accent start changed")
	_expect_float(float(slab[1]["width"]), 2.0, "slab accent width changed")
	var door: Array[Dictionary] = _check_shape_case("door_panel", 6, 10, 0, "polygon")
	_expect_vec(PackedVector2Array(door[0]["points"])[0], Vector2(89.96, 44.0), "door panel frame first point changed")
	_expect_float(float(door[2]["width"]), 2.2, "door panel side accent width changed")
	var pillar: Array[Dictionary] = _check_shape_case("pillar", 2, 6, 0, "polygon")
	_expect_vec(PackedVector2Array(pillar[0]["points"])[0], Vector2(92.32, 59.0), "pillar first point changed")
	var terminal: Array[Dictionary] = _check_shape_case("terminal_console", 3, 8, 1, "rect")
	_expect_eq(Rect2(terminal[1]["rect"]), Rect2(Vector2(93.96, 62.0), Vector2(12.08, 7.2)), "terminal screen rect changed")
	_expect_float(float(terminal[2]["width"]), 1.4, "terminal screen line width changed")
	var marker: Array[Dictionary] = _check_shape_case("small_marker", 2, 3, 0, "circle")
	_expect_vec(Vector2(marker[0]["center"]), Vector2(100.0, 74.0), "small marker center changed")
	_expect_float(float(marker[0]["radius"]), 5.68, "small marker radius changed")
	var line: Array[Dictionary] = _check_shape_case("line", 2, 3, 0, "line")
	_expect_vec(Vector2(line[0]["start"]), Vector2(83.36, 76.0), "line start changed")
	_expect_vec(Vector2(line[0]["end"]), Vector2(116.64, 76.0), "line end changed")
	var heat: Array[Dictionary] = _check_shape_case("heat_marker", 2, 3, 0, "circle")
	_expect_vec(Vector2(heat[0]["center"]), Vector2(100.0, 73.0), "heat marker center changed")
	_expect_float(float(heat[0]["radius"]), 6.39, "heat marker radius changed")
	_expect(ObjectPrimitiveRendererRef.build_shape_commands("", _context()).is_empty(), "empty unsupported shape should draw nothing")
	_expect(ObjectPrimitiveRendererRef.build_shape_commands("unsupported", _context()).is_empty(), "unsupported shape should draw nothing")

func _wall_context(profile_key: String, outlines: bool = false) -> Dictionary:
	return {"visual_center": Vector2(20.0, 30.0), "profile": ObjectPrimitiveRendererRef.get_profile(profile_key), "outlines": outlines}

func _check_wall_mounted_shapes() -> void:
	var door: Array[Dictionary] = ObjectPrimitiveRendererRef.build_wall_mounted_commands("door_terminal", _wall_context("door_terminal", true))
	_check_schema(door)
	_expect_eq(door.size(), 6, "door terminal outlined command count changed")
	_expect_eq(Rect2(door[4]["rect"]), Rect2(Vector2(15.0, 22.0), Vector2(10.0, 2.0)), "door terminal glow rect changed")
	var platform: Array[Dictionary] = ObjectPrimitiveRendererRef.build_wall_mounted_commands("platform_terminal", _wall_context("platform_terminal", false))
	_check_schema(platform)
	_expect_eq(platform.size(), 5, "platform terminal command count changed")
	_expect_vec(Vector2(platform[3]["start"]), Vector2(14.4, 51.5), "platform terminal indicator start must preserve legacy absolute-y formula")
	_expect_vec(Vector2(platform[3]["end"]), Vector2(25.6, 51.5), "platform terminal indicator end must preserve legacy absolute-y formula")
	var cooling: Array[Dictionary] = ObjectPrimitiveRendererRef.build_wall_mounted_commands("cooling_terminal", _wall_context("cooling_terminal", false))
	_check_schema(cooling)
	_expect_eq(cooling.size(), 6, "cooling terminal fin count changed")
	_expect_vec(Vector2(cooling[3]["start"]), Vector2(16.0, 15.2), "cooling first fin start changed")
	_expect_vec(Vector2(cooling[5]["end"]), Vector2(23.6, 25.2), "cooling last fin end changed")
	var firewall: Array[Dictionary] = ObjectPrimitiveRendererRef.build_wall_mounted_commands("firewall", _wall_context("firewall", false))
	_check_schema(firewall)
	_expect_eq(firewall.size(), 6, "firewall warning triangle command count changed")
	_expect_vec(Vector2(firewall[3]["start"]), Vector2(15.0, 22.0), "firewall warning triangle first start changed")
	_expect_vec(Vector2(firewall[5]["end"]), Vector2(15.0, 22.0), "firewall warning triangle closing end changed")
	var breaker: Array[Dictionary] = ObjectPrimitiveRendererRef.build_wall_mounted_commands("circuit_breaker", _wall_context("circuit_breaker", true))
	_check_schema(breaker)
	_expect_eq(breaker.size(), 4, "breaker outlined command count changed")
	var fuse: Array[Dictionary] = ObjectPrimitiveRendererRef.build_wall_mounted_commands("fuse_box", _wall_context("fuse_box", true))
	_check_schema(fuse)
	_expect_eq(fuse.size(), 5, "fuse box outlined command count changed")
	var light_switch: Array[Dictionary] = ObjectPrimitiveRendererRef.build_wall_mounted_commands("light_switch", _wall_context("light_switch", true))
	_check_schema(light_switch)
	_expect_eq(light_switch.size(), 3, "light switch outlined command count changed")
	var socket: Array[Dictionary] = ObjectPrimitiveRendererRef.build_wall_mounted_commands("power_socket", _wall_context("power_socket", true))
	_check_schema(socket)
	_expect_eq(socket.size(), 4, "power socket outlined command count changed")
	var light: Array[Dictionary] = ObjectPrimitiveRendererRef.build_wall_mounted_commands("light", _wall_context("light", true))
	_check_schema(light)
	_expect_eq(light.size(), 4, "light outlined command count changed")
	var reel: Array[Dictionary] = ObjectPrimitiveRendererRef.build_wall_mounted_commands("power_cable_reel", _wall_context("power_cable_reel", true))
	_check_schema(reel)
	_expect_eq(reel.size(), 5, "cable reel outlined command count changed")
	_expect_float(float(reel[1]["radius"]), 5.0, "cable reel outer arc radius changed")
	_expect_float(float(reel[1]["end_angle"]), PI * 1.75, "cable reel arc angle changed")
	_expect(ObjectPrimitiveRendererRef.build_wall_mounted_commands("external_air_duct", _wall_context("generic_object")).is_empty(), "unsupported wall-mounted primitive should draw nothing")

func _check_floor_base() -> void:
	var shadow: PackedVector2Array = PackedVector2Array([Vector2.ZERO, Vector2.RIGHT, Vector2.DOWN])
	var footprint: PackedVector2Array = PackedVector2Array([Vector2(2.0, 0.0), Vector2(3.0, 0.0), Vector2(2.0, 1.0)])
	var commands: Array[Dictionary] = ObjectPrimitiveRendererRef.build_floor_base_commands({"shadow_polygon": shadow, "footprint_polygon": footprint})
	_check_schema(commands)
	_expect_eq(commands.size(), 2, "floor base command count changed")
	_expect_eq(str(commands[0]["kind"]), "polygon", "floor base shadow must be first")
	_expect_color(Color(commands[0]["color"]), Color(0.03, 0.05, 0.08, 0.26), "floor base shadow color changed")
	_expect_color(Color(commands[1]["color"]), Color(0.2, 0.24, 0.28, 0.2), "floor base footprint color changed")
	_expect(ObjectPrimitiveRendererRef.build_floor_base_commands({"shadow_polygon": PackedVector2Array([Vector2.ZERO]), "footprint_polygon": {}}).is_empty(), "invalid floor polygons should draw nothing")
	_expect(ObjectPrimitiveRendererRef.build_floor_base_commands({"is_wall_visual": true, "shadow_polygon": shadow}).is_empty(), "wall visual should skip floor base")

func _check_texture_accent() -> void:
	var accent: Color = Color(0.1, 0.2, 0.3, 0.4)
	var commands: Array[Dictionary] = ObjectPrimitiveRendererRef.build_texture_accent_commands({"visual_center": Vector2(10.0, 20.0), "marker_height": 18.0, "accent": accent, "enabled": true})
	_check_schema(commands)
	_expect_eq(commands.size(), 2, "texture accent command count changed")
	_expect_vec(Vector2(commands[0]["center"]), Vector2(10.0, -6.0), "texture accent circle position changed")
	_expect_float(float(commands[0]["radius"]), 2.4, "texture accent circle radius changed")
	_expect_vec(Vector2(commands[1]["start"]), Vector2(6.0, -1.0), "texture accent line start changed")
	_expect_vec(Vector2(commands[1]["end"]), Vector2(14.0, -1.0), "texture accent line end changed")
	_expect_float(float(commands[1]["width"]), 1.5, "texture accent line width changed")
	_expect_color(Color(commands[1]["color"]), accent, "texture accent color changed")
	_expect(ObjectPrimitiveRendererRef.build_texture_accent_commands({"enabled": false}).is_empty(), "disabled texture accent should draw nothing")

func _check_malformed_contexts() -> void:
	var malformed: Dictionary = {"visual_center": "bad", "diamond": "bad", "half_size": 123, "marker_height": "bad", "profile": [], "outlines": "bad"}
	_expect(ObjectPrimitiveRendererRef.build_shape_commands("slab", malformed).is_empty(), "malformed slab geometry should safely draw nothing")
	_check_schema(ObjectPrimitiveRendererRef.build_shape_commands("small_marker", malformed))
	_check_schema(ObjectPrimitiveRendererRef.build_texture_accent_commands({"visual_center": "bad", "marker_height": "bad", "accent": 123}))
	_expect(ObjectPrimitiveRendererRef.build_floor_base_commands({"shadow_polygon": "bad", "footprint_polygon": {}}).is_empty(), "malformed floor polygons should safely draw nothing")
	_check_schema(ObjectPrimitiveRendererRef.build_wall_mounted_commands("light", {"visual_center": "bad", "profile": [], "outlines": "bad"}))

func _check_stability() -> void:
	var first: Array[Dictionary] = ObjectPrimitiveRendererRef.build_shape_commands("small_marker", _context(true))
	var second: Array[Dictionary] = ObjectPrimitiveRendererRef.build_shape_commands("small_marker", _context(true))
	_expect(var_to_str(first) == var_to_str(second), "repeated identical input must be stable")
