extends RefCounted
class_name VersionedSnapshotMigrationService

const WorldObjectCatalogRef = preload("res://scripts/world/world_object_catalog.gd")
const BindingStoreContractRef = preload("res://scripts/world/world_binding_store_contract.gd")
const DetailsCurrencyServiceRef = preload("res://scripts/game/inventory/details_currency_service.gd")
const PowerCableReelServiceRef = preload("res://scripts/game/power_cable_reel_service.gd")
const PassiveRouteServiceRef = preload("res://scripts/game/routing/passive_route_service.gd")
const MovableActionServiceRef = preload("res://scripts/game/movable/movable_action_service.gd")

const CURRENT_FORMAT_VERSION: int = 2
const MIN_SUPPORTED_FORMAT_VERSION: int = 0

const CODE_VALID := "valid"
const CODE_MIGRATED := "migrated"
const CODE_ALREADY_CURRENT := "already_current"
const CODE_UNSUPPORTED_NEWER_VERSION := "unsupported_newer_version"
const CODE_UNSUPPORTED_OLDER_VERSION := "unsupported_older_version"
const CODE_INVALID_DOCUMENT := "invalid_document"
const CODE_ENTITY_NOT_DICTIONARY := "entity_not_dictionary"
const CODE_ENTITY_ID_MISSING := "entity_id_missing"
const CODE_DUPLICATE_ENTITY_ID := "duplicate_entity_id"
const CODE_BINDING_NOT_DICTIONARY := "binding_not_dictionary"
const CODE_BINDING_PHYSICAL_REMOVED := "binding_physical_relation_removed"
const CODE_BINDING_UNSUPPORTED_REMOVED := "binding_unsupported_role_removed"
const CODE_BINDING_DUPLICATE_REMOVED := "binding_duplicate_removed"
const CODE_BINDING_DIAGNOSTIC := "binding_diagnostic"
const CODE_DETAILS_SNAPSHOT_INVALID := "details_snapshot_invalid"
const CODE_LEGACY_FIELD_REMAINING := "legacy_field_remaining"

const SEVERITY_INFO := "info"
const SEVERITY_WARNING := "warning"
const SEVERITY_ERROR := "error"
const SEVERITY_FATAL := "fatal"

const STEP_V0_TO_V1 := "v0_to_v1_envelope_and_bindings"
const STEP_V1_TO_V2 := "v1_to_v2_canonical_entities_and_currency"

const LEGACY_POWER_FIELDS: Array[String] = [
	"main_power_net", "authored_power_source_id", "power_source_id", "physical_connection_source_id"
]
const DERIVED_RUNTIME_FIELDS: Array[String] = [
	"resolved_source_id", "resolved_circuit_id", "power_received", "blocking_reason", "reason_code", "effective_state", "is_operational"
]
const LEGACY_REEL_ALIAS_FIELDS: Array[String] = [
	"end_1_state", "end_1_target_id", "end_2_state", "end_2_target_id", "cable_path_cells"
]
const LEGACY_MACHINE_LOGICAL_FIELDS: Array[String] = [
	"linked_object_ids"
]

static func preview_migration(source_document: Dictionary) -> Dictionary:
	return migrate_document(source_document)

