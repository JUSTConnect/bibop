extends RefCounted
class_name WorldBindingStoreContract

const FORMAT_VERSION: int = 1
const VALID_CODE := "valid"
const RESULT_CODES: Array[String] = [
	"valid",
	"missing",
	"source_missing",
	"target_missing",
	"wrong_type",
	"inactive",
	"capacity_exceeded",
	"duplicate",
	"cycle",
	"unsupported_role",
	"physical_relation_forbidden",
	"invalid_format_version",
	"binding_cleanup_required"
]

const ROLE_CONTROL_TERMINAL := "control_terminal"
const ROLE_ACCESS_TERMINAL := "access_terminal"
const ROLE_ACCESS_ITEM := "access_item"
const ROLE_PREFERRED_POWER_SOURCE := "preferred_power_source"
const ROLE_LIGHT_CONTROLLER := "light_controller"
const ROLE_PLATFORM_CONTROLLER := "platform_controller"

const ROLE_REGISTRY: Dictionary = {
	ROLE_CONTROL_TERMINAL: {
		"source_groups": ["terminal"],
		"source_types": ["terminal", "information_terminal", "control_terminal"],
		"target_capability": "control",
		"max_per_target": 1,
		"acyclic": true
	},
	ROLE_ACCESS_TERMINAL: {
		"source_groups": ["terminal"],
		"source_types": ["terminal", "information_terminal", "access_terminal"],
		"target_capability": "access",
		"max_per_target": 1,
		"acyclic": true
	},
	ROLE_ACCESS_ITEM: {
		"source_groups": ["item"],
		"source_entity_types": ["item"],
		"target_capability": "access",
		"acyclic": true
	},
	ROLE_PREFERRED_POWER_SOURCE: {
		"source_capability": "power",
		"target_types": ["power_source", "power_source_class_1", "power_source_class_2", "power_source_class_3"],
		"target_roles": ["power_source"],
		"max_per_source": 1,
		"acyclic": true
	},
	ROLE_LIGHT_CONTROLLER: {
		"source_capability": "control",
		"source_groups": ["terminal"],
		"source_types": ["terminal", "information_terminal", "light_switcher", "power_switcher", "light_switch"],
		"target_entity_types": ["light"],
		"target_groups": ["lighting", "light"],
		"target_types": ["light", "wall_light", "light_source"],
		"max_per_target": 1,
		"acyclic": true
	},
	ROLE_PLATFORM_CONTROLLER: {
		"source_capability": "control",
		"source_groups": ["terminal"],
		"source_types": ["terminal", "information_terminal", "platform_controller", "power_switcher"],
		"target_groups": ["platform"],
		"target_types": ["platform", "rotating_platform", "lifting_platform"],
		"max_per_target": 1,
		"acyclic": true
	}
}

const PHYSICAL_RELATION_ROLES: Array[String] = [
	"power_cable",
	"power_cable_segment",
	"runtime_power_feed",
	"power_cable_reel",
	"cable_endpoint",
	"passive_route",
	"duct_adjacency",
	"pipe_adjacency"
]

const PHYSICAL_PARAMETER_FIELDS: Array[String] = [
	"end_1",
	"end_2",
	"path_cells",
	"endpoint_a_id",
	"endpoint_b_id",
	"socket_id",
	"cable_path_cells",
	"route_cells",
	"topology_neighbors"
]

const PHYSICAL_OBJECT_TYPES: Array[String] = [
	"power_cable",
	"power_cable_reel",
	"external_air_duct",
	"external_water_pipe",
	"air_duct",
	"water_pipe"
]

const LEGACY_LOGICAL_LINK_FIELDS: Array[String] = [
	"control_terminal_id",
	"linked_terminal_id",
	"linked_terminal_ids",
	"required_terminal_id",
	"required_key_id",
	"required_digital_key_id",
	"required_access_code_id",
	"preferred_source_id",
	"linked_light_ids",
	"target_light_ids",
	"linked_platform_ids",
	"linked_door_id",
	"linked_door_ids",
	"target_door_id",
	"connected_device_ids"
]

