extends SceneTree

const ObjectRendererRef = preload("res://scripts/visual/renderer/object_renderer.gd")
const IsoDrawEntryContractRef = preload("res://scripts/visual/renderer/iso_draw_entry_contract.gd")

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
	_expect(is_equal_approx(ObjectRendererRef.get_sub_order("wall_mounted", "terminal"), IsoDrawEntryContractRef.SUB_ORDER_WALL_MOUNTED), "wall-mounted sub-order changed")
	_expect(is_equal_approx(ObjectRendererRef.get_sub_order("cable", "generic_object"), IsoDrawEntryContractRef.SUB_ORDER_CABLE), "cable sub-order changed")
	_expect(is_equal_approx(ObjectRendererRef.get_sub_order("terminal", "terminal"), IsoDrawEntryContractRef.SUB_ORDER_TERMINAL), "terminal sub-order changed")
	_expect(is_equal_approx(ObjectRendererRef.get_sub_order("item", "door"), IsoDrawEntryContractRef.SUB_ORDER_DOOR), "door sub-order changed")
	_expect(is_equal_approx(ObjectRendererRef.get_sub_order("item", "generic_object"), IsoDrawEntryContractRef.SUB_ORDER_ITEM), "item sub-order changed")

	_expect(ObjectRendererRef.get_entry_kind("wall_mounted", "terminal") == "wall_mounted", "wall-mounted entry kind changed")
	_expect(ObjectRendererRef.get_entry_kind("cable", "generic_object") == "cable", "cable entry kind changed")
	_expect(ObjectRendererRef.get_entry_kind("item", "door") == "door", "door entry kind changed")
	_expect(ObjectRendererRef.get_entry_kind("terminal", "terminal") == "object", "terminal entry kind changed")
	_expect(ObjectRendererRef.get_entry_kind("item", "generic_object") == "object", "item entry kind changed")

	_expect(is_equal_approx(ObjectRendererRef.get_layer_bias("wall_mounted"), IsoDrawEntryContractRef.LAYER_BIAS_WALL_MOUNTED), "wall-mounted layer bias changed")
	_expect(is_equal_approx(ObjectRendererRef.get_layer_bias("cable"), IsoDrawEntryContractRef.LAYER_BIAS_CABLE), "cable layer bias changed")
	_expect(is_equal_approx(ObjectRendererRef.get_layer_bias("terminal"), IsoDrawEntryContractRef.LAYER_BIAS_TERMINAL), "terminal layer bias changed")
	_expect(is_equal_approx(ObjectRendererRef.get_layer_bias("item"), IsoDrawEntryContractRef.LAYER_BIAS_ITEM), "item layer bias changed")

	_expect(ObjectRendererRef.get_wall_mounted_render_layer({"wall_render_layer": 7}) == 7, "explicit wall render layer changed")
	_expect(ObjectRendererRef.get_wall_mounted_render_layer({"object_type": "power_cable"}) == 10, "cable wall render layer changed")
	_expect(ObjectRendererRef.get_wall_mounted_render_layer({"map_constructor_prefab_id": "external_air_duct"}) == 10, "air duct wall render layer changed")
	_expect(ObjectRendererRef.get_wall_mounted_render_layer({"object_type": "terminal"}, true) == 10, "routing utility wall render layer changed")
	_expect(ObjectRendererRef.get_wall_mounted_render_layer({"object_type": "terminal"}) == 20, "normal wall-mounted render layer changed")

	_check_draw_entry_case("item", "generic_object", 2.0, {}, "object", IsoDrawEntryContractRef.SUB_ORDER_ITEM, IsoDrawEntryContractRef.LAYER_BIAS_ITEM)
	_check_draw_entry_case("item", "door", 1.0, {"object_type": "door"}, "door", IsoDrawEntryContractRef.SUB_ORDER_DOOR, IsoDrawEntryContractRef.LAYER_BIAS_ITEM)
	_check_draw_entry_case("terminal", "terminal", 3.0, {"object_type": "terminal"}, "object", IsoDrawEntryContractRef.SUB_ORDER_TERMINAL, IsoDrawEntryContractRef.LAYER_BIAS_TERMINAL)
	_check_draw_entry_case("cable", "cable", 2.0, {"object_type": "power_cable"}, "cable", IsoDrawEntryContractRef.SUB_ORDER_CABLE, IsoDrawEntryContractRef.LAYER_BIAS_CABLE)
	_check_draw_entry_case("wall_mounted", "terminal", 4.0, {"object_type": "terminal"}, "wall_mounted", IsoDrawEntryContractRef.SUB_ORDER_WALL_MOUNTED, IsoDrawEntryContractRef.LAYER_BIAS_WALL_MOUNTED, 20)
	_check_draw_entry_case("wall_mounted", "external_air_duct", 5.0, {"object_type": "external_air_duct"}, "wall_mounted", IsoDrawEntryContractRef.SUB_ORDER_WALL_MOUNTED, IsoDrawEntryContractRef.LAYER_BIAS_WALL_MOUNTED, 10, true)

func _check_draw_entry_case(
	layer_name: String,
	profile_key: String,
	object_index: float,
	object_data: Dictionary,
	expected_kind: String,
	expected_base_sub_order: float,
	expected_base_layer_bias: float,
	expected_wall_render_layer: int = 20,
	is_routing_utility: bool = false
) -> void:
	var cell := Vector2i(2, 3)
	var payload: Dictionary = {"profile_key": profile_key, "object_data": object_data}
	var depth_key := 42.0
	var entry: Dictionary = ObjectRendererRef.make_draw_entry(cell, layer_name, object_index, payload, depth_key, is_routing_utility)
	var stable_order_step := 0.00001 if layer_name == "wall_mounted" else 0.01
	var expected_sub_order := expected_base_sub_order + object_index * stable_order_step
	if layer_name == "wall_mounted":
		expected_sub_order += float(expected_wall_render_layer) * 0.001
	var expected_layer_bias := expected_base_layer_bias + object_index * 0.01

	_expect(IsoDrawEntryContractRef.validate_entry(entry).is_empty(), "%s entry does not satisfy draw-entry contract" % layer_name)
	_expect(Vector2i(entry.get("cell", Vector2i(-1, -1))) == cell, "%s entry cell changed" % layer_name)
	_expect(str(entry.get("layer", "")) == layer_name, "%s entry layer changed" % layer_name)
	_expect(str(entry.get("kind", "")) == expected_kind, "%s entry kind changed" % layer_name)
	_expect(is_equal_approx(float(entry.get("depth_key", 0.0)), depth_key), "%s entry depth changed" % layer_name)
	_expect(is_equal_approx(float(entry.get("sub_order", 0.0)), expected_sub_order), "%s entry sub-order changed" % layer_name)
	_expect(is_equal_approx(float(entry.get("layer_bias", 0.0)), expected_layer_bias), "%s entry layer bias changed" % layer_name)
	_expect(Dictionary(entry.get("payload", {})) == payload, "%s entry payload changed" % layer_name)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