static func migrate_document(source_document: Dictionary) -> Dictionary:
	var source: Dictionary = source_document.duplicate(true)
	var source_version: int = int(source.get("format_version", 0))
	var issues: Array[Dictionary] = []
	var steps: Array[String] = []
	if source_version > CURRENT_FORMAT_VERSION:
		issues.append(_issue(CODE_UNSUPPORTED_NEWER_VERSION, SEVERITY_FATAL, "Snapshot format is newer than this runtime.", "format_version", {"actual":source_version, "supported_max":CURRENT_FORMAT_VERSION}))
		return _result(false, CODE_UNSUPPORTED_NEWER_VERSION, source_version, source, steps, issues)
	if source_version < MIN_SUPPORTED_FORMAT_VERSION:
		issues.append(_issue(CODE_UNSUPPORTED_OLDER_VERSION, SEVERITY_FATAL, "Snapshot format is older than the supported migration range.", "format_version", {"actual":source_version, "supported_min":MIN_SUPPORTED_FORMAT_VERSION}))
		return _result(false, CODE_UNSUPPORTED_OLDER_VERSION, source_version, source, steps, issues)
	if source_version == CURRENT_FORMAT_VERSION:
		_validate_current_document(source, issues)
		var current_ok: bool = not _has_fatal(issues)
		return _result(current_ok, CODE_ALREADY_CURRENT if current_ok else CODE_INVALID_DOCUMENT, source_version, source, steps, issues)

	var working: Dictionary = source.duplicate(true)
	if source_version == 0:
		var first_step: Dictionary = _step_v0_to_v1(working, issues)
		if not bool(first_step.get("success", false)):
			return _result(false, CODE_INVALID_DOCUMENT, source_version, source, steps, issues)
		working = Dictionary(first_step.get("snapshot", {})).duplicate(true)
		steps.append(STEP_V0_TO_V1)
	var second_step: Dictionary = _step_v1_to_v2(working, issues)
	if not bool(second_step.get("success", false)):
		return _result(false, CODE_INVALID_DOCUMENT, source_version, source, steps, issues)
	working = Dictionary(second_step.get("snapshot", {})).duplicate(true)
	steps.append(STEP_V1_TO_V2)
	_validate_current_document(working, issues)
	var success: bool = not _has_fatal(issues)
	return _result(success, CODE_MIGRATED if success else CODE_INVALID_DOCUMENT, source_version, working if success else source, steps, issues)

static func _step_v0_to_v1(source: Dictionary, issues: Array[Dictionary]) -> Dictionary:
	var snapshot: Dictionary = source.duplicate(true)
	var entities_result: Dictionary = _read_entities(snapshot, issues)
	var bindings_result: Dictionary = _read_bindings(snapshot, issues)
	if not bool(entities_result.get("success", false)) or not bool(bindings_result.get("success", false)):
		return {"success":false, "snapshot":snapshot}
	snapshot["format_version"] = 1
	snapshot["entities"] = Array(entities_result.get("entities", [])).duplicate(true)
	snapshot["bindings"] = Array(bindings_result.get("bindings", [])).duplicate(true)
	snapshot.erase("objects")
	return {"success":true, "snapshot":snapshot}

static func _step_v1_to_v2(source: Dictionary, issues: Array[Dictionary]) -> Dictionary:
	var snapshot: Dictionary = source.duplicate(true)
	var entities_result: Dictionary = _read_entities(snapshot, issues)
	if not bool(entities_result.get("success", false)):
		return {"success":false, "snapshot":snapshot}
	var raw_entities: Array[Dictionary] = Array(entities_result.get("entities", [])).duplicate(true)
	raw_entities = DetailsCurrencyServiceRef.migrate_world_pickups(raw_entities)
	var canonical_entities: Array[Dictionary] = []
	var entities_by_id: Dictionary = {}
	for index in range(raw_entities.size()):
		var raw_entity: Dictionary = raw_entities[index].duplicate(true)
		var entity_id: String = str(raw_entity.get("id", raw_entity.get("object_id", ""))).strip_edges()
		if entity_id.is_empty():
			issues.append(_issue(CODE_ENTITY_ID_MISSING, SEVERITY_FATAL, "Entity has no stable id.", "entities[%d]" % index))
			continue
		if entities_by_id.has(entity_id):
			issues.append(_issue(CODE_DUPLICATE_ENTITY_ID, SEVERITY_FATAL, "Duplicate entity id.", "entities[%d].id" % index, {"entity_id":entity_id}))
			continue
		raw_entity["id"] = entity_id
		var canonical: Dictionary = _canonicalize_entity(raw_entity)
		canonical_entities.append(canonical)
		entities_by_id[entity_id] = canonical
	if _has_fatal(issues):
		return {"success":false, "snapshot":snapshot}

	var binding_result: Dictionary = _migrate_bindings(snapshot, raw_entities, entities_by_id, issues)
	if not bool(binding_result.get("success", false)):
		return {"success":false, "snapshot":snapshot}
	var stripped_entities: Array[Dictionary] = []
	for entity in canonical_entities:
		var stripped_entity: Dictionary = BindingStoreContractRef.strip_legacy_logical_links(entity)
		stripped_entity = _strip_machine_logical_links(stripped_entity)
		stripped_entities.append(stripped_entity)
	var currency_result: Dictionary = _migrate_currency(snapshot, issues)
	if not bool(currency_result.get("success", false)):
		return {"success":false, "snapshot":snapshot}

	snapshot["format_version"] = CURRENT_FORMAT_VERSION
	snapshot["entities"] = stripped_entities
	snapshot["bindings"] = Array(binding_result.get("bindings", [])).duplicate(true)
	snapshot["inventory_state"] = Dictionary(currency_result.get("inventory_state", {})).duplicate(true)
	snapshot["center_storage"] = Dictionary(currency_result.get("center_storage", {})).duplicate(true)
	snapshot["details_currency"] = Dictionary(currency_result.get("details_currency", {})).duplicate(true)
	snapshot.erase("objects")
	snapshot.erase("runtime_inventory_state")
	return {"success":true, "snapshot":snapshot}