static func make_result(code: String, binding: Dictionary = {}, details: Dictionary = {}, success_override: Variant = null) -> Dictionary:
	var success: bool = code == VALID_CODE
	if success_override is bool:
		success = bool(success_override)
	return {
		"ok": success,
		"success": success,
		"code": code,
		"reason_code": code,
		"binding_id": str(binding.get("id", "")),
		"source_id": str(binding.get("source_id", "")),
		"target_id": str(binding.get("target_id", "")),
		"role": str(binding.get("role", "")),
		"details": details.duplicate(true)
	}

static func canonicalize_record(record: Dictionary) -> Dictionary:
	var parameters: Dictionary = {}
	if record.get("parameters", {}) is Dictionary:
		parameters = Dictionary(record.get("parameters", {})).duplicate(true)
	return {
		"id": str(record.get("id", "")).strip_edges(),
		"role": str(record.get("role", "")).strip_edges().to_lower(),
		"source_id": str(record.get("source_id", "")).strip_edges(),
		"target_id": str(record.get("target_id", "")).strip_edges(),
		"parameters": parameters,
		"format_version": int(record.get("format_version", FORMAT_VERSION))
	}

static func validate_record(record: Dictionary, entities_by_id: Dictionary, bindings_by_id: Dictionary, replacing_binding_id: String = "", allow_missing_entities: bool = false) -> Dictionary:
	var binding: Dictionary = canonicalize_record(record)
	var binding_id: String = str(binding.get("id", ""))
	var role: String = str(binding.get("role", ""))
	var source_id: String = str(binding.get("source_id", ""))
	var target_id: String = str(binding.get("target_id", ""))
	if binding_id.is_empty() or role.is_empty() or source_id.is_empty() or target_id.is_empty():
		return make_result("missing", binding, {"required_fields": ["id", "role", "source_id", "target_id"]})
	if int(binding.get("format_version", 0)) != FORMAT_VERSION:
		return make_result("invalid_format_version", binding, {"expected": FORMAT_VERSION, "actual": int(binding.get("format_version", 0))})
	if not ROLE_REGISTRY.has(role):
		if PHYSICAL_RELATION_ROLES.has(role):
			return make_result("physical_relation_forbidden", binding, {"role": role})
		return make_result("unsupported_role", binding, {"role": role})
	var parameters: Dictionary = Dictionary(binding.get("parameters", {}))
	for field_name in PHYSICAL_PARAMETER_FIELDS:
		if parameters.has(field_name):
			return make_result("physical_relation_forbidden", binding, {"field": field_name})
	if bindings_by_id.has(binding_id) and binding_id != replacing_binding_id:
		return make_result("duplicate", binding, {"duplicate_binding_id": binding_id})
	for existing_id_value in bindings_by_id.keys():
		var existing_id: String = str(existing_id_value)
		if existing_id == replacing_binding_id:
			continue
		var existing: Dictionary = Dictionary(bindings_by_id[existing_id])
		if _relation_key(existing) == _relation_key(binding):
			return make_result("duplicate", binding, {"duplicate_binding_id": existing_id})
	var source_exists: bool = entities_by_id.has(source_id)
	var target_exists: bool = entities_by_id.has(target_id)
	if not source_exists:
		return make_result("source_missing", binding, {"preservable": allow_missing_entities})
	if not target_exists:
		return make_result("target_missing", binding, {"preservable": allow_missing_entities})
	var source: Dictionary = Dictionary(entities_by_id[source_id])
	var target: Dictionary = Dictionary(entities_by_id[target_id])
	if _is_physical_topology_object(source) or _is_physical_topology_object(target):
		return make_result("physical_relation_forbidden", binding, {"source_type": _object_type(source), "target_type": _object_type(target)})
	var descriptor: Dictionary = Dictionary(ROLE_REGISTRY[role])
	if not _entity_matches(source, descriptor, "source") or not _entity_matches(target, descriptor, "target"):
		return make_result("wrong_type", binding, {
			"source_group": _object_group(source),
			"source_type": _object_type(source),
			"target_group": _object_group(target),
			"target_type": _object_type(target)
		})
	if _entity_is_inactive(source) or _entity_is_inactive(target):
		return make_result("inactive", binding, {
			"source_inactive": _entity_is_inactive(source),
			"target_inactive": _entity_is_inactive(target)
		})
	var max_per_source: int = int(descriptor.get("max_per_source", 0))
	var max_per_target: int = int(descriptor.get("max_per_target", 0))
	if max_per_source > 0 and _count_role_endpoint(bindings_by_id, role, "source_id", source_id, replacing_binding_id) >= max_per_source:
		return make_result("capacity_exceeded", binding, {"endpoint": "source", "capacity": max_per_source})
	if max_per_target > 0 and _count_role_endpoint(bindings_by_id, role, "target_id", target_id, replacing_binding_id) >= max_per_target:
		return make_result("capacity_exceeded", binding, {"endpoint": "target", "capacity": max_per_target})
	if bool(descriptor.get("acyclic", false)) and _would_create_cycle(bindings_by_id, binding, replacing_binding_id):
		return make_result("cycle", binding)
	return make_result(VALID_CODE, binding)

