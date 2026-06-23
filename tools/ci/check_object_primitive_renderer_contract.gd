extends SceneTree

const ObjectPrimitiveRendererRef = preload("res://scripts/visual/renderer/object_primitive_renderer.gd")

func _fail(message: String) -> void:
	push_error(message)
	quit(1)

func _assert_true(value: bool, message: String) -> void:
	if not value:
		_fail(message)

func _check_schema(commands: Array[Dictionary]) -> void:
	var last_order: int = -1
	for command in commands:
		_assert_true(command.has("kind"), "command missing kind")
		_assert_true(command.has("order"), "command missing order")
		var order: int = int(command.get("order", -1))
		_assert_true(order > last_order, "command order must increase monotonically")
		last_order = order
		var kind: String = str(command.get("kind", ""))
		_assert_true(kind in ["polygon", "line", "circle", "rect", "arc", "text"], "unsupported command kind: %s" % kind)

func _init() -> void:
	var profiles: Dictionary = ObjectPrimitiveRendererRef.get_visual_profiles()
	_assert_true(profiles.has("door") and profiles.has("terminal") and profiles.has("generic_object"), "representative object profile catalog entries missing")
	_assert_true(ObjectPrimitiveRendererRef.get_profile("").get("label") == "Generic Object", "empty profile key must safely fall back")
	var context: Dictionary = {
		"visual_center": Vector2(100.0, 80.0),
		"diamond": PackedVector2Array([Vector2(100.0, 40.0), Vector2(164.0, 80.0), Vector2(100.0, 120.0), Vector2(36.0, 80.0)]),
		"half_size": Vector2(64.0, 35.5),
		"marker_height": 18.0,
		"profile": ObjectPrimitiveRendererRef.get_profile("terminal"),
		"outlines": false,
	}
	for shape in ["slab", "door_panel", "pillar", "terminal_console", "small_marker", "line", "heat_marker"]:
		var commands: Array[Dictionary] = ObjectPrimitiveRendererRef.build_shape_commands(shape, context)
		_assert_true(not commands.is_empty(), "shape produced no commands: %s" % shape)
		_check_schema(commands)
		var outlined_context: Dictionary = context.duplicate(true)
		outlined_context["outlines"] = true
		var outlined_commands: Array[Dictionary] = ObjectPrimitiveRendererRef.build_shape_commands(shape, outlined_context)
		_assert_true(outlined_commands.size() >= commands.size(), "outlines should not remove commands: %s" % shape)
		_check_schema(outlined_commands)
	_assert_true(ObjectPrimitiveRendererRef.build_shape_commands("", context).is_empty(), "empty unsupported shape should draw nothing")
	_assert_true(ObjectPrimitiveRendererRef.build_shape_commands("unsupported", context).is_empty(), "unsupported shape should draw nothing")
	_assert_true(ObjectPrimitiveRendererRef.build_shape_commands("slab", {"diamond": PackedVector2Array(), "profile": {}}).is_empty(), "invalid slab polygon should draw nothing")
	for key in ["door_terminal", "platform_terminal", "cooling_terminal", "firewall", "circuit_breaker", "fuse_box", "light_switch", "power_switcher", "power_socket", "light", "power_cable_reel"]:
		var wall_commands: Array[Dictionary] = ObjectPrimitiveRendererRef.build_wall_mounted_commands(key, {"visual_center": Vector2(20.0, 30.0), "profile": ObjectPrimitiveRendererRef.get_profile(key), "outlines": true})
		_assert_true(not wall_commands.is_empty(), "wall-mounted profile produced no commands: %s" % key)
		_check_schema(wall_commands)
	_assert_true(ObjectPrimitiveRendererRef.build_wall_mounted_commands("external_air_duct", context).is_empty(), "unsupported wall-mounted primitive should draw nothing")
	_check_schema(ObjectPrimitiveRendererRef.build_floor_base_commands({"shadow_polygon": PackedVector2Array([Vector2.ZERO, Vector2.RIGHT, Vector2.DOWN]), "footprint_polygon": PackedVector2Array([Vector2.ZERO, Vector2.RIGHT, Vector2.DOWN])}))
	_assert_true(ObjectPrimitiveRendererRef.build_floor_base_commands({"is_wall_visual": true}).is_empty(), "wall visuals should skip floor base")
	_assert_true(ObjectPrimitiveRendererRef.build_floor_base_commands({"shadow_polygon": PackedVector2Array([Vector2.ZERO])}).is_empty(), "invalid floor polygons should draw nothing")
	_check_schema(ObjectPrimitiveRendererRef.build_texture_accent_commands({"visual_center": Vector2.ZERO, "marker_height": 18.0, "accent": Color.WHITE, "enabled": true}))
	_assert_true(ObjectPrimitiveRendererRef.build_texture_accent_commands({"enabled": false}).is_empty(), "disabled texture accent should draw nothing")
	var first: Array[Dictionary] = ObjectPrimitiveRendererRef.build_shape_commands("small_marker", context)
	var second: Array[Dictionary] = ObjectPrimitiveRendererRef.build_shape_commands("small_marker", context)
	_assert_true(var_to_str(first) == var_to_str(second), "repeated identical input must be stable")
	print("ObjectPrimitiveRenderer contract OK")
	quit(0)