static func _read_entities(snapshot: Dictionary, issues: Array[Dictionary]) -> Dictionary:
	var raw: Variant = snapshot.get("entities", snapshot.get("objects", []))
	if not raw is Array:
		issues.append(_issue(CODE_INVALID_DOCUMENT, SEVERITY_FATAL, "Snapshot entities field must be an array.", "entities"))
		return {"success":false, "entities":[]}
	var entities: Array[Dictionary] = []
	for index in range(Array(raw).size()):
		var row: Variant = Array(raw)[index]
		if not row is Dictionary:
			issues.append(_issue(CODE_ENTITY_NOT_DICTIONARY, SEVERITY_FATAL, "Entity row must be a dictionary.", "entities[%d]" % index))
			continue
		entities.append(Dictionary(row).duplicate(true))
	return {"success":not _has_fatal(issues), "entities":entities}

static func _read_bindings(snapshot: Dictionary, issues: Array[Dictionary]) -> Dictionary:
	var raw: Variant = snapshot.get("bindings", [])
	if not raw is Array:
		issues.append(_issue(CODE_INVALID_DOCUMENT, SEVERITY_FATAL, "Snapshot bindings field must be an array.", "bindings"))
		return {"success":false, "bindings":[]}
	var bindings: Array[Dictionary] = []
	for index in range(Array(raw).size()):
		var row: Variant = Array(raw)[index]
		if not row is Dictionary:
			issues.append(_issue(CODE_BINDING_NOT_DICTIONARY, SEVERITY_FATAL, "Binding row must be a dictionary.", "bindings[%d]" % index))
			continue
		bindings.append(Dictionary(row).duplicate(true))
	return {"success":not _has_fatal(issues), "bindings":bindings}

static func _canonicalize_entity(source: Dictionary) -> Dictionary:
	var entity: Dictionary = WorldObjectCatalogRef.normalize_world_object_contract(source)
	var object_type: String = str(entity.get("object_type", entity.get("type", ""))).strip_edges().to_lower()
	if object_type == "power_cable_reel":
		entity = PowerCableReelServiceRef.migrate_legacy_reel(entity)
		for field_name in LEGACY_REEL_ALIAS_FIELDS:
			entity.erase(field_name)
	if PassiveRouteServiceRef.is_passive_route(entity):
		entity = PassiveRouteServiceRef.normalize_segment(entity)
	if MovableActionServiceRef.is_movable_entity(entity) or MovableActionServiceRef.is_crate(entity):
		entity = MovableActionServiceRef.normalize_movable_contract(entity)
	for field_name in LEGACY_POWER_FIELDS:
		entity.erase(field_name)
	for field_name in DERIVED_RUNTIME_FIELDS:
		entity.erase(field_name)
	entity = _strip_machine_logical_links(entity)
	return _attach_contract(entity)

