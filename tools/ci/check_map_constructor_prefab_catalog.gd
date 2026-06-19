extends SceneTree

const Catalog = preload("res://scripts/game/map_constructor_prefab_catalog.gd")
const MissionManager = preload("res://scripts/game/mission_manager.gd")
const WorldObjectCatalog = preload("res://scripts/world/world_object_catalog.gd")

const EXPECTED_IDS: Array[String] = [
	"power_cable_reel", "power_source", "power_cable", "power_socket", "fuse_box", "power_switcher", "light", "light_switcher",
	"radiator", "external_water_pipe", "external_air_duct", "metal_cooling_block", "crate", "barrel", "wall", "floor", "platform", "station",
	"digital_item", "access_item", "physical_item", "module_item", "turret", "enemy", "bipob", "terminal", "door", "firewall", "debris", "case"
]

const EXPECTED_CATEGORY_ORDER: Array[String] = ["Recent", "Power", "Cooling system", "Movable", "Environments", "Item", "Traps", "Robots", "Control", "Other"]

const EXPECTED_CATEGORIES: Dictionary = {
	"power_cable_reel":"Power", "power_source":"Power", "power_cable":"Power", "power_socket":"Power", "fuse_box":"Power", "power_switcher":"Power", "light":"Power", "light_switcher":"Power",
	"radiator":"Cooling system", "external_water_pipe":"Cooling system", "external_air_duct":"Cooling system", "metal_cooling_block":"Cooling system",
	"crate":"Movable", "barrel":"Movable", "wall":"Environments", "floor":"Environments", "platform":"Environments", "station":"Environments",
	"digital_item":"Item", "access_item":"Item", "physical_item":"Item", "module_item":"Item", "turret":"Traps", "enemy":"Robots", "bipob":"Robots",
	"terminal":"Control", "door":"Control", "firewall":"Control", "debris":"Other", "case":"Other"
}

const EXPECTED_LABELS: Dictionary = {
	"power_cable_reel":"Cable Reel", "power_source":"Power Source", "power_cable":"Power Cable", "power_socket":"Power Socket", "fuse_box":"Fuse Box", "power_switcher":"Power Switcher", "light":"Light", "light_switcher":"Light Switcher",
	"radiator":"Radiator", "external_water_pipe":"External Water Pipe", "external_air_duct":"External Air Duct", "metal_cooling_block":"Cooling block",
	"crate":"Crate", "barrel":"Barrel", "wall":"Wall", "floor":"Floor", "platform":"Platform", "station":"Station", "digital_item":"Digital Item", "access_item":"Access Item", "physical_item":"Physical Item", "module_item":"Module Item",
	"turret":"Turret", "enemy":"Enemy", "bipob":"Bipob", "terminal":"Terminal", "door":"Door", "firewall":"Firewall Node", "debris":"Debris", "case":"Case"
}

const REQUIRED_ALIASES: Dictionary = {
	"light_switch":"power_switcher", "circuit_breaker":"power_switcher", "fuse_box_installed":"fuse_box", "fuse_box_empty":"fuse_box",
	"module_internal":"module_item", "module_external":"module_item", "concrete_floor":"floor", "breachable_wall":"wall"
}

var failures: Array[String] = []

