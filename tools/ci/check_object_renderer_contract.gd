extends SceneTree

const ObjectRendererRef = preload("res://scripts/visual/renderer/object_renderer.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_check_profile_policy()
	_check_mount_and_state_policy()
	_check_asset_policy()
	_check_entry_policy()
	if failures.is_empty():
		print("ObjectRenderer policy contract OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _check_profile_policy() -> void:
	_expect(ObjectRendererRef.get_asset_key_for_profile("door") != "object_generic", "door profile asset mapping changed")
	_expect(ObjectRendererRef.get_asset_key_for_profile("terminal") == "terminal_01", "terminal profile asset mapping changed")
	_expect(ObjectRendererRef.get_profile_key_for_object_data({"object_type": "digital_key"}) == "keycard", "digital key profile classification changed")
	_expect(ObjectRendererRef.get_profile_key_for_object_data({"object_type": "power_switcher", "switcher_type": "light_switcher"}) == "light_switcher", "light switcher profile classification changed")
	_expect(ObjectRendererRef.get_profile_key_for_object_data({"object_type": "enemy", "enemy_type": "bug"}) == "bug", "bug profile classification changed")

func _check_mount_and_state_policy() -> void:
	_expect(ObjectRendererRef.get_mount_mode({"placement_mode": "wall_mounted"}) == "wall", "wall mount classification changed")
	_expect(ObjectRendererRef.get_mount_mode({"placement": "floor"}) == "floor", "floor mount classification changed")
	_expect(ObjectRendererRef.is_state_on({"state": "active"}), "active switch state must be on")
	_expect(not ObjectRendererRef.is_state_on({"object_type": "power_switcher_off"}), "off type suffix must remain off")
	_expect(ObjectRendererRef.is_fuse_present({"fuse_present": true}), "explicit fuse presence changed")
	_expect(not ObjectRendererRef.is_fuse_present({"object_type": "fuse_box_empty"}), "empty fuse box classification changed")
	_expect(ObjectRendererRef.is_wall_mounted_runtime_object({"is_wall_mounted": true}), "wall-mounted runtime classification changed")
	_expect(ObjectRendererRef.get_wall_mounted_cardinal_side({"wall_side": "east"}) == "east", "wall-mounted cardinal fallback changed")

func _check_asset_policy() -> void:
	_expect(ObjectRendererRef.get_asset_key_for_object_data({"object_type": "platform"}, "generic_object") == "", "platform must not resolve as a loose object asset")
	_expect(ObjectRendererRef.get_asset_key_for_object_data({"object_type": "fire_barrel"}, "barrel") == "fire_barrel_floor_01", "fire barrel asset mapping changed")
	_expect(ObjectRendererRef.get_asset_key_for_object_data({"object_type": "cable_reel", "placement_mode": "wall_mounted"}, "cable_reel") == "cable_reel_02", "wall cable reel asset mapping changed")
	_expect(ObjectRendererRef.get_asset_key_for_object_data({"object_type": "external_radiator"}, "radiator") == "radiator_floor_01", "radiator asset mapping changed")
	_expect(ObjectRendererRef.get_asset_key_for_object_data({"object_type": "digital_key"}, "keycard") == "object_keycard", "digital key asset mapping changed")

func _check_entry_policy() -> void:
	_expect(ObjectRendererRef.get_sub_order("wall_mounted", "terminal") > ObjectRendererRef.get_sub_order("item", "generic_object"), "wall-mounted sub-order changed")
	_expect(ObjectRendererRef.get_wall_mounted_render_layer({"object_type": "external_air_duct"}) == 10, "routing utility wall layer changed")
	_expect(ObjectRendererRef.get_entry_kind("item", "door") == "door", "door entry kind changed")
	var payload: Dictionary = {"profile_key": "terminal", "object_data": {"object_type": "terminal"}}
	var entry: Dictionary = ObjectRendererRef.make_draw_entry(Vector2i(2, 3), "terminal", 0.0, payload, 42.0)
	_expect(str(entry.get("layer", "")) == "terminal", "object entry layer changed")
	_expect(str(entry.get("kind", "")) == "object", "terminal entry kind changed")
	_expect(is_equal_approx(float(entry.get("depth_key", 0.0)), 42.0), "object entry depth changed")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