static func _strip_machine_logical_links(source: Dictionary) -> Dictionary:
	var entity: Dictionary = source.duplicate(true)
	for field_name in LEGACY_MACHINE_LOGICAL_FIELDS:
		entity.erase(field_name)
	return entity

static func _attach_contract(source: Dictionary) -> Dictionary:
	var entity: Dictionary = source.duplicate(true)
	var definition_id: String = str(entity.get("map_constructor_prefab_id", entity.get("archetype_id", entity.get("object_type", "")))).strip_edges().to_lower()
	if definition_id.is_empty():
		return entity
	var contract: Dictionary = WorldObjectCatalogRef.get_entity_definition_contract(definition_id)
	if contract.is_empty():
		return entity
	entity["entity_contract"] = contract.duplicate(true)
	entity["entity_contract_id"] = definition_id
	entity["entity_contract_scope"] = str(contract.get("scope", ""))
	entity["entity_type"] = str(contract.get("entity_type", ""))
	entity["entity_subtype"] = str(contract.get("entity_subtype", ""))
	return entity

static func _migrate_bindings(snapshot: Dictionary, entities: Array[Dictionary], entities_by_id: Dictionary, issues: Array[Dictionary]) -> Dictionary:
	var raw_result: Dictionary = _read_bindings(snapshot, issues)
	if not bool(raw_result.get("success", false)):
		return {"success":false, "bindings":[]}
	var by_relation: Dictionary = {}
	var explicit: Array[Dictionary] = Array(raw_result.get("bindings", [])).duplicate(true)
	explicit.sort_custom(_binding_id_less)
	for index in range(explicit.size()):
		var raw_binding: Dictionary = explicit[index]
		var binding: Dictionary = BindingStoreContractRef.canonicalize_record(raw_binding)
		var role: String = str(binding.get("role", ""))
		if BindingStoreContractRef.PHYSICAL_RELATION_ROLES.has(role):
			issues.append(_issue(CODE_BINDING_PHYSICAL_REMOVED, SEVERITY_WARNING, "Physical relation binding was removed.", "bindings[%d]" % index, {"role":role, "binding_id":str(binding.get("id", ""))}))
			continue
		if not BindingStoreContractRef.ROLE_REGISTRY.has(role):
			issues.append(_issue(CODE_BINDING_UNSUPPORTED_REMOVED, SEVERITY_ERROR, "Unsupported logical role was not guessed.", "bindings[%d]" % index, {"role":role, "binding_id":str(binding.get("id", ""))}))
			continue
		var key: String = _relation_key(binding)
		if by_relation.has(key):
			issues.append(_issue(CODE_BINDING_DUPLICATE_REMOVED, SEVERITY_WARNING, "Duplicate binding relation was removed.", "bindings[%d]" % index, {"binding_id":str(binding.get("id", ""))}))
			continue
		by_relation[key] = binding
	var legacy_by_id: Dictionary = {}
	for entity in entities:
		legacy_by_id[str(entity.get("id", ""))] = entity.duplicate(true)
	for candidate in BindingStoreContractRef.legacy_candidates(legacy_by_id):
		var key: String = _relation_key(candidate)
		if not by_relation.has(key):
			by_relation[key] = BindingStoreContractRef.canonicalize_record(candidate)
	var relation_keys: Array = by_relation.keys()
	relation_keys.sort()
	var bindings: Array[Dictionary] = []
	for key_value in relation_keys:
		bindings.append(Dictionary(by_relation[key_value]).duplicate(true))
	var built: Dictionary = BindingStoreContractRef.build_state(bindings, entities_by_id, true)
	if not bool(built.get("success", false)):
		issues.append(_issue(str(built.get("code", CODE_INVALID_DOCUMENT)), SEVERITY_FATAL, "Canonical binding state could not be built.", "bindings"))
		return {"success":false, "bindings":[]}
	for diagnostic_variant in Array(built.get("diagnostics", [])):
		if diagnostic_variant is Dictionary:
			issues.append(_issue(CODE_BINDING_DIAGNOSTIC, SEVERITY_ERROR, "Binding remains loadable but semantically invalid.", "bindings", {"diagnostic":Dictionary(diagnostic_variant).duplicate(true)}))
	var built_by_id: Dictionary = Dictionary(built.get("bindings_by_id", {}))
	var ids: Array = built_by_id.keys()
	ids.sort()
	bindings.clear()
	for id_value in ids:
		bindings.append(Dictionary(built_by_id[id_value]).duplicate(true))
	return {"success":true, "bindings":bindings}

