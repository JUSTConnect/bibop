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

const EXPECTED_CONFIGURABLE: Dictionary = {
	"power_cable_reel":true, "power_source":false, "power_cable":false, "power_socket":true, "fuse_box":true, "power_switcher":true, "light":true, "light_switcher":true,
	"radiator":false, "external_water_pipe":true, "external_air_duct":true, "metal_cooling_block":false, "crate":true, "barrel":true, "wall":true, "floor":true, "platform":true, "station":true,
	"digital_item":true, "access_item":true, "physical_item":true, "module_item":true, "turret":false, "enemy":true, "bipob":true, "terminal":true, "door":true, "firewall":true, "debris":false, "case":true
}

const EXPECTED_SCHEMA_FIELDS: Dictionary = {
	"door":["door_type", "material", "access_type", "state"],
	"terminal":["terminal_type", "power_type", "control_type", "status"],
	"wall":["material", "is_breachable_wall"],
	"module_item":["module_item_type", "state"],
	"power_switcher":["mount", "switch_state"],
	"fuse_box":["mount", "has_fuse"],
	"power_socket":["mount"]
}

var failures: Array[String] = []

func _checkpoint(label: String) -> void:
	printerr("PREFAB_GATE: %s" % label)

func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _schema_field_names(schema: Array[Dictionary]) -> Array[String]:
	var field_names: Array[String] = []
	for entry in schema:
		var field_name: String = str(entry.get("field", "")).strip_edges()
		if not field_name.is_empty():
			field_names.append(field_name)
	return field_names

func _assert_schema_valid(id: String, schema: Array[Dictionary]) -> void:
	var seen_fields: Dictionary = {}
	for entry in schema:
		_assert(entry is Dictionary, "schema entry is not dictionary for %s" % id)
		var field_name: String = str(entry.get("field", "")).strip_edges()
		_assert(not field_name.is_empty(), "schema field empty for %s" % id)
		_assert(not seen_fields.has(field_name), "schema field duplicated for %s: %s" % [id, field_name])
		seen_fields[field_name] = true

