extends SceneTree

const Catalog = preload("res://scripts/game/map_constructor_prefab_catalog.gd")
const WorldObjectCatalog = preload("res://scripts/world/world_object_catalog.gd")
const Contract = preload("res://scripts/world/entity_definition_contract.gd")
const MissionManager = preload("res://scripts/game/mission_manager.gd")
const GridManager = preload("res://scripts/field/grid_manager.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _assert(ok: bool, msg: String) -> void:
	if not ok:
		failures.append(msg)

func _has_error(report: Dictionary, code: String) -> bool:
	for error in Array(report.get("errors", [])):
		if error is Dictionary and str(Dictionary(error).get("code", "")) == code:
			return true
	return false

func _make_constructor_manager():
	var manager = MissionManager.new()
	var grid_manager = GridManager.new()
	root.add_child(grid_manager)
	root.add_child(manager)
	manager.grid_manager = grid_manager
	manager.setup_task_test_sandbox_world()
	return manager

func _run() -> void:
	await process_frame
	var rows := Catalog.get_catalog_entries()
	var ids: Array[String] = []
	var types: Dictionary = {}
	for row in rows:
		var id := str(row.get("id", ""))
		ids.append(id)
		_assert(bool(row.get("entity_contract_valid", false)), "visible row invalid: %s" % id)
		var report := WorldObjectCatalog.validate_entity_definition_contract(id)
		_assert(bool(report.get("valid", false)), "contract invalid: %s %s" % [id, str(report.get("errors", []))])
		if str(report.get("scope", "")) == Contract.SCOPE_ENTITY:
			types[str(report.get("entity_type", ""))] = true
			for key in Contract.CAPABILITY_KEYS:
				_assert(Dictionary(report.get("capabilities", {})).has(key), "missing capability %s for %s" % [key, id])
				_assert(Dictionary(report.get("capabilities", {})).get(key) is bool, "non-bool capability %s for %s" % [key, id])
			var contract := Dictionary(report.get("contract", {}))
			for field in Contract.REQUIRED_PROFILE_FIELDS:
				_assert(Array(Contract.PROFILE_REGISTRIES[field]).has(str(contract.get(field, ""))), "unknown profile %s for %s" % [field, id])
			var capability_by_profile := {"power_profile":"power", "control_profile":"control", "access_profile":"access", "binding_profile":"bindings"}
			for profile_field in capability_by_profile.keys():
				var capability_name := str(capability_by_profile[profile_field])
				if str(contract.get(profile_field, "")) == "none":
					_assert(not bool(Dictionary(report.get("capabilities", {})).get(capability_name, false)), "%s has %s capability but %s=none" % [id, capability_name, profile_field])
			if bool(WorldObjectCatalog.get_constructor_prefab_definition(id).get("configurable", false)):
				_assert(not WorldObjectCatalog.get_constructor_prefab_property_schema(id).is_empty(), "configurable missing schema: %s" % id)
	for entity_type in Contract.ENTITY_TYPES:
		_assert(types.has(entity_type), "entity type not represented: %s" % entity_type)
	for archetype_id in WorldObjectCatalog.ARCHETYPE_REGISTRY.keys():
		var archetype_report := WorldObjectCatalog.validate_entity_definition_contract(str(archetype_id))
		_assert(bool(archetype_report.get("valid", false)), "managed archetype contract invalid: %s %s" % [str(archetype_id), str(archetype_report.get("errors", []))])
	var pipe_contract := WorldObjectCatalog.get_entity_definition_contract("external_air_duct")
	var pipe_caps := Dictionary(pipe_contract.get("capabilities", {}))
	_assert(bool(pipe_caps.get("side", false)) and bool(pipe_caps.get("routing", false)) and bool(pipe_caps.get("test_override", false)), "air duct missing passive route capabilities")
	for disabled_key in ["state", "health", "power", "control", "access", "bindings"]:
		_assert(not bool(pipe_caps.get(disabled_key, true)), "air duct has forbidden capability: %s" % disabled_key)
	var synthetic := WorldObjectCatalog.get_constructor_prefab_definition("door")
	var missing_notification_contract := WorldObjectCatalog.get_entity_definition_contract("door")
	missing_notification_contract.erase("notification_profile")
	synthetic["entity_contract"] = missing_notification_contract
	_assert(_has_error(Contract.validate_definition("door", synthetic), "entity_contract.notification_profile_missing"), "missing notification exact code absent")
	var unknown_type_contract := WorldObjectCatalog.get_entity_definition_contract("door")
	unknown_type_contract["entity_type"] = "weird"
	synthetic["entity_contract"] = unknown_type_contract
	_assert(_has_error(Contract.validate_definition("door", synthetic), "entity_contract.entity_type_invalid"), "unknown entity type code absent")
	_assert(_has_error(Contract.validate_definition("wall", {"entity_contract":{"scope":"excluded"}}), "entity_contract.exclusion_reason_missing"), "excluded reason code absent")
	_assert(WorldObjectCatalog.get_entity_definition_contract("light_switch") == WorldObjectCatalog.get_entity_definition_contract("power_switcher"), "alias contract mismatch")
	_assert(not Contract.is_palette_eligible(Contract.validate_definition("bad", {})), "incomplete palette eligible")
	var synthetic_catalog_row := Catalog.normalize_presentation_row({"id":"missing_contract_prefab"})
	_assert(not bool(synthetic_catalog_row.get("entity_contract_valid", true)), "synthetic incomplete row should be invalid")
	_assert(Array(synthetic_catalog_row.get("entity_contract_error_codes", [])).has("entity_contract.missing"), "synthetic incomplete row missing diagnostic code")
	_assert(Catalog.get_entity_contract_diagnostics().is_empty(), "current diagnostics should be empty")
	_assert(ids == Catalog.PREFAB_ORDER, "visible palette ids changed")
	_assert(bool(WorldObjectCatalog.validate_entity_definition_contract("external_wall").get("valid", false)), "external_wall exclusion invalid")
	_assert(not WorldObjectCatalog.create_archetype_object("external_wall", "external_wall_contract_check").is_empty(), "external_wall creation failed")
	_assert(not WorldObjectCatalog.create_world_object("light_switch", "utility_alias_contract_check").is_empty(), "utility alias loading failed")
	var legacy := WorldObjectCatalog.create_world_object("mechanical_door", "legacy_alias_check")
	_assert(not legacy.is_empty(), "legacy alias loading failed")
	var constructor_manager = _make_constructor_manager()
	await process_frame
	var invalid_result: Dictionary = constructor_manager.place_map_constructor_prefab("missing_contract_prefab", Vector2i.ZERO)
	_assert(str(invalid_result.get("reason", "")) == "incomplete_entity_contract", "direct placement did not reject incomplete definition")
	var stepped_result: Dictionary = constructor_manager.place_map_constructor_prefab("stepped_floor", Vector2i(1, 1))
	_assert(bool(stepped_result.get("ok", false)), "stepped_floor placement failed: %s" % str(stepped_result))
	var valid_cell := Vector2i(2, 2)
	constructor_manager.grid_manager.set_tile(valid_cell, GridManager.TILE_FLOOR)
	var valid_result: Dictionary = constructor_manager.place_map_constructor_prefab("case", valid_cell)
	_assert(bool(valid_result.get("ok", false)), "valid prefab placement failed: %s" % str(valid_result))
	constructor_manager.grid_manager.queue_free()
	constructor_manager.queue_free()
	await process_frame
	await process_frame
	if failures.is_empty():
		print("ENTITY_CONTRACT_GATE: OK")
		quit(0)
		return
	for failure in failures:
		printerr("ENTITY_CONTRACT_GATE: FAIL: %s" % failure)
	quit(1)