extends SceneTree

const CableCanvasRendererRef = preload("res://scripts/visual/renderer/cable_canvas_renderer.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_check_color_policy()
	_check_isolated_commands()
	_check_straight_and_elbow_commands()
	_check_junction_invalid_and_damage_commands()
	_check_hidden_links_and_wall_segments()
	_check_bridge_policy_and_geometry()
	_check_malformed_contexts()
	if failures.is_empty():
		print("CableCanvasRenderer contract OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _expect_vector(actual: Variant, expected: Vector2, message: String) -> void:
	_expect(actual is Vector2 and Vector2(actual).is_equal_approx(expected), "%s: got %s expected %s" % [message, str(actual), str(expected)])

func _expect_color(actual: Variant, expected: Color, message: String) -> void:
	_expect(actual is Color and Color(actual).is_equal_approx(expected), "%s: got %s expected %s" % [message, str(actual), str(expected)])

func _expect_float(actual: Variant, expected: float, message: String) -> void:
	_expect((actual is float or actual is int) and is_equal_approx(float(actual), expected), "%s: got %s expected %s" % [message, str(actual), str(expected)])

func _profile() -> Dictionary:
	return {"base": Color(0.16, 0.18, 0.22, 0.98), "accent": Color(0.87, 0.73, 0.30, 0.95), "outline": Color(0.06, 0.065, 0.075, 0.98)}

func _endpoints() -> Dictionary:
	return {"north": Vector2(68.0, 48.0), "south": Vector2(132.0, 112.0), "west": Vector2(36.0, 112.0), "east": Vector2(164.0, 48.0)}

func _direction_vectors() -> Dictionary:
	return {"north": Vector2(-64.0, -32.0), "south": Vector2(64.0, 32.0), "west": Vector2(-64.0, 32.0), "east": Vector2(64.0, -32.0)}

func _base_context(route_plan: Dictionary) -> Dictionary:
	return {"center": Vector2(100.0, 80.0), "tile_half_size": Vector2(64.0, 32.0), "profile": _profile(), "install_mode": "floor", "route_plan": route_plan, "endpoints": _endpoints(), "direction_vectors": _direction_vectors(), "object_link_rows": [], "health_state": "normal", "debug_outlines": false}

func _check_color_policy() -> void:
	_expect_color(CableCanvasRendererRef.resolve_line_color("red", Color(0.0, 0.0, 0.0, 0.5)), Color(1.0, 0.22, 0.18, 0.5), "red color mapping")
	_expect_color(CableCanvasRendererRef.resolve_line_color("unknown", Color(0.1, 0.2, 0.3, 0.4)), Color(0.1, 0.2, 0.3, 0.4), "unknown color fallback")
	var hidden := CableCanvasRendererRef.build_profile({"profile": _profile(), "install_mode": "hidden", "valid": true})
	_expect_float(Color(hidden.get("base", Color.WHITE)).a, 0.72, "hidden base alpha")
	_expect_float(Color(hidden.get("accent", Color.WHITE)).a, 0.82, "hidden accent alpha")
	var invalid := CableCanvasRendererRef.build_profile({"profile": _profile(), "install_mode": "floor", "valid": false})
	_expect_color(invalid.get("base", Color.WHITE), Color(1.0, 0.25, 0.08, 0.98), "invalid base color")
	_expect_color(invalid.get("accent", Color.WHITE), Color(1.0, 0.82, 0.15, 0.98), "invalid accent color")

func _check_isolated_commands() -> void:
	var commands: Array[Dictionary] = CableCanvasRendererRef.build_floor_cable_commands(_base_context({"shape": "isolated", "active_dirs": [], "geometry_mode": "isolated", "has_switch": false, "valid": true, "endpoint_cap": false, "junction_marker": false, "invalid_marker": false}))
	_expect(commands.size() == 5, "isolated command count")
	_expect(str(commands[0].get("kind", "")) == "line", "isolated shadow command kind")
	_expect_vector(commands[0].get("start", Vector2.ZERO), Vector2(92.32, 81.5), "isolated shadow start")
	_expect_vector(commands[0].get("end", Vector2.ZERO), Vector2(107.68, 81.5), "isolated shadow end")
	_expect_float(commands[0].get("width", 0.0), 7.0, "isolated shadow width")
	_expect(str(commands[3].get("kind", "")) == "circle", "isolated center circle kind")
	_expect_float(commands[3].get("radius", 0.0), 4.5, "isolated center circle radius")
	_expect(str(commands[4].get("kind", "")) == "arc", "isolated ring kind")
	_expect_float(commands[4].get("radius", 0.0), 7.0, "isolated ring radius")
	_expect_float(commands[4].get("width", 0.0), 1.4, "isolated ring width")

func _check_straight_and_elbow_commands() -> void:
	var straight: Array[Dictionary] = CableCanvasRendererRef.build_floor_cable_commands(_base_context({"shape": "straight_x", "active_dirs": ["east", "west"], "geometry_mode": "straight", "has_switch": false, "valid": true, "endpoint_cap": false, "junction_marker": false, "invalid_marker": false}))
	_expect(straight.size() == 3, "straight command count")
	_expect_vector(straight[1].get("start", Vector2.ZERO), Vector2(164.0, 48.0), "straight core start")
	_expect_vector(straight[1].get("end", Vector2.ZERO), Vector2(36.0, 112.0), "straight core end")
	_expect_float(straight[1].get("width", 0.0), 5.0, "straight core width")
	var elbow: Array[Dictionary] = CableCanvasRendererRef.build_floor_cable_commands(_base_context({"shape": "corner_ne", "active_dirs": ["north", "east"], "geometry_mode": "elbow", "has_switch": false, "valid": true, "endpoint_cap": false, "junction_marker": false, "invalid_marker": false}))
	_expect(elbow.size() == 8, "elbow command count")
	_expect_vector(elbow[0].get("start", Vector2.ZERO), Vector2(68.0, 49.5), "elbow first shadow start")
	_expect_vector(elbow[0].get("end", Vector2.ZERO), Vector2(100.0, 81.5), "elbow first shadow end")
	_expect(str(elbow[6].get("kind", "")) == "circle", "elbow base center kind")
	_expect_float(elbow[6].get("radius", 0.0), 2.7, "elbow base center radius")
	_expect_float(elbow[7].get("radius", 0.0), 1.2, "elbow accent center radius")

func _check_junction_invalid_and_damage_commands() -> void:
	var junction: Array[Dictionary] = CableCanvasRendererRef.build_floor_cable_commands(_base_context({"shape": "junction_t", "active_dirs": ["north", "east", "west"], "geometry_mode": "branches", "has_switch": false, "valid": true, "endpoint_cap": false, "junction_marker": true, "invalid_marker": false}))
	_expect(junction.size() == 10, "junction command count")
	_expect(str(junction[9].get("kind", "")) == "circle", "junction marker kind")
	_expect_float(junction[9].get("radius", 0.0), 3.6, "junction marker radius")
	var invalid_context := _base_context({"shape": "invalid_cross", "active_dirs": ["north", "south"], "geometry_mode": "branches", "has_switch": false, "valid": false, "endpoint_cap": false, "junction_marker": false, "invalid_marker": true})
	invalid_context["health_state"] = "cut"
	var invalid: Array[Dictionary] = CableCanvasRendererRef.build_floor_cable_commands(invalid_context)
	_expect(invalid.size() == 12, "invalid plus damage command count")
	_expect(str(invalid[6].get("kind", "")) == "circle", "invalid marker circle kind")
	_expect_float(invalid[6].get("radius", 0.0), 7.0, "invalid cross radius")
	_expect_color(invalid[10].get("color", Color.WHITE), Color(1.0, 0.22, 0.16, 0.96), "cut marker first slash color")

func _check_hidden_links_and_wall_segments() -> void:
	var hidden: Array[Dictionary] = CableCanvasRendererRef.build_hidden_segment_commands({"start": Vector2.ZERO, "end": Vector2(30.0, 0.0), "profile": _profile()})
	_expect(hidden.size() == 12, "hidden layered dash command count")
	_expect(str(hidden[0].get("kind", "")) == "polyline", "hidden command kind")
	_expect_float(hidden[0].get("width", 0.0), 7.0, "hidden shadow width")
	var links: Array[Dictionary] = CableCanvasRendererRef.build_object_link_commands({"profile": {"base": Color(0.1, 0.1, 0.1, 1.0), "accent": Color(0.8, 0.7, 0.2, 1.0), "outline": Color(0.05, 0.05, 0.05, 1.0), "install_mode": "floor"}, "rows": [{"start": Vector2(10.0, 10.0), "end": Vector2(20.0, 10.0)}]})
	_expect(links.size() == 4, "visible object link command count")
	_expect_float(links[0].get("width", 0.0), 4.0, "object link shadow width")
	_expect_float(links[3].get("radius", 0.0), 2.3, "object link endpoint radius")
	var wall: Array[Dictionary] = CableCanvasRendererRef.build_wall_segment_commands({"start": Vector2.ZERO, "end": Vector2(20.0, 0.0), "profile": _profile()})
	_expect(wall.size() == 5, "wall segment command count")
	_expect(str(wall[0].get("kind", "")) == "polyline", "wall layered polyline kind")
	_expect_float(wall[4].get("width", 0.0), 2.0, "wall extra shadow width")

func _check_bridge_policy_and_geometry() -> void:
	_expect(CableCanvasRendererRef.extract_bridge_network_id({"network_id": "fallback", "power_network_id": "primary"}) == "primary", "bridge network precedence")
	_expect(CableCanvasRendererRef.should_emit_bridge({"object_cell": Vector2i(1, 1), "cable_cell": Vector2i(2, 1), "cable_present": true, "object_connectable": true, "object_network_id": "a", "cable_network_id": "a"}), "bridge same-network adjacency")
	_expect(not CableCanvasRendererRef.should_emit_bridge({"object_cell": Vector2i(1, 1), "cable_cell": Vector2i(3, 1), "cable_present": true, "object_connectable": true, "object_network_id": "a", "cable_network_id": "a"}), "bridge rejects non-adjacent cells")
	_expect(not CableCanvasRendererRef.should_emit_bridge({"object_cell": Vector2i(1, 1), "cable_cell": Vector2i(2, 1), "cable_present": true, "object_connectable": true, "object_network_id": "a", "cable_network_id": "b"}), "bridge rejects different network")
	var points := CableCanvasRendererRef.build_bridge_points({"object_center": Vector2(20.0, 40.0), "cable_center": Vector2(60.0, 80.0)})
	_expect_vector(points.get("from_edge_towards_to", Vector2.ZERO), Vector2(40.0, 60.0), "bridge shared edge")
	var commands: Array[Dictionary] = CableCanvasRendererRef.build_bridge_commands({"object_center": Vector2(20.0, 40.0), "cable_center": Vector2(60.0, 80.0), "install_mode": "floor"})
	_expect(commands.size() == 6, "bridge command count")
	_expect_vector(commands[1].get("start", Vector2.ZERO), Vector2(20.0, 40.0), "bridge object core start")
	_expect_vector(commands[1].get("end", Vector2.ZERO), Vector2(40.0, 60.0), "bridge object core end")
	_expect_vector(commands[4].get("start", Vector2.ZERO), Vector2(60.0, 80.0), "bridge cable core start")
	_expect_vector(commands[4].get("end", Vector2.ZERO), Vector2(40.0, 60.0), "bridge cable core end")

func _check_malformed_contexts() -> void:
	_expect(CableCanvasRendererRef.build_floor_cable_commands({"center": "bad", "route_plan": "bad"}) is Array, "malformed floor context remains safe")
	_expect(CableCanvasRendererRef.build_hidden_segment_commands({"start": "bad", "end": 7}) is Array, "malformed hidden context remains safe")
	_expect(CableCanvasRendererRef.build_object_link_commands({"rows": "bad"}).is_empty(), "malformed link rows remain safe")
	_expect(not CableCanvasRendererRef.should_emit_bridge({"object_cell": "bad", "cable_cell": 2}), "malformed bridge context remains safe")