static func _migrate_currency(snapshot: Dictionary, issues: Array[Dictionary]) -> Dictionary:
	var service = DetailsCurrencyServiceRef.new()
	var existing: Variant = snapshot.get("details_currency", {})
	if not existing is Dictionary:
		issues.append(_issue(CODE_DETAILS_SNAPSHOT_INVALID, SEVERITY_FATAL, "Details snapshot must be a dictionary.", "details_currency"))
		return {"success":false}
	if not Dictionary(existing).is_empty():
		var load_result: Dictionary = service.replace_snapshot(Dictionary(existing))
		if not bool(load_result.get("success", false)):
			issues.append(_issue(CODE_DETAILS_SNAPSHOT_INVALID, SEVERITY_FATAL, "Details snapshot is invalid.", "details_currency"))
			return {"success":false}
	var raw_inventory: Variant = snapshot.get("inventory_state", snapshot.get("runtime_inventory_state", {}))
	var raw_center: Variant = snapshot.get("center_storage", {})
	if not raw_inventory is Dictionary or not raw_center is Dictionary:
		issues.append(_issue(CODE_INVALID_DOCUMENT, SEVERITY_FATAL, "Inventory and center storage must be dictionaries.", "inventory_state"))
		return {"success":false}
	var migration: Dictionary = service.migrate_legacy_parts(Dictionary(raw_inventory), Dictionary(raw_center), "legacy_snapshot_v2")
	if not bool(migration.get("success", false)):
		issues.append(_issue(str(migration.get("code", CODE_INVALID_DOCUMENT)), SEVERITY_FATAL, "Legacy parts could not be migrated.", "inventory_state"))
		return {"success":false}
	return {
		"success":true,
		"inventory_state":Dictionary(migration.get("inventory_state", {})).duplicate(true),
		"center_storage":Dictionary(migration.get("center_storage", {})).duplicate(true),
		"details_currency":service.get_snapshot()
	}

static func _validate_current_document(snapshot: Dictionary, issues: Array[Dictionary]) -> void:
	var entities_result: Dictionary = _read_entities(snapshot, issues)
	if not bool(entities_result.get("success", false)):
		return
	var entities: Array[Dictionary] = Array(entities_result.get("entities", [])).duplicate(true)
	var by_id: Dictionary = {}
	for index in range(entities.size()):
		var entity: Dictionary = entities[index]
		var entity_id: String = str(entity.get("id", "")).strip_edges()
		if entity_id.is_empty():
			issues.append(_issue(CODE_ENTITY_ID_MISSING, SEVERITY_FATAL, "Entity has no stable id.", "entities[%d]" % index))
			continue
		if by_id.has(entity_id):
			issues.append(_issue(CODE_DUPLICATE_ENTITY_ID, SEVERITY_FATAL, "Duplicate entity id.", "entities[%d].id" % index))
			continue
		by_id[entity_id] = entity
		_validate_legacy_fields(entity, index, issues)
	var bindings_result: Dictionary = _read_bindings(snapshot, issues)
	if not bool(bindings_result.get("success", false)):
		return
	var built: Dictionary = BindingStoreContractRef.build_state(Array(bindings_result.get("bindings", [])).duplicate(true), by_id, true)
	if not bool(built.get("success", false)):
		issues.append(_issue(str(built.get("code", CODE_INVALID_DOCUMENT)), SEVERITY_FATAL, "Current bindings are not loadable.", "bindings"))
	for diagnostic_variant in Array(built.get("diagnostics", [])):
		if diagnostic_variant is Dictionary:
			issues.append(_issue(CODE_BINDING_DIAGNOSTIC, SEVERITY_ERROR, "Binding remains loadable but semantically invalid.", "bindings", {"diagnostic":Dictionary(diagnostic_variant).duplicate(true)}))
	var details: Variant = snapshot.get("details_currency", {})
	if not details is Dictionary:
		issues.append(_issue(CODE_DETAILS_SNAPSHOT_INVALID, SEVERITY_FATAL, "Details snapshot must be a dictionary.", "details_currency"))
	elif not Dictionary(details).is_empty():
		var service = DetailsCurrencyServiceRef.new()
		if not bool(service.replace_snapshot(Dictionary(details)).get("success", false)):
			issues.append(_issue(CODE_DETAILS_SNAPSHOT_INVALID, SEVERITY_FATAL, "Details snapshot is invalid.", "details_currency"))

