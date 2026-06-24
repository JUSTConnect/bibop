extends SceneTree

const DoorCanvasRendererRef = preload("res://scripts/visual/renderer/door_canvas_renderer.gd")

const EPSILON := 0.001

var failures: Array[String] = []

func _init() -> void:
	_check_normalization()
	_check_profiles()
	_check_threshold_commands()
	_check_frame_commands()
	_check_body_procedural_geometry()
	_check_body_texture_success_geometry()
	_check_state_overlay_commands()
	_check_malformed_and_schema_stability()
	if failures.is_empty():
		print("DoorCanvasRenderer contract passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _fail(message: String) -> void:
	failures.append(message)

func _eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		_fail("%s expected=%s actual=%s" % [label, var_to_str(expected), var_to_str(actual)])

func _near_float(actual: float, expected: float, label: String) -> void:
	if absf(actual - expected) > EPSILON:
		_fail("%s expected=%.6f actual=%.6f" % [label, expected, actual])

func _near_vec(actual: Vector2, expected: Vector2, label: String) -> void:
	if actual.distance_to(expected) > EPSILON:
		_fail("%s expected=%s actual=%s" % [label, expected, actual])

func _near_color(actual: Color, expected: Color, label: String) -> void:
	if absf(actual.r - expected.r) > EPSILON or absf(actual.g - expected.g) > EPSILON or absf(actual.b - expected.b) > EPSILON or absf(actual.a - expected.a) > EPSILON:
		_fail("%s expected=%s actual=%s" % [label, expected, actual])

func _near_points(actual: PackedVector2Array, expected: PackedVector2Array, label: String) -> void:
	_eq(actual.size(), expected.size(), "%s size" % label)
	if actual.size() != expected.size():
		return
	for index in range(actual.size()):
		_near_vec(actual[index], expected[index], "%s point %d" % [label, index])

func _assert_line(command: Dictionary, start: Vector2, end: Vector2, color: Color, width: float, label: String, antialiased := false) -> void:
	_eq(command.get("kind"), "line", "%s kind" % label)
	_near_vec(command.get("start", Vector2.INF), start, "%s start" % label)
	_near_vec(command.get("end", Vector2.INF), end, "%s end" % label)
	_near_color(command.get("color", Color.TRANSPARENT), color, "%s color" % label)
	_near_float(float(command.get("width", -1.0)), width, "%s width" % label)
	_eq(command.get("antialiased", false), antialiased, "%s antialiased" % label)

func _assert_circle(command: Dictionary, center: Vector2, radius: float, color: Color, label: String) -> void:
	_eq(command.get("kind"), "circle", "%s kind" % label)
	_near_vec(command.get("center", Vector2.INF), center, "%s center" % label)
	_near_float(float(command.get("radius", -1.0)), radius, "%s radius" % label)
	_near_color(command.get("color", Color.TRANSPARENT), color, "%s color" % label)

func _assert_polygon(command: Dictionary, points: PackedVector2Array, color: Color, label: String) -> void:
	_eq(command.get("kind"), "polygon", "%s kind" % label)
	_near_points(command.get("points", PackedVector2Array()), points, "%s points" % label)
	_near_color(command.get("color", Color.TRANSPARENT), color, "%s color" % label)

func _assert_schema(commands: Array[Dictionary], label: String) -> void:
	for index in range(commands.size()):
		var command := commands[index]
		_eq(command.has("kind"), true, "%s command %d has kind" % [label, index])
		_eq(command.get("order"), index, "%s command %d order" % [label, index])
		match str(command.get("kind", "")):
			"polygon":
				_eq(command.has("points"), true, "%s polygon points" % label)
				_eq(command.has("color"), true, "%s polygon color" % label)
			"line":
				for key in ["start", "end", "color", "width", "antialiased"]:
					_eq(command.has(key), true, "%s line %s" % [label, key])
			"circle":
				for key in ["center", "radius", "color"]:
					_eq(command.has(key), true, "%s circle %s" % [label, key])
			_:
				_fail("%s unknown command kind %s" % [label, command.get("kind", "")])

func _profile(kind: String, state: String) -> Dictionary:
	return DoorCanvasRendererRef.build_visual_profile(kind, state)

func _final_base(profile: Dictionary) -> Color:
	var color: Color = profile.get("base_color")
	color.a *= float(profile.get("alpha"))
	return color

func _final_accent(profile: Dictionary) -> Color:
	var color: Color = profile.get("accent_color")
	color.a *= maxf(float(profile.get("alpha")), 0.55)
	return color

func _context(kind := "mechanical_door", state := "closed", orientation := "axis_x") -> Dictionary:
	return {
		"orientation": orientation,
		"door_insert_center": Vector2(100.0, 80.0),
		"tile_half_size": Vector2(64.0, 35.5),
		"wall_height": 50.0,
		"threshold_polygon": PackedVector2Array([Vector2(0, 0), Vector2(4, 0), Vector2(4, 3), Vector2(0, 3)]),
		"door_frame_polygon": PackedVector2Array([Vector2(1, 1), Vector2(5, 1), Vector2(5, 6), Vector2(1, 6)]),
		"valid_jamb_centers": [Vector2(10, 10), Vector2(20, 20)],
		"profile": _profile(kind, state),
		"threshold_texture_succeeded": false,
		"door_texture_succeeded": false,
		"debug_outlines": false,
	}

func _panel_points(context: Dictionary) -> PackedVector2Array:
	var along := Vector2(0.78, 0.39).normalized() if str(context.get("orientation")) == "axis_y" else Vector2(0.78, -0.39).normalized()
	var center: Vector2 = context.get("door_insert_center")
	var half_width := Vector2(context.get("tile_half_size")).x * 0.24
	var panel_bottom := center + Vector2(0.0, 12.0)
	var panel_top := panel_bottom + Vector2(0.0, -1.0) * (float(context.get("wall_height")) * 0.58)
	return PackedVector2Array([panel_top - along * half_width, panel_top + along * half_width, panel_bottom + along * half_width, panel_bottom - along * half_width])

func _check_normalization() -> void:
	for state in ["open", "closed", "locked", "powered", "unpowered", "damaged"]:
		_eq(DoorCanvasRendererRef.normalize_state(state), state, "normalize supported %s" % state)
	for state in ["broken", "jammed", "destroyed"]:
		_eq(DoorCanvasRendererRef.normalize_state(state), "damaged", "normalize alias %s" % state)
	_eq(DoorCanvasRendererRef.normalize_state(""), "closed", "normalize empty")
	_eq(DoorCanvasRendererRef.normalize_state("surprise"), "closed", "normalize unknown")
	_eq(DoorCanvasRendererRef.normalize_state(" LOCKED "), "locked", "normalize trim/lower")

func _check_profiles() -> void:
	var defaults := {
		"mechanical_door": [Color(0.27, 0.24, 0.22, 0.96), Color(0.88, 0.72, 0.36, 0.98)],
		"digital_door": [Color(0.13, 0.2, 0.28, 0.96), Color(0.38, 0.88, 1.0, 0.98)],
		"powered_gate": [Color(0.09, 0.14, 0.2, 0.9), Color(0.48, 0.96, 1.0, 0.98)],
	}
	for kind in defaults.keys():
		for state in ["open", "closed", "locked", "powered", "unpowered", "damaged"]:
			var p := _profile(kind, state)
			_eq(p.get("door_kind"), kind, "profile kind %s %s" % [kind, state])
			_eq(p.get("door_state"), state, "profile state %s %s" % [kind, state])
			_near_color(p.get("frame_color"), Color(0.12, 0.14, 0.16, 0.98), "frame color %s %s" % [kind, state])
			_near_color(p.get("threshold_color"), Color(0.16, 0.18, 0.2, 0.82), "threshold color %s %s" % [kind, state])
			_eq(p.get("frame_enabled"), true, "frame flag")
			_eq(p.get("threshold_enabled"), true, "threshold flag")
			_eq(p.get("state_badge_enabled"), state != "closed", "badge flag")
			_eq(p.get("damage_overlay_enabled"), state == "damaged", "damage flag")
			if state == "closed":
				_near_color(p.get("base_color"), defaults[kind][0], "closed base %s" % kind)
				_near_color(p.get("accent_color"), defaults[kind][1], "closed accent %s" % kind)
				_near_float(p.get("alpha"), 0.96, "closed alpha %s" % kind)
			elif state == "open":
				_near_color(p.get("base_color"), defaults[kind][0].darkened(0.18), "open base %s" % kind)
				_near_color(p.get("accent_color"), Color(0.58, 0.9, 0.98, 0.92), "open accent %s" % kind)
				_near_float(p.get("alpha"), 0.38, "open alpha %s" % kind)
			elif state == "locked":
				_near_color(p.get("accent_color"), Color(1.0, 0.72, 0.22, 0.99), "locked accent %s" % kind)
				_near_color(p.get("warning_color"), Color(1.0, 0.86, 0.24, 0.99), "locked warning %s" % kind)
			elif state == "powered":
				_near_color(p.get("accent_color"), Color(0.32, 0.92, 1.0, 0.99), "powered accent %s" % kind)
			elif state == "unpowered":
				_near_color(p.get("base_color"), Color(0.18, 0.19, 0.21, 0.86), "unpowered base %s" % kind)
				_near_color(p.get("accent_color"), Color(0.48, 0.54, 0.58, 0.86), "unpowered accent %s" % kind)
				_near_float(p.get("alpha"), 0.72, "unpowered alpha %s" % kind)
			elif state == "damaged":
				_near_color(p.get("accent_color"), Color(1.0, 0.34, 0.22, 0.99), "damaged accent %s" % kind)
				_near_color(p.get("warning_color"), Color(1.0, 0.18, 0.12, 0.99), "damaged warning %s" % kind)

func _check_threshold_commands() -> void:
	var c := _context("mechanical_door", "closed")
	var p: Dictionary = c["profile"]
	var commands := DoorCanvasRendererRef.build_threshold_commands(c)
	_assert_schema(commands, "threshold fallback")
	_eq(commands.size(), 5, "threshold fallback count")
	_assert_polygon(commands[0], c["threshold_polygon"], p["threshold_color"], "threshold fill")
	var edge_color := _final_accent(p).darkened(0.25)
	var polygon: PackedVector2Array = c["threshold_polygon"]
	for index in range(polygon.size()):
		_assert_line(commands[index + 1], polygon[index], polygon[(index + 1) % polygon.size()], edge_color, 1.0, "threshold edge %d" % index)
	var texture_success := c.duplicate(true)
	texture_success["threshold_texture_succeeded"] = true
	_eq(DoorCanvasRendererRef.build_threshold_commands(texture_success).size(), 0, "threshold texture success emits none")
	var disabled := c.duplicate(true)
	disabled["profile"]["threshold_enabled"] = false
	_eq(DoorCanvasRendererRef.build_threshold_commands(disabled).size(), 0, "threshold disabled emits none")
	var malformed := c.duplicate(true)
	malformed["threshold_polygon"] = PackedVector2Array([Vector2.ZERO, Vector2.ONE])
	_eq(DoorCanvasRendererRef.build_threshold_commands(malformed).size(), 0, "threshold short polygon emits none")

func _check_frame_commands() -> void:
	var c := _context()
	var p: Dictionary = c["profile"]
	var frame_color: Color = p["frame_color"]
	var commands := DoorCanvasRendererRef.build_frame_commands(c)
	_assert_schema(commands, "frame")
	_eq(commands.size(), 7, "frame command count")
	var polygon: PackedVector2Array = c["door_frame_polygon"]
	_assert_polygon(commands[0], polygon, Color(frame_color.r, frame_color.g, frame_color.b, 0.72), "frame fill")
	for index in range(polygon.size()):
		_assert_line(commands[index + 1], polygon[index], polygon[(index + 1) % polygon.size()], frame_color.lightened(0.18), 2.0, "frame edge %d" % index)
	_assert_line(commands[5], Vector2(10, 0), Vector2(10, 23), frame_color.lightened(0.24), 3.0, "left jamb")
	_assert_line(commands[6], Vector2(20, 10), Vector2(20, 33), frame_color.lightened(0.24), 3.0, "right jamb")
	var disabled := c.duplicate(true)
	disabled["profile"]["frame_enabled"] = false
	_eq(DoorCanvasRendererRef.build_frame_commands(disabled).size(), 0, "frame disabled emits none")
	var malformed := c.duplicate(true)
	malformed["door_frame_polygon"] = PackedVector2Array([Vector2.ZERO, Vector2.ONE, Vector2(2, 2)])
	_eq(DoorCanvasRendererRef.build_frame_commands(malformed).size(), 0, "frame short polygon emits none")

func _check_body_procedural_geometry() -> void:
	for orientation in ["axis_x", "axis_y"]:
		var c := _context("mechanical_door", "closed", orientation)
		var p: Dictionary = c["profile"]
		var panel := _panel_points(c)
		var commands := DoorCanvasRendererRef.build_body_commands(c)
		_assert_schema(commands, "mechanical closed %s" % orientation)
		_eq(commands.size(), 2, "mechanical closed count %s" % orientation)
		_assert_polygon(commands[0], panel, _final_base(p), "mechanical closed panel %s" % orientation)
		_assert_line(commands[1], panel[0].lerp(panel[3], 0.5), panel[1].lerp(panel[2], 0.5), _final_accent(p), 1.6, "mechanical center line %s" % orientation)
	var open_context := _context("mechanical_door", "open")
	var open_panel := _panel_points(open_context)
	var along := Vector2(0.78, -0.39).normalized()
	var split := along * Vector2(open_context["tile_half_size"]).x * 0.24 * 0.58
	var open_commands := DoorCanvasRendererRef.build_body_commands(open_context)
	_eq(open_commands.size(), 3, "mechanical open split count")
	_assert_polygon(open_commands[0], PackedVector2Array([open_panel[0] - split, open_panel[0], open_panel[3], open_panel[3] - split]), _final_base(open_context["profile"]), "mechanical open left panel")
	_assert_polygon(open_commands[1], PackedVector2Array([open_panel[1], open_panel[1] + split, open_panel[2] + split, open_panel[2]]), _final_base(open_context["profile"]), "mechanical open right panel")
	var digital_context := _context("digital_door", "closed")
	var digital_panel := _panel_points(digital_context)
	var digital_commands := DoorCanvasRendererRef.build_body_commands(digital_context)
	_eq(digital_commands.size(), 3, "digital procedural count")
	var digital_start := digital_panel[0].lerp(digital_panel[1], 0.79)
	var digital_end := digital_panel[3].lerp(digital_panel[2], 0.79)
	_assert_line(digital_commands[1], digital_start, digital_end, _final_accent(digital_context["profile"]), 3.2, "digital strip")
	_assert_circle(digital_commands[2], digital_start.lerp(digital_end, 0.35), 2.8, _final_accent(digital_context["profile"]).lightened(0.2), "digital light")
	var powered_context := _context("powered_gate", "closed")
	var powered_commands := DoorCanvasRendererRef.build_body_commands(powered_context)
	_eq(powered_commands.size(), 9, "powered procedural count")
	for bar_index in range(4):
		_eq(powered_commands[bar_index * 2 + 1].get("kind"), "line", "powered bar kind %d" % bar_index)
		_near_float(powered_commands[bar_index * 2 + 1].get("width"), 1.8, "powered bar width %d" % bar_index)
		_assert_circle(powered_commands[bar_index * 2 + 2], powered_commands[bar_index * 2 + 1].get("start").lerp(powered_commands[bar_index * 2 + 1].get("end"), 0.5), 1.6, _final_accent(powered_context["profile"]).lightened(0.18), "powered node %d" % bar_index)
	var debug_context := _context()
	debug_context["debug_outlines"] = true
	var debug_commands := DoorCanvasRendererRef.build_body_commands(debug_context)
	_eq(debug_commands.size(), 6, "debug outline count")
	var debug_panel := _panel_points(debug_context)
	for index in range(debug_panel.size()):
		_assert_line(debug_commands[index + 2], debug_panel[index], debug_panel[(index + 1) % debug_panel.size()], debug_context["profile"]["frame_color"].lightened(0.28), 1.0, "debug outline %d" % index)

func _check_body_texture_success_geometry() -> void:
	for kind in ["mechanical_door", "digital_door", "powered_gate"]:
		var c := _context(kind, "closed")
		c["door_texture_succeeded"] = true
		var p: Dictionary = c["profile"]
		var center: Vector2 = c["door_insert_center"]
		var commands := DoorCanvasRendererRef.build_body_commands(c)
		_assert_schema(commands, "texture success %s" % kind)
		if kind == "digital_door":
			_eq(commands.size(), 3, "digital texture count")
			_assert_line(commands[0], center + Vector2(10, -43), center + Vector2(10, -13), _final_accent(p), 2.6, "digital texture strip")
			_assert_circle(commands[1], center + Vector2(10, -28), 2.4, _final_accent(p).lightened(0.2), "digital texture light")
		elif kind == "powered_gate":
			_eq(commands.size(), 4, "powered texture count")
			for index in range(3):
				var y := -38.0 + float(index) * 10.0
				_assert_line(commands[index], center + Vector2(-13, y), center + Vector2(13, y), _final_accent(p), 1.8, "powered texture bar %d" % index)
		else:
			_eq(commands.size(), 2, "mechanical texture count")
			_assert_line(commands[0], center + Vector2(-9, -24), center + Vector2(9, -24), _final_accent(p), 2.0, "mechanical texture accent")
		_assert_circle(commands[commands.size() - 1], center + Vector2(0, -31), 2.5, _final_accent(p), "texture center accent %s" % kind)

func _check_state_overlay_commands() -> void:
	_eq(DoorCanvasRendererRef.build_state_overlay_commands(_context("mechanical_door", "closed")).size(), 0, "closed state no badge")
	var locked := _context("mechanical_door", "locked")
	var locked_commands := DoorCanvasRendererRef.build_state_overlay_commands(locked)
	_assert_schema(locked_commands, "locked overlay")
	_eq(locked_commands.size(), 2, "locked overlay count")
	var badge: Vector2 = locked["door_insert_center"] + Vector2(18, -22)
	_assert_circle(locked_commands[0], badge, 4.2, locked["profile"]["warning_color"], "locked badge")
	_assert_line(locked_commands[1], badge + Vector2(-2, -1), badge + Vector2(2, -1), locked["profile"]["frame_color"], 1.2, "locked badge line")
	var unpowered := _context("mechanical_door", "unpowered")
	var unpowered_commands := DoorCanvasRendererRef.build_state_overlay_commands(unpowered)
	_eq(unpowered_commands.size(), 2, "unpowered overlay count")
	_assert_circle(unpowered_commands[0], badge, 4.2, _final_accent(unpowered["profile"]), "unpowered badge")
	_assert_line(unpowered_commands[1], badge + Vector2(-2.8, 2), badge + Vector2(2.8, -2), unpowered["profile"]["frame_color"], 1.4, "unpowered slash")
	var damaged := _context("mechanical_door", "damaged")
	var damaged_commands := DoorCanvasRendererRef.build_state_overlay_commands(damaged)
	_eq(damaged_commands.size(), 3, "damaged overlay count")
	_assert_circle(damaged_commands[0], badge, 4.2, damaged["profile"]["warning_color"], "damaged badge first")
	_assert_line(damaged_commands[1], damaged["door_insert_center"] + Vector2(-12, -36), damaged["door_insert_center"] + Vector2(-2, -23), damaged["profile"]["warning_color"], 1.8, "damage crack first")
	_assert_line(damaged_commands[2], damaged["door_insert_center"] + Vector2(-2, -23), damaged["door_insert_center"] + Vector2(-8, -14), damaged["profile"]["warning_color"], 1.4, "damage crack second")

func _check_malformed_and_schema_stability() -> void:
	_eq(DoorCanvasRendererRef.build_threshold_commands({"profile": {"threshold_enabled": "yes"}, "threshold_polygon": "bad"}).size(), 0, "malformed threshold safe")
	_eq(DoorCanvasRendererRef.build_frame_commands({"profile": {"frame_enabled": 1}, "door_frame_polygon": [Vector2.ZERO]}).size(), 0, "malformed frame safe")
	var malformed_body := DoorCanvasRendererRef.build_body_commands({"profile": "bad", "door_texture_succeeded": "true", "debug_outlines": 1})
	_assert_schema(malformed_body, "malformed body schema")
	_eq(malformed_body.size(), 2, "malformed body safe fallback")
	var first := DoorCanvasRendererRef.build_body_commands(_context("powered_gate", "closed"))
	var second := DoorCanvasRendererRef.build_body_commands(_context("powered_gate", "closed"))
	_eq(var_to_str(first), var_to_str(second), "repeated identical input stability")
	_assert_schema(DoorCanvasRendererRef.build_threshold_commands(_context()), "threshold schema")
	_assert_schema(DoorCanvasRendererRef.build_frame_commands(_context()), "frame schema")
	_assert_schema(DoorCanvasRendererRef.build_body_commands(_context("digital_door", "closed")), "body schema")
	_assert_schema(DoorCanvasRendererRef.build_state_overlay_commands(_context("mechanical_door", "damaged")), "state overlay schema")