func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _initialize() -> void:
	var rows: Array[Dictionary] = Catalog.get_catalog_entries()
	var ids: Array[String] = []
	for row in rows:
		var id := str(row.get("id", ""))
		ids.append(id)
		_assert(not bool(row.get("presentation_missing", false)), "visible prefab missing presentation: %s" % id)
		_assert(str(row.get("display_name", "")) == str(EXPECTED_LABELS.get(id, "")), "display label mismatch for %s" % id)
		_assert(str(row.get("label", "")) == str(row.get("display_name", "")), "compat label mismatch for %s" % id)
		_assert(str(row.get("category", "")) == str(EXPECTED_CATEGORIES.get(id, "")), "category mismatch for %s" % id)
		var contract := WorldObjectCatalog.get_constructor_placement_contract(id)
		_assert(not contract.is_empty(), "missing placement contract for %s" % id)
		_assert(str(row.get("canonical_prefab_id", "")) == str(contract.get("canonical_prefab_id", "")), "canonical mismatch for %s" % id)
		_assert(str(row.get("prefab_id", "")) == id and str(row.get("requested_prefab_id", "")) == id, "requested id not preserved for %s" % id)
		for field in ["default_placement_mode", "default_placement_surface", "supports_floor", "supports_wall", "floor_only", "wall_only", "requires_floor", "requires_wall", "requires_floor_anchor", "requires_floor_anchor_when_wall_mounted", "changes_passability", "blocks_movement"]:
			_assert(row.get(field) == contract.get(field), "%s mismatch for %s" % [field, id])
		_assert(Array(row.get("placement_surfaces", [])) == Array(contract.get("placement_surfaces", [])), "surfaces mismatch for %s" % id)
		if bool(row.get("configurable", false)):
			var schema := WorldObjectCatalog.get_archetype_property_schema(str(row.get("canonical_prefab_id", id)))
			_assert(not schema.is_empty(), "configurable prefab exposes no editable canonical schema: %s" % id)
	_assert(ids == EXPECTED_IDS, "visible prefab sequence changed: %s" % str(ids))
	_assert(Catalog.get_category_order() == EXPECTED_CATEGORY_ORDER, "category order contract changed: %s" % str(Catalog.get_category_order()))
	for hidden_alias in REQUIRED_ALIASES.keys():
		_assert(not ids.has(str(hidden_alias)), "hidden alias exposed: %s" % hidden_alias)
		var alias_meta := Catalog.normalize_presentation_row(Catalog.get_prefab_presentation(str(hidden_alias)))
		_assert(not alias_meta.is_empty(), "alias presentation missing: %s" % hidden_alias)
		_assert(str(alias_meta.get("prefab_id", "")) == str(hidden_alias), "alias requested id lost: %s" % hidden_alias)
		_assert(str(alias_meta.get("requested_prefab_id", "")) == str(hidden_alias), "alias requested_prefab_id lost: %s" % hidden_alias)
		_assert(str(alias_meta.get("canonical_prefab_id", "")) == str(REQUIRED_ALIASES[hidden_alias]), "alias canonical mismatch: %s" % hidden_alias)
	var unknown := Catalog.normalize_presentation_row({"id":"unknown_prefab", "display_name":"Unknown", "supports_floor":true, "placement_mode":"object"})
	_assert(not bool(unknown.get("placement_contract_valid", true)), "unknown contract should fail closed")
	_assert(not bool(unknown.get("supports_floor", true)), "unknown emitted fallback floor support")
	var override_row := Catalog.normalize_presentation_row({"id":"door", "supports_wall":not bool(WorldObjectCatalog.get_constructor_placement_contract("door").get("supports_wall", false))})
	_assert(bool(override_row.get("supports_wall", false)) == bool(WorldObjectCatalog.get_constructor_placement_contract("door").get("supports_wall", false)), "presentation overrode gameplay contract")
	var manager := MissionManager.new()
	var api_rows := manager.get_map_constructor_prefab_palette_rows({})
	_assert(bool(api_rows.get("ok", false)), "MissionManager palette API failed")
	_assert(Array(api_rows.get("categories", [])) == ["Power", "Cooling system", "Movable", "Environments", "Item", "Traps", "Robots", "Control", "Other"], "MissionManager category order changed")
	var alias_result := manager.get_map_constructor_prefab_metadata("fuse_box_installed")
	_assert(bool(alias_result.get("ok", false)), "MissionManager alias metadata failed")
	_assert(str(Dictionary(alias_result.get("prefab", {})).get("prefab_id", "")) == "fuse_box_installed", "MissionManager alias requested ID lost")
	if failures.is_empty():
		print("Map constructor prefab catalog checks passed.")
		quit(0)
	for failure in failures:
		push_error(failure)
	quit(1)
