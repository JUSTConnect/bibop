extends SceneTree

const Catalog = preload("res://scripts/game/map_constructor_prefab_catalog.gd")
const WorldObjectCatalog = preload("res://scripts/world/world_object_catalog.gd")
const Contract = preload("res://scripts/world/entity_definition_contract.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _assert(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func _has_error(report: Dictionary, code: String) -> bool:
	for value in Array(report.get("errors", [])):
		if value is Dictionary and str(Dictionary(value).get("code", "")) == code:
			return true
	return false

func _diagnostic_has(diagnostics: Array[Dictionary], prefab_id: String, code: String) -> bool:
	for diagnostic in diagnostics:
		if str(diagnostic.get("prefab_id", "")) != prefab_id:
			continue
		for value in Array(diagnostic.get("errors", [])):
			if value is Dictionary and str(Dictionary(value).get("code", "")) == code:
				return true
	return false

func _mutated_door_report(profile_field: String, profile_value: String, capability: String, capability_value: bool) -> Dictionary:
	var definition: Dictionary = WorldObjectCatalog.get_constructor_prefab_definition("door")
	var contract: Dictionary = WorldObjectCatalog.get_entity_definition_contract("door")
	var capabilities: Dictionary = Dictionary(contract.get("capabilities", {})).duplicate(true)
	contract[profile_field] = profile_value
	capabilities[capability] = capability_value
	contract["capabilities"] = capabilities
	definition["entity_contract"] = contract
	return Contract.validate_definition("door", definition)

func _run() -> void:
	await process_frame
	_assert(_has_error(_mutated_door_report("power_profile", "none", "power", true), "entity_contract.power_capability_profile_mismatch"), "enabled power with none profile was accepted")
	_assert(_has_error(_mutated_door_report("power_profile", "configurable", "power", false), "entity_contract.power_capability_profile_mismatch"), "disabled power with active profile was accepted")
	_assert(_has_error(_mutated_door_report("status_profile", "none", "state", true), "entity_contract.state_status_profile_mismatch"), "state with none status profile was accepted")

	_assert(not Contract.resolve_validation_fixture("default").is_empty(), "default validation fixture did not resolve")
	var definition: Dictionary = WorldObjectCatalog.get_constructor_prefab_definition("door")
	var contract: Dictionary = WorldObjectCatalog.get_entity_definition_contract("door")
	contract["validation_fixture"] = "unknown_fixture"
	definition["entity_contract"] = contract
	_assert(_has_error(Contract.validate_definition("door", definition), "entity_contract.validation_fixture_unknown"), "unknown validation fixture was accepted")

	var synthetic_order: Array[String] = ["missing_contract_prefab"]
	_assert(Catalog.get_catalog_entries(synthetic_order).is_empty(), "incomplete prefab leaked into palette")
	var diagnostics: Array[Dictionary] = Catalog.get_entity_contract_diagnostics()
	_assert(_diagnostic_has(diagnostics, "missing_contract_prefab", "entity_contract.missing"), "entity-contract diagnostic missing")
	_assert(_diagnostic_has(diagnostics, "missing_contract_prefab", "placement_contract.missing"), "placement-contract diagnostic missing")
	Catalog.get_catalog_entries()
	_assert(Catalog.get_entity_contract_diagnostics().is_empty(), "production catalog diagnostics should be empty")

	await process_frame
	if failures.is_empty():
		print("ENTITY_CONTRACT_CONSISTENCY_GATE: OK")
		quit(0)
		return
	for failure in failures:
		printerr("ENTITY_CONTRACT_CONSISTENCY_GATE: FAIL: %s" % failure)
	quit(1)