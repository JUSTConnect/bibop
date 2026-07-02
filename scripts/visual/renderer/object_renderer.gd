extends RefCounted
class_name ObjectRenderer

const VisualAssetCatalogRef = preload("res://scripts/visual/visual_asset_catalog.gd")
const VisualStateAssetServiceRef = preload("res://scripts/visual/visual_state_asset_service.gd")
const CanonicalVisualDescriptorServiceRef = preload("res://scripts/visual/canonical_visual_descriptor_service.gd")
const IsoDrawEntryContractRef = preload("res://scripts/visual/renderer/iso_draw_entry_contract.gd")
const WallMountedPlacementRulesServiceRef = preload("res://scripts/game/wall/wall_mounted_placement_rules_service.gd")

const WALL_SIDE_ORDER: Array[String] = ["north", "east", "south", "west"]

static func get_asset_key_for_profile(profile_key: String) -> String:
	var key: String = profile_key.strip_edges().to_lower()
	match key:
		"door", "digital_door", "powered_gate": return VisualAssetCatalogRef.resolve_object_asset_id("door")
		"terminal", "airflow_terminal", "door_terminal", "platform_terminal", "cooling_terminal": return "terminal_01"
		"key": return "object_key"
		"keycard", "digital_key": return "object_keycard"
		"fuse": return VisualAssetCatalogRef.resolve_object_asset_id("fuse")
		"fuse_box": return "fuse_box_in_01"
		"repair_kit": return VisualAssetCatalogRef.resolve_object_asset_id("repair_kit")
		"access_code", "datafile": return "object_access_code"
		"component": return "object_component"
		"socket": return "object_socket"
		"cable": return "object_cable"
		"cable_reel", "power_cable_reel": return "cable_reel_01"
		"button", "platform_control", "fan_control", "fan_speed_control": return "object_button"
		"switch", "breaker", "circuit_breaker", "light_switch", "power_switcher": return VisualAssetCatalogRef.resolve_object_asset_id("power_switcher_off")
		"power_source": return "power_source_01"
		"radiator": return "radiator_01"
		"light": return "light_off_wall_01"
		"barrel": return "barrel_01"
		"crate": return "normal_crate_floor_01"
		"box", "steel_box": return VisualAssetCatalogRef.resolve_object_asset_id("steel_box")
		"case": return VisualAssetCatalogRef.resolve_object_asset_id("case")
	return "object_generic"

static func get_profile_key_for_object_data(object_data: Dictionary, fallback_profile_key: String = "generic_object") -> String:
	var type_value: String = str(object_data.get("object_type", object_data.get("item_type", object_data.get("type", "")))).to_lower().strip_edges()
	var prefab_value: String = str(object_data.get("map_constructor_prefab_id", "")).to_lower().strip_edges()
	var key_kind: String = str(object_data.get("key_kind", object_data.get("key_type", ""))).to_lower().strip_edges()
	var blob: String = "%s %s %s" % [type_value, prefab_value, key_kind]
	if type_value == "enemy":
		return "bug" if str(object_data.get("enemy_type", object_data.get("enemy_kind", "vagus"))).to_lower().strip_edges() == "bug" else "vagus"
	if blob.contains("digital_key") or blob.contains("keycard"): return "keycard"
	if blob.contains("key"): return "key"
	if blob.contains("fuse"): return "fuse"
	if blob.contains("repair_kit"): return "repair_kit"
	if blob.contains("access_code") or blob.contains("code"): return "access_code"
	if blob.contains("cable_reel") or blob.contains("cable reel"): return "cable_reel"
	if blob.contains("power_cable") or blob.contains("cable") or blob.contains("wire"): return "cable"
	if blob.contains("power_source"): return "power_source"
	if blob.contains("radiator"): return "radiator"
	if blob.contains("power_switcher"):
		var switcher_type: String = str(object_data.get("switcher_type", "")).strip_edges().to_lower()
		if switcher_type == "light_switcher": return "light_switcher"
		if switcher_type == "power_breaker": return "power_breaker"
		return "power_switcher"
	if blob.contains("circuit_switch") or blob.contains("light_switch") or blob.contains("breaker") or blob.contains("switch"): return "switch"
	if blob.contains("light"): return "light"
	if blob.contains("door") or blob.contains("powered_gate"): return "door"
	if blob.contains("terminal"): return "terminal"
	if blob.contains("barrel"): return "barrel"
	if VisualStateAssetServiceRef.is_loot_case_object(object_data): return "case"
	if blob.contains("crate") or blob.contains("box"): return "crate"
	return "generic_object" if fallback_profile_key.strip_edges().is_empty() else fallback_profile_key