static func build_state(records: Array[Dictionary], entities_by_id: Dictionary, preserve_semantic_invalid: bool = true) -> Dictionary:
	var bindings_by_id: Dictionary = {}
	var diagnostics: Array[Dictionary] = []
	var sorted_records: Array[Dictionary] = []
	for record in records:
		sorted_records.append(canonicalize_record(record))
	sorted_records.sort_custom(_record_id_less)
	for binding in sorted_records:
		var validation: Dictionary = validate_record(binding, entities_by_id, bindings_by_id, "", preserve_semantic_invalid)
		var code: String = str(validation.get("code", "missing"))
		var preservable: bool = bool(Dictionary(validation.get("details", {})).get("preservable", false))
		if preserve_semantic_invalid and code in ["source_missing", "target_missing", "wrong_type", "inactive", "capacity_exceeded", "cycle"]:
			preservable = true
		if code != VALID_CODE and not preservable:
			return {
				"ok": false,
				"success": false,
				"code": code,
				"reason_code": code,
				"binding": binding.duplicate(true),
				"diagnostics": diagnostics.duplicate(true)
			}
		var binding_id: String = str(binding.get("id", ""))
		bindings_by_id[binding_id] = binding.duplicate(true)
		if code != VALID_CODE:
			diagnostics.append(validation.duplicate(true))
	var indexes: Dictionary = rebuild_indexes(bindings_by_id)
	return {
		"ok": true,
		"success": true,
		"code": VALID_CODE,
		"reason_code": VALID_CODE,
		"bindings_by_id": bindings_by_id,
		"indexes": indexes,
		"diagnostics": diagnostics
	}

static func _record_id_less(left: Dictionary, right: Dictionary) -> bool:
	return str(left.get("id", "")) < str(right.get("id", ""))

static func rebuild_indexes(bindings_by_id: Dictionary) -> Dictionary:
	var by_source: Dictionary = {}
	var by_target: Dictionary = {}
	var by_role: Dictionary = {}
	var ids: Array = bindings_by_id.keys()
	ids.sort()
	for binding_id_value in ids:
		var binding_id: String = str(binding_id_value)
		var binding: Dictionary = Dictionary(bindings_by_id[binding_id])
		_append_index(by_source, str(binding.get("source_id", "")), binding_id)
		_append_index(by_target, str(binding.get("target_id", "")), binding_id)
		_append_index(by_role, str(binding.get("role", "")), binding_id)
	return {
		"by_source": by_source,
		"by_target": by_target,
		"by_role": by_role
	}

static func validate_indexes(bindings_by_id: Dictionary, by_source: Dictionary, by_target: Dictionary, by_role: Dictionary) -> Array[String]:
	var warnings: Array[String] = []
	var expected: Dictionary = rebuild_indexes(bindings_by_id)
	if var_to_str(Dictionary(expected.get("by_source", {}))) != var_to_str(by_source):
		warnings.append("binding_source_index_mismatch")
	if var_to_str(Dictionary(expected.get("by_target", {}))) != var_to_str(by_target):
		warnings.append("binding_target_index_mismatch")
	if var_to_str(Dictionary(expected.get("by_role", {}))) != var_to_str(by_role):
		warnings.append("binding_role_index_mismatch")
	return warnings

