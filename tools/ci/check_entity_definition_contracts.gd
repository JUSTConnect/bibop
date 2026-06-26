extends SceneTree

const Catalog = preload("res://scripts/game/map_constructor_prefab_catalog.gd")
const WorldObjectCatalog = preload("res://scripts/world/world_object_catalog.gd")
const Contract = preload("res://scripts/world/entity_definition_contract.gd")

var failures: Array[String] = []
func _assert(ok: bool, msg: String) -> void:
	if not ok: failures.append(msg)
func _has_error(report: Dictionary, code: String) -> bool:
	for error in Array(report.get("errors", [])):
		if error is Dictionary and str(error.get("code", "")) == code: return true
	return false
func _initialize() -> void:
	var rows := Catalog.get_catalog_entries()
	var ids: Array[String] = []
	var types := {}
	for row in rows:
		var id := str(row.get("id", "")); ids.append(id)
		_assert(bool(row.get("entity_contract_valid", false)), "visible row invalid: %s" % id)
		var report := WorldObjectCatalog.validate_entity_definition_contract(id)
		_assert(bool(report.get("valid", false)), "contract invalid: %s" % id)
		if str(report.get("scope", "")) == Contract.SCOPE_ENTITY:
			types[str(report.get("entity_type", ""))] = true
			for key in Contract.CAPABILITY_KEYS:
				_assert(Dictionary(report.get("capabilities", {})).has(key), "missing capability %s for %s" % [key, id])
				_assert(Dictionary(report.get("capabilities", {})).get(key) is bool, "non-bool capability %s for %s" % [key, id])
			var c := Dictionary(report.get("contract", {}))
			for field in Contract.REQUIRED_PROFILE_FIELDS:
				_assert(Array(Contract.PROFILE_REGISTRIES[field]).has(str(c.get(field, ""))), "unknown profile %s for %s" % [field, id])
			if bool(WorldObjectCatalog.get_constructor_prefab_definition(id).get("configurable", false)):
				_assert(not WorldObjectCatalog.get_constructor_prefab_property_schema(id).is_empty(), "configurable missing schema: %s" % id)
	for t in Contract.ENTITY_TYPES: _assert(types.has(t), "entity type not represented: %s" % t)
	var good := WorldObjectCatalog.get_constructor_prefab_definition("door"); good["entity_contract"] = WorldObjectCatalog.get_entity_definition_contract("door"); good["entity_contract"].erase("notification_profile")
	_assert(_has_error(Contract.validate_definition("door", good), "entity_contract.notification_profile_missing"), "missing notification exact code absent")
	good["entity_contract"] = WorldObjectCatalog.get_entity_definition_contract("door"); good["entity_contract"]["entity_type"] = "weird"
	_assert(_has_error(Contract.validate_definition("door", good), "entity_contract.entity_type_invalid"), "unknown entity type code absent")
	_assert(_has_error(Contract.validate_definition("wall", {"entity_contract":{"scope":"excluded"}}), "entity_contract.exclusion_reason_missing"), "excluded reason code absent")
	_assert(WorldObjectCatalog.get_entity_definition_contract("light_switch") == WorldObjectCatalog.get_entity_definition_contract("power_switcher"), "alias contract mismatch")
	_assert(not Contract.is_palette_eligible(Contract.validate_definition("bad", {})), "incomplete palette eligible")
	_assert(Catalog.get_entity_contract_diagnostics().is_empty(), "current diagnostics should be empty")
	_assert(ids == Catalog.PREFAB_ORDER, "visible palette ids changed")
	var legacy := WorldObjectCatalog.create_world_object("mechanical_door", "legacy_alias_check")
	_assert(not legacy.is_empty(), "legacy alias loading failed")
	if failures.is_empty():
		print("ENTITY_CONTRACT_GATE: OK")
		quit(0)
	for f in failures: printerr("ENTITY_CONTRACT_GATE: FAIL: %s" % f)
	quit(1)