static func get_mount_mode(object_data: Dictionary) -> String:
	var mount: String = str(object_data.get("mount", object_data.get("cable_install_mode", object_data.get("install_mode", object_data.get("placement_mode", object_data.get("placement", "floor")))))).to_lower().strip_edges()
	return "wall" if mount in ["wall", "wall_mounted"] or bool(object_data.get("is_wall_mounted", false)) else "floor"

static func is_state_on(object_data: Dictionary) -> bool:
	var type_value: String = str(object_data.get("object_type", object_data.get("type", ""))).to_lower().strip_edges()
	var state: String = str(object_data.get("switch_state", object_data.get("state", "off"))).to_lower().strip_edges()
	if type_value.ends_with("_on") or type_value.contains("_on_"): return true
	if type_value.ends_with("_off") or type_value.contains("_off_"): return false
	if state in ["on", "off", "switch_on", "switch_off", "active", "inactive"]: return state in ["on", "switch_on", "active"]
	return bool(object_data.get("is_on", false)) if object_data.has("is_on") else false

static func is_fuse_present(object_data: Dictionary) -> bool:
	var type_value: String = str(object_data.get("object_type", object_data.get("type", ""))).to_lower().strip_edges()
	if type_value.contains("installed") or type_value.contains("_in"): return true
	if type_value.contains("empty") or type_value.contains("_out"): return false
	if object_data.has("fuse_present"): return bool(object_data.get("fuse_present", false))
	return bool(object_data.get("fuse_installed", str(object_data.get("state", "")).to_lower().strip_edges() == "installed"))

static func is_wall_mounted_runtime_object(object_data: Dictionary) -> bool:
	return str(object_data.get("placement_mode", object_data.get("placement", ""))).strip_edges().to_lower() == "wall_mounted" or bool(object_data.get("is_wall_mounted", false))

static func get_wall_mounted_cardinal_side(object_data: Dictionary) -> String:
	var wall_side: String = str(object_data.get("interaction_side", object_data.get("wall_side", ""))).strip_edges().to_lower()
	var direction: Vector2i = WallMountedPlacementRulesServiceRef.get_required_interaction_direction(object_data)
	if direction == Vector2i(0, -1): return "north"
	if direction == Vector2i(1, 0): return "east"
	if direction == Vector2i(0, 1): return "south"
	if direction == Vector2i(-1, 0): return "west"
	return wall_side if wall_side in WALL_SIDE_ORDER else "west"

static func has_explicit_visual_descriptor_fields(object_data: Dictionary) -> bool:
	for key in ["visual_family", "visual_asset_family", "visual_state_policy", "visual_asset_id", "visual_texture_asset_id", "texture_asset_id", "asset_id"]:
		if object_data.has(key) and not str(object_data.get(key, "")).strip_edges().is_empty():
			return true
	return false

static func get_canonical_visual_asset_key(object_data: Dictionary) -> String:
	if not has_explicit_visual_descriptor_fields(object_data) and not VisualStateAssetServiceRef.object_uses_visual_states(object_data):
		return ""
	var descriptor: Dictionary = CanonicalVisualDescriptorServiceRef.build_descriptor(object_data)
	if not CanonicalVisualDescriptorServiceRef.is_valid_descriptor(descriptor):
		return ""
	return str(descriptor.get(CanonicalVisualDescriptorServiceRef.FIELD_VISUAL_ASSET_ID, "")).strip_edges()