static func legacy_candidates(entities_by_id: Dictionary) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	var entity_ids: Array = entities_by_id.keys()
	entity_ids.sort()
	for entity_id_value in entity_ids:
		var entity_id: String = str(entity_id_value)
		var entity: Dictionary = Dictionary(entities_by_id[entity_id])
		_append_legacy_scalar(candidates, entity, "control_terminal_id", ROLE_CONTROL_TERMINAL, true, entity_id)
		_append_legacy_scalar(candidates, entity, "linked_terminal_id", ROLE_CONTROL_TERMINAL, true, entity_id)
		_append_legacy_scalar(candidates, entity, "required_terminal_id", ROLE_ACCESS_TERMINAL, true, entity_id)
		_append_legacy_scalar(candidates, entity, "required_key_id", ROLE_ACCESS_ITEM, true, entity_id)
		_append_legacy_scalar(candidates, entity, "required_digital_key_id", ROLE_ACCESS_ITEM, true, entity_id)
		_append_legacy_scalar(candidates, entity, "required_access_code_id", ROLE_ACCESS_ITEM, true, entity_id)
		_append_legacy_scalar(candidates, entity, "preferred_source_id", ROLE_PREFERRED_POWER_SOURCE, false, entity_id)
		_append_legacy_array(candidates, entity, "linked_light_ids", ROLE_LIGHT_CONTROLLER, entity_id)
		_append_legacy_array(candidates, entity, "target_light_ids", ROLE_LIGHT_CONTROLLER, entity_id)
		_append_legacy_array(candidates, entity, "linked_platform_ids", ROLE_PLATFORM_CONTROLLER, entity_id)
	return _deduplicate_candidates(candidates)

static func strip_legacy_logical_links(entity: Dictionary) -> Dictionary:
	var result: Dictionary = entity.duplicate(true)
	for field_name in LEGACY_LOGICAL_LINK_FIELDS:
		result.erase(field_name)
	return result

static func _append_legacy_scalar(candidates: Array[Dictionary], entity: Dictionary, field_name: String, role: String, value_is_source: bool, entity_id: String) -> void:
	var related_id: String = str(entity.get(field_name, "")).strip_edges()
	if related_id.is_empty():
		return
	var source_id: String = related_id if value_is_source else entity_id
	var target_id: String = entity_id if value_is_source else related_id
	candidates.append(_legacy_record(role, source_id, target_id, field_name))

static func _append_legacy_array(candidates: Array[Dictionary], entity: Dictionary, field_name: String, role: String, source_id: String) -> void:
	var raw: Variant = entity.get(field_name, [])
	if not (raw is Array):
		return
	var target_ids: Array = Array(raw).duplicate()
	target_ids.sort()
	for target_id_value in target_ids:
		var target_id: String = str(target_id_value).strip_edges()
		if not target_id.is_empty():
			candidates.append(_legacy_record(role, source_id, target_id, field_name))

static func _legacy_record(role: String, source_id: String, target_id: String, field_name: String) -> Dictionary:
	return {
		"id": "legacy__%s__%s__%s" % [_id_token(role), _id_token(source_id), _id_token(target_id)],
		"role": role,
		"source_id": source_id,
		"target_id": target_id,
		"parameters": {"migrated_from_field": field_name},
		"format_version": FORMAT_VERSION
	}

static func _deduplicate_candidates(candidates: Array[Dictionary]) -> Array[Dictionary]:
	var by_relation: Dictionary = {}
	for candidate in candidates:
		var key: String = _relation_key(candidate)
		if not by_relation.has(key):
			by_relation[key] = candidate.duplicate(true)
	var keys: Array = by_relation.keys()
	keys.sort()
	var result: Array[Dictionary] = []
	for key_value in keys:
		result.append(Dictionary(by_relation[key_value]).duplicate(true))
	return result

static func _entity_matches(entity: Dictionary, descriptor: Dictionary, prefix: String) -> bool:
	var groups: Array = Array(descriptor.get("%s_groups" % prefix, []))
	var types: Array = Array(descriptor.get("%s_types" % prefix, []))
	var entity_types: Array = Array(descriptor.get("%s_entity_types" % prefix, []))
	var roles: Array = Array(descriptor.get("%s_roles" % prefix, []))
	var capability: String = str(descriptor.get("%s_capability" % prefix, ""))
	var has_constraint: bool = not groups.is_empty() or not types.is_empty() or not entity_types.is_empty() or not roles.is_empty() or not capability.is_empty()
	if not has_constraint:
		return true
	if not capability.is_empty() and _has_capability(entity, capability):
		return true
	if groups.has(_object_group(entity)):
		return true
	if types.has(_object_type(entity)):
		return true
	if entity_types.has(_entity_type(entity)):
		return true
	if roles.has(str(entity.get("generic_power_role", "")).strip_edges().to_lower()):
		return true
	return false

