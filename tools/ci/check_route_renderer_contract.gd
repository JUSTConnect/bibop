extends SceneTree

const RouteRendererRef = preload("res://scripts/visual/renderer/route_renderer.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_check_normalization()
	_check_wall_face_geometry()
	_check_wall_cable_commands()
	_check_floor_policy()
	_check_procedural_route_commands()
	if failures.is_empty():
		print("RouteRenderer contract OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _check_normalization() -> void:
	_expect(RouteRendererRef.normalize_install_mode({"placement_mode": "wall_mounted"}) == "wall", "wall install mode changed")
	_expect(RouteRendererRef.normalize_install_mode({"hidden_installation": true}) == "hidden", "hidden install mode changed")
	_expect(RouteRendererRef.normalize_install_mode({}) == "floor", "default floor install mode changed")
	_expect(RouteRendererRef.normalize_wall_routing_mode({"route_mode": "in-wall"}) == "inner", "inner routing normalization changed")
	_expect(RouteRendererRef.normalize_wall_routing_mode({"route_mode": "outer", "routing_mode": "inner"}) == "outer", "route mode precedence changed")
	_expect(RouteRendererRef.normalize_wall_routing_mode({}) == "outer", "default outer routing changed")
	_expect(RouteRendererRef.get_health_state({"cut": true}) == "cut", "cut health state changed")
	_expect(RouteRendererRef.is_broken_route({"cable_state": "broken"}), "broken route detection changed")
	_expect(RouteRendererRef.get_route_family({"map_constructor_prefab_id": "external_air_duct"}) == "air_duct", "air duct family changed")
	_expect(RouteRendererRef.get_route_family({"object_type": "external_water_pipe"}) == "water_pipe", "water pipe family changed")
	_expect(RouteRendererRef.get_route_family({"object_type": "power_cable"}) == "cable", "cable family changed")
	_expect(RouteRendererRef.is_wall_procedural_routed_object({"object_type": "power_cable"}, "wall"), "wall route classification changed")
	_expect(not RouteRendererRef.is_wall_procedural_routed_object({"object_type": "power_cable"}, "floor"), "floor cable must not classify as wall route")

func _check_wall_face_geometry() -> void:
	var half := Vector2(64.0, 35.5)
	var sw: Dictionary = RouteRendererRef.build_wall_face_segment(Vector2.ZERO, half, "sw", 50.0)
	_expect(Vector2(sw.get("start_edge", Vector2.ZERO)).is_equal_approx(Vector2(-64.0, -50.0)), "SW cable start changed")
	_expect(Vector2(sw.get("end_edge", Vector2.ZERO)).is_equal_approx(Vector2(0.0, -14.5)), "SW cable end changed")
	_expect(Vector2(sw.get("mid", Vector2.ZERO)).is_equal_approx(Vector2(-32.0, -32.25)), "SW cable midpoint changed")
	var se: Dictionary = RouteRendererRef.build_wall_face_segment(Vector2.ZERO, half, "se", 50.0)
	_expect(Vector2(se.get("start_edge", Vector2.ZERO)).is_equal_approx(Vector2(0.0, -14.5)), "SE cable start changed")
	_expect(Vector2(se.get("end_edge", Vector2.ZERO)).is_equal_approx(Vector2(64.0, -50.0)), "SE cable end changed")
	_expect(RouteRendererRef.get_wall_face_occluder_delta("sw") == Vector2i(0, 1), "SW occluder delta changed")
	_expect(RouteRendererRef.get_wall_face_occluder_delta("se") == Vector2i(1, 0), "SE occluder delta changed")
	var sw_route: Dictionary = RouteRendererRef.build_wall_route_segment(Vector2(100.0, 80.0), half, "sw")
	var se_route: Dictionary = RouteRendererRef.build_wall_route_segment(Vector2(100.0, 80.0), half, "se")
	_expect(str(sw_route.get("side", "")) == "sw", "SW route side changed")
	_expect(str(se_route.get("side", "")) == "se", "SE route side changed")
	_expect(Vector2(sw_route.get("start", Vector2.ZERO)).x < Vector2(sw_route.get("end", Vector2.ZERO)).x, "SW route direction changed")
	_expect(Vector2(se_route.get("start", Vector2.ZERO)).x < Vector2(se_route.get("end", Vector2.ZERO)).x, "SE route direction changed")

func _check_wall_cable_commands() -> void:
	var profile: Dictionary = {"base": Color.RED, "accent": Color.YELLOW, "outline": Color.BLACK}
	var normal_commands: Array[Dictionary] = RouteRendererRef.build_wall_cable_commands(Vector2.ZERO, Vector2(100.0, 0.0), Vector2.UP, profile, false)
	_expect(normal_commands.size() == 1, "normal wall cable command count changed")
	_expect(str(normal_commands[0].get("kind", "")) == "wall_cable_segment", "normal wall cable command kind changed")
	var broken_commands: Array[Dictionary] = RouteRendererRef.build_wall_cable_commands(Vector2.ZERO, Vector2(100.0, 0.0), Vector2.UP, profile, true)
	_expect(broken_commands.size() == 10, "broken wall cable command count changed")
	_expect(str(broken_commands[0].get("kind", "")) == "wall_cable_segment", "broken cable first segment changed")
	_expect(str(broken_commands[4].get("kind", "")) == "line", "broken cable hanging wire ordering changed")
	var break_overlay: Array[Dictionary] = RouteRendererRef.build_wall_break_overlay_commands({"start_edge": Vector2.ZERO, "mid": Vector2(50.0, 0.0), "end_edge": Vector2(100.0, 0.0), "normal": Vector2.UP}, profile)
	_expect(break_overlay.size() == 9, "break overlay command count changed")
	_expect(is_equal_approx(float(break_overlay[0].get("width", 0.0)), 8.0), "break overlay mask width changed")

func _check_floor_policy() -> void:
	var hidden_commands: Array[Dictionary] = RouteRendererRef.build_floor_mode_segment_commands(Vector2.ZERO, Vector2(30.0, 0.0), "hidden")
	_expect(hidden_commands.size() >= 5, "hidden floor cable dashes changed")
	for command in hidden_commands:
		_expect(str(command.get("kind", "")) == "line", "hidden floor cable command type changed")
	var floor_commands: Array[Dictionary] = RouteRendererRef.build_floor_mode_segment_commands(Vector2.ZERO, Vector2(30.0, 0.0), "floor")
	_expect(floor_commands.size() == 3, "floor cable layered command count changed")
	var straight_plan: Dictionary = RouteRendererRef.build_floor_topology_plan({"shape": "straight", "connected_dirs": {"east": true, "west": true}, "valid": true})
	_expect(str(straight_plan.get("geometry_mode", "")) == "straight", "straight topology plan changed")
	var elbow_plan: Dictionary = RouteRendererRef.build_floor_topology_plan({"shape": "corner", "connected_dirs": {"north": true, "east": true}, "valid": true})
	_expect(str(elbow_plan.get("geometry_mode", "")) == "elbow", "elbow topology plan changed")
	var end_plan: Dictionary = RouteRendererRef.build_floor_topology_plan({"shape": "end", "connected_dirs": {"north": true}, "valid": true})
	_expect(bool(end_plan.get("endpoint_cap", false)), "floor end-cap policy changed")
	var junction_plan: Dictionary = RouteRendererRef.build_floor_topology_plan({"shape": "junction_t", "connected_dirs": {"north": true, "east": true, "west": true}, "valid": true})
	_expect(bool(junction_plan.get("junction_marker", false)), "junction marker policy changed")

func _check_procedural_route_commands() -> void:
	var segment: Dictionary = {"start": Vector2.ZERO, "end": Vector2(100.0, 0.0), "normal": Vector2.UP}
	var cable_outer: Array[Dictionary] = RouteRendererRef.build_procedural_route_commands("cable", segment, "outer")
	_expect(cable_outer.size() == 7, "outer cable command count changed")
	var cable_inner: Array[Dictionary] = RouteRendererRef.build_procedural_route_commands("cable", segment, "inner")
	_expect(cable_inner.size() > 5, "inner cable dashed commands changed")
	var air_outer: Array[Dictionary] = RouteRendererRef.build_procedural_route_commands("air_duct", segment, "outer")
	_expect(air_outer.size() == 7, "outer air duct command count changed")
	var air_inner: Array[Dictionary] = RouteRendererRef.build_procedural_route_commands("air_duct", segment, "inner")
	_expect(air_inner.size() == 4, "inner air duct command count changed")
	var water_outer: Array[Dictionary] = RouteRendererRef.build_procedural_route_commands("water_pipe", segment, "outer")
	_expect(water_outer.size() == 8, "outer water pipe command count changed")
	var water_inner: Array[Dictionary] = RouteRendererRef.build_procedural_route_commands("water_pipe", segment, "inner")
	_expect(water_inner.size() == 3, "inner water pipe command count changed")
	for commands in [cable_outer, air_outer, water_outer]:
		for command in commands:
			_expect(command.has("kind"), "route command missing kind")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