static func get_asset_key_for_object_data(object_data: Dictionary, fallback_profile_key: String) -> String:
	var descriptor_asset_key: String = get_canonical_visual_asset_key(object_data)
	if not descriptor_asset_key.is_empty():
		return descriptor_asset_key
	var fallback_asset_key: String = get_asset_key_for_profile(fallback_profile_key)
	var type_value: String = str(object_data.get("object_type", object_data.get("item_type", object_data.get("type", "")))).to_lower().strip_edges()
	var prefab_value: String = str(object_data.get("map_constructor_prefab_id", object_data.get("catalog_id", ""))).to_lower().strip_edges()
	var group_value: String = str(object_data.get("group", "")).to_lower().strip_edges()
	var name_value: String = str(object_data.get("name", "")).to_lower().strip_edges()
	var id_value: String = str(object_data.get("id", object_data.get("object_id", ""))).to_lower().strip_edges()
	var blob: String = "%s %s %s %s %s %s" % [fallback_profile_key.to_lower(), type_value, prefab_value, group_value, name_value, id_value]
	if type_value == "platform" or blob.contains(" platform"):
		return ""
	if type_value == "power_switcher" or blob.contains("power_switcher"):
		var mount: String = get_mount_mode(object_data)
		var on_suffix: String = "on" if is_state_on(object_data) else "off"
		if mount == "wall":
			return VisualAssetCatalogRef.resolve_object_asset_id("power_switcher_%s_wall" % on_suffix)
		return VisualAssetCatalogRef.resolve_object_asset_id("power_switcher_%s_floor" % on_suffix)
	if type_value == "fuse_box" or blob.contains("fuse_box"):
		var fuse_suffix: String = "in" if is_fuse_present(object_data) else "out"
		if get_mount_mode(object_data) == "wall":
			return "fuse_box_%s_wall_01" % fuse_suffix
		return "fuse_box_%s_01" % fuse_suffix
	if blob.contains("circuit_switch") or blob.contains("light_switch") or blob.contains("breaker") or blob.contains("switch"):
		var switch_mount: String = get_mount_mode(object_data)
		var switch_suffix: String = "on" if is_state_on(object_data) else "off"
		if switch_mount == "wall":
			return VisualAssetCatalogRef.resolve_object_asset_id("power_switcher_%s_wall" % switch_suffix)
		return VisualAssetCatalogRef.resolve_object_asset_id("power_switcher_%s_floor" % switch_suffix)
	if type_value == "barrel" or type_value == "fire_barrel" or type_value == "normal_barrel" or blob.contains("barrel"):
		var barrel_variant: String = str(object_data.get("variant", "normal")).to_lower().strip_edges()
		if barrel_variant == "fire" or type_value == "fire_barrel" or blob.contains("fire_barrel") or blob.contains("fire barrel") or blob.contains("flammable"):
			return "fire_barrel_floor_01"
		return "normal_barrel_floor_01"
	if VisualStateAssetServiceRef.is_loot_case_object(object_data):
		return VisualStateAssetServiceRef.resolve_visual_asset_id(object_data)
	if type_value == "crate":
		var crate_type: String = str(object_data.get("crate_type", object_data.get("variant", "normal"))).to_lower().strip_edges()
		if crate_type in ["heavy", "steel", "steel_box", "heavy_crate"]:
			return VisualAssetCatalogRef.resolve_object_asset_id("steel_box")
		return "normal_crate_floor_01"
	if type_value == "heavy_crate" or blob.contains("heavy_crate") or blob.contains("heavy crate") or type_value == "steel_box" or blob.contains("steel_box") or blob.contains("steel box"):
		return VisualAssetCatalogRef.resolve_object_asset_id("steel_box")
	if type_value == "normal_crate" or blob.contains("normal_crate") or blob.contains("normal crate"):
		return "normal_crate_floor_01"
	if type_value == "cable_reel" or type_value == "power_cable_reel" or blob.contains("cable_reel") or blob.contains("cable reel"):
		return "cable_reel_02" if get_mount_mode(object_data) == "wall" else "cable_reel_01"
	if type_value == "power_source" or blob.contains("power_source"):
		return "power_source_01"
	if type_value == "radiator" or type_value == "external_radiator" or blob.contains("radiator"):
		return "radiator_floor_01"
	if blob.contains("terminal") or blob.contains("console") or blob.contains("control_panel"):
		return "terminal_01"
	if blob.contains("door") or blob.contains("powered_gate"):
		return VisualAssetCatalogRef.resolve_object_asset_id("door")
	if blob.contains("terminal") or blob.contains("console") or blob.contains("control_panel"):
		return "object_terminal"
	if blob.contains("keycard") or blob.contains("digital_key"):
		return "object_keycard"
	if blob.contains("key"):
		return "object_key"
	if blob.contains("fuse"):
		return VisualAssetCatalogRef.resolve_object_asset_id("fuse")
	if blob.contains("repair_kit") or blob.contains("repair kit"):
		return VisualAssetCatalogRef.resolve_object_asset_id("repair_kit")
	if blob.contains("access_code") or blob.contains("access code"):
		return "object_access_code"
	if blob.contains("component"):
		return "object_component"
	if blob.contains("socket"):
		return "object_socket"
	if blob.contains("cable_reel") or blob.contains("cable reel"):
		return "object_cable_reel"
	if blob.contains("cable"):
		return "object_cable"
	if blob.contains("button"):
		return "object_button"
	if blob.contains("switch") or blob.contains("breaker"):
		var fallback_mount: String = get_mount_mode(object_data)
		var fallback_switch_suffix: String = "on" if is_state_on(object_data) else "off"
		if fallback_mount == "wall":
			return "power_switcher_%s_wall_01" % fallback_switch_suffix
		return "power_switcher_%s_01" % fallback_switch_suffix
	if fallback_asset_key.is_empty():
		return "object_generic"
	return fallback_asset_key