static func _has_capability(entity: Dictionary, capability: String) -> bool:
	var contract: Variant = entity.get("entity_contract", {})
	if not (contract is Dictionary):
		return false
	var capabilities: Variant = Dictionary(contract).get("capabilities", {})
	return capabilities is Dictionary and bool(Dictionary(capabilities).get(capability, false))

static func _entity_type(entity: Dictionary) -> String:
	var contract: Variant = entity.get("entity_contract", {})
	if contract is Dictionary:
		var value: String = str(Dictionary(contract).get("entity_type", "")).strip_edges().to_lower()
		if not value.is_empty():
			return value
	return str(entity.get("entity_type", "")).strip_edges().to_lower()

static func _object_group(entity: Dictionary) -> String:
	return str(entity.get("object_group", entity.get("group", ""))).strip_edges().to_lower()

static func _object_type(entity: Dictionary) -> String:
	return str(entity.get("object_type", entity.get("type", entity.get("item_type", "")))).strip_edges().to_lower()

static func _entity_is_inactive(entity: Dictionary) -> bool:
	if entity.has("binding_active") and not bool(entity.get("binding_active", true)):
		return true
	if entity.has("is_operational") and not bool(entity.get("is_operational", true)):
		return true
	return false

static func _is_physical_topology_object(entity: Dictionary) -> bool:
	if PHYSICAL_OBJECT_TYPES.has(_object_type(entity)):
		return true
	var role: String = str(entity.get("generic_power_role", "")).strip_edges().to_lower()
	return role in ["cable_link", "cable_endpoint", "airflow_path_cell", "water_route_cell"]

static func _count_role_endpoint(bindings_by_id: Dictionary, role: String, endpoint_field: String, endpoint_id: String, replacing_binding_id: String) -> int:
	var count: int = 0
	for binding_id_value in bindings_by_id.keys():
		var binding_id: String = str(binding_id_value)
		if binding_id == replacing_binding_id:
			continue
		var binding: Dictionary = Dictionary(bindings_by_id[binding_id])
		if str(binding.get("role", "")) == role and str(binding.get(endpoint_field, "")) == endpoint_id:
			count += 1
	return count

static func _would_create_cycle(bindings_by_id: Dictionary, candidate: Dictionary, replacing_binding_id: String) -> bool:
	var role: String = str(candidate.get("role", ""))
	var adjacency: Dictionary = {}
	for binding_id_value in bindings_by_id.keys():
		var binding_id: String = str(binding_id_value)
		if binding_id == replacing_binding_id:
			continue
		var binding: Dictionary = Dictionary(bindings_by_id[binding_id])
		if str(binding.get("role", "")) != role:
			continue
		_append_index(adjacency, str(binding.get("source_id", "")), str(binding.get("target_id", "")))
	_append_index(adjacency, str(candidate.get("source_id", "")), str(candidate.get("target_id", "")))
	var source_id: String = str(candidate.get("source_id", ""))
	var target_id: String = str(candidate.get("target_id", ""))
	return _path_exists(adjacency, target_id, source_id, {})

static func _path_exists(adjacency: Dictionary, current_id: String, expected_id: String, visited: Dictionary) -> bool:
	if current_id == expected_id:
		return true
	if visited.has(current_id):
		return false
	visited[current_id] = true
	for next_id_value in Array(adjacency.get(current_id, [])):
		if _path_exists(adjacency, str(next_id_value), expected_id, visited):
			return true
	return false

static func _append_index(index: Dictionary, key: String, value: String) -> void:
	if key.is_empty() or value.is_empty():
		return
	var values: Array = Array(index.get(key, []))
	if not values.has(value):
		values.append(value)
		values.sort()
	index[key] = values

static func _relation_key(binding: Dictionary) -> String:
	return "%s\u001f%s\u001f%s" % [str(binding.get("role", "")), str(binding.get("source_id", "")), str(binding.get("target_id", ""))]

static func _id_token(value: String) -> String:
	var result: String = ""
	for index in range(value.length()):
		var character: String = value.substr(index, 1).to_lower()
		if character == "_" or character.is_valid_identifier() or character.is_valid_int():
			result += character
		else:
			result += "_"
	while result.begins_with("_"):
		result = result.trim_prefix("_")
	while result.ends_with("_"):
		result = result.trim_suffix("_")
	return result