static func _validate_legacy_fields(entity: Dictionary, index: int, issues: Array[Dictionary]) -> void:
	var fields: Array[String] = []
	fields.append_array(BindingStoreContractRef.LEGACY_LOGICAL_LINK_FIELDS)
	fields.append_array(LEGACY_MACHINE_LOGICAL_FIELDS)
	fields.append_array(LEGACY_POWER_FIELDS)
	fields.append_array(LEGACY_REEL_ALIAS_FIELDS)
	if PassiveRouteServiceRef.is_passive_route(entity):
		fields.append_array(["wall_side_1", "wall_side_2", "cooling_contour_id", "cooling_contour_mode", "cooling_contour_member_ids", "connected_device_ids", "test_override_enabled"])
	for field_name in fields:
		if entity.has(field_name):
			issues.append(_issue(CODE_LEGACY_FIELD_REMAINING, SEVERITY_ERROR, "Canonical entity still contains a legacy source-of-truth field.", "entities[%d].%s" % [index, field_name], {"entity_id":str(entity.get("id", "")), "field":field_name}))

static func _relation_key(binding: Dictionary) -> String:
	return "%s|%s|%s" % [str(binding.get("role", "")), str(binding.get("source_id", "")), str(binding.get("target_id", ""))]

static func _binding_id_less(left: Dictionary, right: Dictionary) -> bool:
	return str(left.get("id", "")) < str(right.get("id", ""))

static func _issue(code: String, severity: String, message: String, path: String, details: Dictionary = {}) -> Dictionary:
	return {"code":code, "reason_code":code, "severity":severity, "message":message, "path":path, "details":details.duplicate(true)}

static func _has_fatal(issues: Array[Dictionary]) -> bool:
	for issue in issues:
		if str(issue.get("severity", "")) == SEVERITY_FATAL:
			return true
	return false

static func _has_blocker(issues: Array[Dictionary]) -> bool:
	for issue in issues:
		if str(issue.get("severity", "")) in [SEVERITY_FATAL, SEVERITY_ERROR]:
			return true
	return false

static func _result(success: bool, code: String, source_version: int, snapshot: Dictionary, steps: Array[String], issues: Array[Dictionary]) -> Dictionary:
	return {
		"ok":success,
		"success":success,
		"code":code,
		"reason_code":code,
		"source_format_version":source_version,
		"target_format_version":CURRENT_FORMAT_VERSION,
		"migrated":success and source_version < CURRENT_FORMAT_VERSION,
		"applied_steps":steps.duplicate(),
		"issues":issues.duplicate(true),
		"draft_save_allowed":success,
		"task_test_allowed":success,
		"promotion_allowed":success and not _has_blocker(issues),
		"snapshot":snapshot.duplicate(true)
	}