static func get_sub_order(layer_name: String, profile_key: String) -> float:
	if layer_name == "wall_mounted":
		return IsoDrawEntryContractRef.SUB_ORDER_WALL_MOUNTED
	if layer_name == "cable":
		return IsoDrawEntryContractRef.SUB_ORDER_CABLE
	if layer_name == "terminal":
		return IsoDrawEntryContractRef.SUB_ORDER_TERMINAL
	if profile_key.contains("door") or profile_key.contains("gate"):
		return IsoDrawEntryContractRef.SUB_ORDER_DOOR
	return IsoDrawEntryContractRef.SUB_ORDER_ITEM

static func get_wall_mounted_render_layer(object_data: Dictionary, is_routing_utility: bool = false) -> int:
	if object_data.has("wall_render_layer"):
		return int(object_data.get("wall_render_layer", 20))
	var object_type: String = str(object_data.get("object_type", object_data.get("type", ""))).strip_edges().to_lower()
	var prefab_id: String = str(object_data.get("map_constructor_prefab_id", object_data.get("prefab_id", ""))).strip_edges().to_lower()
	var visual_family: String = str(object_data.get("visual_family", object_data.get("visual_asset_family", ""))).strip_edges().to_lower()
	var routing_kind: String = str(object_data.get("routing_kind", "")).strip_edges().to_lower()
	if object_type.contains("cable") or prefab_id.contains("cable") or visual_family.contains("cable") or routing_kind.contains("cable"):
		return 10
	if prefab_id in ["external_air_duct", "external_water_pipe"] or object_type in ["external_air_duct", "external_water_pipe", "air_duct", "water_pipe"]:
		return 10
	if is_routing_utility:
		return 10
	return 20

static func get_entry_kind(layer_name: String, profile_key: String) -> String:
	if layer_name == "wall_mounted":
		return "wall_mounted"
	if layer_name == "cable":
		return "cable"
	if profile_key.contains("door") or profile_key.contains("gate"):
		return "door"
	return "object"

static func get_layer_bias(layer_name: String) -> float:
	if layer_name == "wall_mounted":
		return IsoDrawEntryContractRef.LAYER_BIAS_WALL_MOUNTED
	if layer_name == "cable":
		return IsoDrawEntryContractRef.LAYER_BIAS_CABLE
	if layer_name == "terminal":
		return IsoDrawEntryContractRef.LAYER_BIAS_TERMINAL
	return IsoDrawEntryContractRef.LAYER_BIAS_ITEM

static func make_draw_entry(cell: Vector2i, layer_name: String, object_index: float, payload: Dictionary, depth_key: float, is_routing_utility: bool = false) -> Dictionary:
	var profile_key: String = str(payload.get("profile_key", ""))
	var stable_order_step: float = 0.00001 if layer_name == "wall_mounted" else 0.01
	var sub_order: float = get_sub_order(layer_name, profile_key) + object_index * stable_order_step
	if layer_name == "wall_mounted":
		sub_order += float(get_wall_mounted_render_layer(Dictionary(payload.get("object_data", {})), is_routing_utility)) * 0.001
	return IsoDrawEntryContractRef.make_entry(
		cell,
		layer_name,
		get_entry_kind(layer_name, profile_key),
		depth_key,
		sub_order,
		payload,
		get_layer_bias(layer_name) + object_index * 0.01
	)

static func get_safe_visual_scale(object_data: Dictionary, rule: Dictionary, min_scale: float, max_scale: float, is_png_asset: bool) -> float:
	var rule_scale: float = clampf(float(rule.get("scale", 1.0)), min_scale, max_scale)
	if not is_png_asset:
		return rule_scale
	if not bool(object_data.get("allow_custom_visual_scale", false)):
		return rule_scale
	return clampf(float(object_data.get("visual_scale", rule_scale)), min_scale, max_scale)

