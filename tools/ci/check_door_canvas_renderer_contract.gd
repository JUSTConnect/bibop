extends SceneTree

const DoorCanvasRendererRef = preload("res://scripts/visual/renderer/door_canvas_renderer.gd")

var failures: Array[String] = []

func _init() -> void:
	_check_normalization()
	_check_profiles()
	_check_commands()
	_check_malformed_and_stability()
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

func _near_vec(actual: Vector2, expected: Vector2, label: String) -> void:
	if actual.distance_to(expected) > 0.001:
		_fail("%s expected=%s actual=%s" % [label, expected, actual])

func _profile(kind: String, state: String) -> Dictionary:
	return DoorCanvasRendererRef.build_visual_profile(kind, state)

func _context(kind: String = "mechanical_door", state: String = "closed") -> Dictionary:
	return {
		"orientation": "axis_x",
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

func _check_normalization() -> void:
	for state in ["open", "closed", "locked", "powered", "unpowered", "damaged"]:
		_eq(DoorCanvasRendererRef.normalize_state(state), state, "normalize supported %s" % state)
	for state in ["broken", "jammed", "destroyed"]:
		_eq(DoorCanvasRendererRef.normalize_state(state), "damaged", "normalize alias %s" % state)
	_eq(DoorCanvasRendererRef.normalize_state(""), "closed", "normalize empty")
	_eq(DoorCanvasRendererRef.normalize_state("surprise"), "closed", "normalize unknown")

func _check_profiles() -> void:
	var kinds := ["mechanical_door", "digital_door", "powered_gate"]
	var states := ["open", "closed", "locked", "powered", "unpowered", "damaged"]
	for kind in kinds:
		for state in states:
			var p := _profile(kind, state)
			_eq(p.get("door_kind"), kind, "profile kind %s %s" % [kind, state])
			_eq(p.get("door_state"), state, "profile state %s %s" % [kind, state])
			_eq(p.get("frame_enabled"), true, "frame enabled")
			_eq(p.get("threshold_enabled"), true, "threshold enabled")
			_eq(p.get("state_badge_enabled"), state != "closed", "badge flag")
			_eq(p.get("damage_overlay_enabled"), state == "damaged", "damage flag")
	var open_base: Color = _profile("mechanical_door", "open").get("base_color")
	_eq(open_base.a, 0.96, "profile stores pre-multiplied base alpha")
	var cmds := DoorCanvasRendererRef.build_body_commands(_context("mechanical_door", "open"))
	_eq(cmds[0].get("color").a, 0.96 * 0.38, "command final base alpha")
	var locked_overlay := DoorCanvasRendererRef.build_state_overlay_commands(_context("mechanical_door", "locked"))
	_eq(locked_overlay[0].get("color"), Color(1.0, 0.86, 0.24, 0.99), "locked warning badge color")

func _check_commands() -> void:
	var c := _context()
	var threshold := DoorCanvasRendererRef.build_threshold_commands(c)
	_eq(threshold.size(), 5, "threshold fallback count")
	_eq(threshold[0].get("kind"), "polygon", "threshold first polygon")
	_eq(threshold[1].get("antialiased"), false, "threshold antialias flag")
	var tex_context := c.duplicate(true); tex_context["threshold_texture_succeeded"] = true
	_eq(DoorCanvasRendererRef.build_threshold_commands(tex_context).size(), 0, "threshold texture success empty")
	var disabled := c.duplicate(true); disabled["profile"]["threshold_enabled"] = false
	_eq(DoorCanvasRendererRef.build_threshold_commands(disabled).size(), 0, "threshold disabled empty")
	var frame := DoorCanvasRendererRef.build_frame_commands(c)
	_eq(frame.size(), 7, "frame count")
	_eq(frame[5].get("width"), 3.0, "jamb width")
	var body := DoorCanvasRendererRef.build_body_commands(c)
	_eq(body.size(), 2, "mechanical closed procedural count")
	_eq(body[0].get("kind"), "polygon", "mechanical body polygon")
	var cy := c.duplicate(true); cy["orientation"] = "axis_y"
	_eq(DoorCanvasRendererRef.build_body_commands(cy).size(), 2, "mechanical axis_y procedural count")
	_eq(DoorCanvasRendererRef.build_body_commands(_context("mechanical_door", "open")).size(), 3, "mechanical open split count")
	_eq(DoorCanvasRendererRef.build_body_commands(_context("digital_door", "closed")).size(), 3, "digital procedural count")
	_eq(DoorCanvasRendererRef.build_body_commands(_context("powered_gate", "closed")).size(), 9, "powered procedural count")
	for kind in ["mechanical_door", "digital_door", "powered_gate"]:
		var tc := _context(kind, "closed"); tc["door_texture_succeeded"] = true
		var textured := DoorCanvasRendererRef.build_body_commands(tc)
		_eq(textured[textured.size() - 1].get("kind"), "circle", "texture center accent %s" % kind)
	var dbg := _context(); dbg["debug_outlines"] = true
	_eq(DoorCanvasRendererRef.build_body_commands(dbg).size(), 6, "debug outline count")
	_eq(DoorCanvasRendererRef.build_state_overlay_commands(_context("mechanical_door", "closed")).size(), 0, "closed no badge")
	_eq(DoorCanvasRendererRef.build_state_overlay_commands(_context("mechanical_door", "locked")).size(), 2, "locked badge count")
	_eq(DoorCanvasRendererRef.build_state_overlay_commands(_context("mechanical_door", "unpowered")).size(), 2, "unpowered badge count")
	var damaged := DoorCanvasRendererRef.build_state_overlay_commands(_context("mechanical_door", "damaged"))
	_eq(damaged.size(), 3, "damaged badge and overlay count")
	_eq(damaged[0].get("kind"), "circle", "damaged badge precedes overlay")
	_eq(damaged[1].get("width"), 1.8, "damage first line width")

func _check_malformed_and_stability() -> void:
	_eq(DoorCanvasRendererRef.build_threshold_commands({"profile": {"threshold_enabled": "yes"}, "threshold_polygon": "bad"}).size(), 0, "malformed threshold safe")
	_eq(DoorCanvasRendererRef.build_frame_commands({"profile": {"frame_enabled": 1}, "door_frame_polygon": [Vector2.ZERO]}).size(), 0, "malformed frame safe")
	_eq(DoorCanvasRendererRef.build_body_commands({"profile": "bad", "door_texture_succeeded": "true", "debug_outlines": 1}).size(), 2, "malformed body safe")
	var a := DoorCanvasRendererRef.build_body_commands(_context("powered_gate", "closed"))
	var b := DoorCanvasRendererRef.build_body_commands(_context("powered_gate", "closed"))
	_eq(var_to_str(a), var_to_str(b), "repeated identical input stability")
	for cmds in [DoorCanvasRendererRef.build_threshold_commands(_context()), DoorCanvasRendererRef.build_frame_commands(_context()), DoorCanvasRendererRef.build_body_commands(_context("digital_door", "closed")), DoorCanvasRendererRef.build_state_overlay_commands(_context("mechanical_door", "damaged"))]:
		for i in range(cmds.size()):
			_eq(cmds[i].has("kind"), true, "schema kind")
			_eq(cmds[i].get("order"), i, "monotonic order")