func _initialize() -> void:
	_checkpoint("static_catalog:start")
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
		_assert(contract.has("blocks_movement"), "placement contract missing blocks_movement for %s" % id)
		_assert(str(row.get("canonical_prefab_id", "")) == str(contract.get("canonical_prefab_id", "")), "canonical mismatch for %s" % id)
		_assert(str(row.get("prefab_id", "")) == id and str(row.get("requested_prefab_id", "")) == id, "requested id not preserved for %s" % id)
		for field in ["default_placement_mode", "default_placement_surface", "supports_floor", "supports_wall", "floor_only", "wall_only", "requires_floor", "requires_wall", "requires_floor_anchor", "requires_floor_anchor_when_wall_mounted", "changes_passability", "blocks_movement"]:
			_assert(row.get(field) == contract.get(field), "%s mismatch for %s" % [field, id])
		_assert(Array(row.get("placement_surfaces", [])) == Array(contract.get("placement_surfaces", [])), "surfaces mismatch for %s" % id)
		_assert(row.has("configurable"), "row missing configurable for %s" % id)
		_assert(bool(row.get("configurable", false)) == bool(EXPECTED_CONFIGURABLE.get(id, false)), "configurable fixture mismatch for %s" % id)
		var definition: Dictionary = WorldObjectCatalog.get_constructor_prefab_definition(str(row.get("canonical_prefab_id", id)))
		_assert(bool(row.get("configurable", false)) == bool(definition.get("configurable", false)), "configurable canonical mismatch for %s" % id)
		var schema: Array[Dictionary] = WorldObjectCatalog.get_constructor_prefab_property_schema(str(row.get("canonical_prefab_id", id)))
		_assert(Array(row.get("property_schema", [])) == schema, "property schema mismatch for %s" % id)
		_assert_schema_valid(id, schema)
		if bool(row.get("configurable", false)):
			_assert(not schema.is_empty(), "configurable prefab exposes no editable canonical schema: %s" % id)
		if EXPECTED_SCHEMA_FIELDS.has(id):
			var field_names: Array[String] = _schema_field_names(schema)
			for expected_field in Array(EXPECTED_SCHEMA_FIELDS[id]):
				_assert(field_names.has(str(expected_field)), "%s schema missing %s" % [id, expected_field])
	_assert(ids == EXPECTED_IDS, "visible prefab sequence changed: %s" % str(ids))
	_assert(Catalog.get_category_order() == EXPECTED_CATEGORY_ORDER, "category order contract changed: %s" % str(Catalog.get_category_order()))
	for hidden_alias in REQUIRED_ALIASES.keys():
		_assert(not ids.has(str(hidden_alias)), "hidden alias exposed: %s" % hidden_alias)
		var alias_meta := Catalog.normalize_presentation_row(Catalog.get_prefab_presentation(str(hidden_alias)))
		_assert(not alias_meta.is_empty(), "alias presentation missing: %s" % hidden_alias)
		_assert(str(alias_meta.get("prefab_id", "")) == str(hidden_alias), "alias requested id lost: %s" % hidden_alias)
		_assert(str(alias_meta.get("requested_prefab_id", "")) == str(hidden_alias), "alias requested_prefab_id lost: %s" % hidden_alias)
		var alias_canonical_id := str(REQUIRED_ALIASES[hidden_alias])
		_assert(str(alias_meta.get("canonical_prefab_id", "")) == alias_canonical_id, "alias canonical mismatch: %s" % hidden_alias)
		_assert(not str(alias_meta.get("label", "")).is_empty(), "alias label missing: %s" % hidden_alias)
		var alias_definition: Dictionary = \
			WorldObjectCatalog.get_constructor_prefab_definition(
				alias_canonical_id
			)
		_assert(
			bool(alias_meta.get("configurable", false)) ==
				bool(alias_definition.get("configurable", false)),
			"alias configurable not canonical: %s" % hidden_alias
		)
		if bool(alias_meta.get("configurable", false)):
			var alias_schema: Array[Dictionary] = \
				WorldObjectCatalog.get_constructor_prefab_property_schema(
					alias_canonical_id
				)
			_assert(
				not alias_schema.is_empty(),
				"alias canonical schema missing: %s" % hidden_alias
			)
			_assert(
				Array(alias_meta.get("property_schema", [])) ==
					alias_schema,
				"alias row schema differs from canonical schema: %s" %
					hidden_alias
			)
		var alias_contract: Dictionary = WorldObjectCatalog.get_constructor_placement_contract(str(hidden_alias))
		_assert(str(alias_meta.get("default_placement_surface", "")) == str(alias_contract.get("default_placement_surface", "")), "alias placement contract not alias-aware: %s" % hidden_alias)
	var unknown := Catalog.normalize_presentation_row({"id":"unknown_prefab", "display_name":"Unknown", "supports_floor":true, "placement_mode":"object"})
	_assert(not bool(unknown.get("placement_contract_valid", true)), "unknown contract should fail closed")
	_assert(not bool(unknown.get("supports_floor", true)), "unknown emitted fallback floor support")
	var override_row := Catalog.normalize_presentation_row({"id":"door", "supports_wall":not bool(WorldObjectCatalog.get_constructor_placement_contract("door").get("supports_wall", false))})
	_assert(bool(override_row.get("supports_wall", false)) == bool(WorldObjectCatalog.get_constructor_placement_contract("door").get("supports_wall", false)), "presentation overrode gameplay contract")
	var power_socket_meta := Catalog.normalize_presentation_row(Catalog.get_prefab_presentation("power_socket"))
	_assert(bool(power_socket_meta.get("configurable", false)), "power_socket lost configurable=true")
	var power_socket_schema: Array[Dictionary] = WorldObjectCatalog.get_constructor_prefab_property_schema("power_socket")
	_assert(not power_socket_schema.is_empty(), "power_socket constructor schema missing")
	_assert(_schema_field_names(power_socket_schema).has("mount"), "power_socket schema missing mount")
	_checkpoint("static_catalog:done")
	_checkpoint("manager_new:start")
	var manager := MissionManager.new()
	_checkpoint("manager_new:done")
	_checkpoint("manager_catalog:start")
	var manager_catalog_rows: Array[Dictionary] = manager.get_map_constructor_prefab_catalog()
	var manager_power_socket: Dictionary = {}
	for manager_row in manager_catalog_rows:
		if str(manager_row.get("id", "")) == "power_socket":
			manager_power_socket = manager_row
			break
	_assert(not manager_power_socket.is_empty(), "MissionManager catalog missing power_socket")
	_assert(bool(manager_power_socket.get("configurable", false)), "MissionManager power_socket lost configurable=true")
	var manager_power_socket_schema: Array[Dictionary] = []
	for entry_variant in Array(manager_power_socket.get("property_schema", [])):
		if entry_variant is Dictionary:
			manager_power_socket_schema.append(Dictionary(entry_variant))
	_assert(_schema_field_names(manager_power_socket_schema).has("mount"), "MissionManager power_socket schema missing mount")
	var power_socket_contract: Dictionary = WorldObjectCatalog.get_constructor_placement_contract("power_socket")
	for field in ["default_placement_mode", "default_placement_surface", "supports_floor", "supports_wall", "changes_passability", "blocks_movement"]:
		_assert(manager_power_socket.get(field) == power_socket_contract.get(field), "MissionManager power_socket %s mismatch" % field)
	var public_catalog: Array[Dictionary] = manager.get_map_constructor_prefab_catalog()
	_assert(public_catalog.size() == EXPECTED_IDS.size(), "MissionManager catalog size changed")
	var first_public_row: Dictionary = public_catalog[0]
	_assert(first_public_row.has("configurable"), "MissionManager catalog row lost configurable")
	_checkpoint("manager_catalog:done")
	_checkpoint("manager_palette:start")
	var api_rows := manager.get_map_constructor_prefab_palette_rows({})
	_assert(bool(api_rows.get("ok", false)), "MissionManager palette API failed")
	_assert(Array(api_rows.get("categories", [])) == ["Power", "Cooling system", "Movable", "Environments", "Item", "Traps", "Robots", "Control", "Other"], "MissionManager category order changed")
	_checkpoint("manager_palette:done")
	_checkpoint("manager_metadata:start")
	var alias_result := manager.get_map_constructor_prefab_metadata("fuse_box_installed")
	_assert(bool(alias_result.get("ok", false)), "MissionManager alias metadata failed")
	var alias_prefab: Dictionary = Dictionary(alias_result.get("prefab", {}))
	_assert(str(alias_prefab.get("prefab_id", "")) == "fuse_box_installed", "MissionManager alias requested ID lost")
	_assert(bool(alias_prefab.get("configurable", false)) == bool(WorldObjectCatalog.get_constructor_prefab_definition("fuse_box").get("configurable", false)), "MissionManager alias configurable not canonical")
	_checkpoint("manager_metadata:done")
	_checkpoint("manager_free:start")
	manager.free()
	_checkpoint("manager_free:done")
	manager = null
	if failures.is_empty():
		print("Map constructor prefab catalog checks passed.")
		_checkpoint("quit")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	_checkpoint("quit")
	quit(1)