static func get_surface_context_policy(object_data: Dictionary, rule: Dictionary = {}) -> Dictionary:
	var placement_mode: String = str(object_data.get("placement_mode", object_data.get("install_mode", object_data.get("mount", "")))).to_lower().strip_edges()
	var anchor_value: String = str(object_data.get("anchor", object_data.get("visual_anchor", object_data.get("alignment_anchor", "")))).to_lower().strip_edges()
	var rule_anchor: String = str(rule.get("anchor", "")).to_lower().strip_edges()
	var rule_mount: String = str(rule.get("mount", rule.get("placement_mode", ""))).to_lower().strip_edges()
	var wall_mounted: bool = placement_mode == "wall_mounted" or get_mount_mode(object_data) == "wall" or anchor_value.contains("wall_mount") or rule_anchor.contains("wall_mount") or rule_mount in ["wall", "wall_mounted"]
	return {
		"wall_mounted": wall_mounted,
		"has_explicit_surface_y_offset": object_data.has("explicit_surface_y_offset"),
		"explicit_surface_y_offset": float(object_data.get("explicit_surface_y_offset", 0.0)),
		"uses_platform_offset": object_data.has("platform_level") or object_data.has("current_level") or object_data.has("visual_level") or object_data.has("platform_height_level"),
		"ground_surface_y_offset": float(object_data.get("ground_surface_y_offset", 0.0))
	}

static func build_object_descriptor(context: Dictionary) -> Dictionary:
	var expected_size: Vector2 = Vector2(context.get("expected_size", Vector2.ZERO))
	var visual_scale: float = float(context.get("visual_scale", 1.0))
	var destination_size: Vector2 = expected_size * visual_scale
	var visual_pivot: Vector2 = Vector2(context.get("visual_pivot", Vector2.ZERO))
	var surface_level: int = int(context.get("surface_level", 0))
	var surface_context: Dictionary = Dictionary(context.get("surface_context", {}))
	var surface_y_offset: float = float(context.get("surface_y_offset", 0.0))
	var explicit_visual_offset: Vector2 = Vector2(context.get("explicit_visual_offset", Vector2.ZERO))
	var configured_offset: Vector2 = Vector2(context.get("rule_offset", Vector2.ZERO)) + explicit_visual_offset
	var wall_mounted: bool = bool(context.get("wall_mounted", false))
	if wall_mounted:
		configured_offset = explicit_visual_offset
	var visual_center: Vector2 = Vector2(context.get("visual_center", Vector2.ZERO))
	var final_draw_position: Vector2 = visual_center + Vector2(0.0, surface_y_offset) - visual_pivot + configured_offset
	var destination_rect: Rect2 = Rect2(final_draw_position, destination_size)
	var source_size: Vector2 = Vector2(context.get("source_size", expected_size))
	return {
		"visual_asset_key": str(context.get("visual_asset_key", "")),
		"texture": context.get("texture", null),
		"render_contract": str(context.get("render_contract", "")),
		"visual_scale": visual_scale,
		"visual_pivot": visual_pivot,
		"surface_level": surface_level,
		"surface_context": surface_context,
		"surface_y_offset": surface_y_offset,
		"final_draw_position": final_draw_position,
		"destination_rect": destination_rect,
		"source_rect": Rect2(Vector2.ZERO, source_size),
		"mirror_h": bool(context.get("mirror_h", false))
	}

static func build_authored_canvas_descriptor(context: Dictionary) -> Dictionary:
	var texture_size: Vector2 = Vector2(context.get("texture_size", Vector2.ZERO))
	var tile_size: Vector2 = Vector2(context.get("tile_size", Vector2.ZERO))
	var safe_source_width: float = maxf(1.0, float(context.get("source_width", 1.0)))
	var visual_scale: float = tile_size.x / safe_source_width
	var destination_size: Vector2 = texture_size * visual_scale
	var visual_pivot: Vector2 = destination_size * Vector2(context.get("anchor_ratio", Vector2(0.5, 1.0)))
	var visual_center: Vector2 = Vector2(context.get("visual_center", Vector2.ZERO))
	var explicit_visual_offset: Vector2 = Vector2(context.get("explicit_visual_offset", Vector2.ZERO))
	var final_draw_position: Vector2 = visual_center - visual_pivot + explicit_visual_offset
	return {
		"visual_asset_key": str(context.get("visual_asset_key", "")),
		"texture": context.get("texture", null),
		"texture_path": str(context.get("texture_path", "")),
		"render_contract": str(context.get("render_contract", "")),
		"visual_scale": visual_scale,
		"visual_pivot": visual_pivot,
		"surface_level": int(context.get("surface_level", 0)),
		"surface_context": {},
		"surface_y_offset": 0.0,
		"final_draw_position": final_draw_position,
		"destination_rect": Rect2(final_draw_position, destination_size),
		"source_rect": Rect2(Vector2.ZERO, texture_size),
		"mirror_h": bool(context.get("mirror_h", false))
	}

static func build_descriptor_for_contract(context: Dictionary) -> Dictionary:
	if str(context.get("descriptor_mode", "object")) == "authored_canvas":
		return build_authored_canvas_descriptor(context)
	return build_object_descriptor(context)
