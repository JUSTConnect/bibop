extends RefCounted
class_name AccessResolver

const BindingStoreContractRef = preload("res://scripts/world/world_binding_store_contract.gd")

const ACCESS_NONE := "none"
const ACCESS_KEY_CARD := "key_card"
const ACCESS_DIGITAL_KEY := "digital_key"
const ACCESS_CODE := "access_code"
const ACCESS_TERMINAL := "terminal"
const ACCESS_MULTI_FACTOR := "multi_factor"
const ACCESS_TYPES: Array[String] = [
	ACCESS_NONE,
	ACCESS_KEY_CARD,
	ACCESS_DIGITAL_KEY,
	ACCESS_CODE,
	ACCESS_TERMINAL,
	ACCESS_MULTI_FACTOR
]

const OP_ALL_OF := "all_of"
const OP_ANY_OF := "any_of"
const GROUP_OPERATORS: Array[String] = [OP_ALL_OF, OP_ANY_OF]

const CODE_GRANTED := "access.granted"
const CODE_NOT_REQUIRED := "access.not_required"
const CODE_BINDING_MISSING := "access.binding_missing"
const CODE_SOURCE_MISSING := "access.source_missing"
const CODE_TARGET_MISSING := "access.target_missing"
const CODE_WRONG_TYPE := "access.wrong_type"
const CODE_CREDENTIAL_MISSING := "access.credential_missing"
const CODE_CREDENTIAL_DAMAGED := "access.credential_damaged"
const CODE_CREDENTIAL_ENCRYPTED := "access.credential_encrypted"
const CODE_CREDENTIAL_INVALID := "access.credential_invalid"
const CODE_TERMINAL_MISSING := "access.terminal_missing"
const CODE_TERMINAL_UNPOWERED := "access.terminal_unpowered"
const CODE_TERMINAL_INACTIVE := "access.terminal_inactive"
const CODE_GROUP_FAILED := "access.group_failed"
const CODE_PROFILE_MISSING := "access.profile_missing"
const CODE_INVALID_STRUCTURE := "access.invalid_structure"
const CODE_CYCLE := "access.cycle"

static func normalize_access_type(value: Variant) -> String:
	var normalized: String = str(value).strip_edges().to_lower().replace(" ", "_").replace("-", "_")
	match normalized:
		"", "none", "no_key", "open", "unlocked":
			return ACCESS_NONE
		"key", "keycard", "key_card", "mechanical", "mechanical_key", "physical_key":
			return ACCESS_KEY_CARD
		"digital", "digital_key", "digital_keycard", "digital_access":
			return ACCESS_DIGITAL_KEY
		"code", "pin", "pin_code", "digital_code", "access_code":
			return ACCESS_CODE
		"terminal", "terminal_access", "access_terminal":
			return ACCESS_TERMINAL
		"multi", "multi_factor", "multifactor":
			return ACCESS_MULTI_FACTOR
	return normalized

static func resolve(target: Dictionary, context: Dictionary, bindings: Array[Dictionary], entities_by_id: Dictionary) -> Dictionary:
	var target_id: String = str(target.get("id", "")).strip_edges()
	if target_id.is_empty() or not entities_by_id.has(target_id):
		return _result(false, CODE_TARGET_MISSING, target_id, ACCESS_NONE, [], [], [], [], {}, [{"code":CODE_TARGET_MISSING}])
	var profile: Dictionary = _profile_for(target)
	var access_type: String = normalize_access_type(profile.get("access_type", target.get("access_type", target.get("lock_type", ACCESS_NONE))))
	if access_type not in ACCESS_TYPES:
		return _result(false, CODE_INVALID_STRUCTURE, target_id, access_type, [], [], [], [], {}, [{"code":CODE_INVALID_STRUCTURE, "field":"access_type", "value":access_type}])
	if access_type == ACCESS_NONE:
		return _result(true, CODE_NOT_REQUIRED, target_id, access_type, [], [], [], [], _success_patch(target, profile), [])
	var diagnostics: Array[Dictionary] = []
	var evaluated: Dictionary
	if access_type == ACCESS_MULTI_FACTOR:
		var root: Variant = profile.get("root", profile.get("requirement", null))
		if not root is Dictionary:
			return _result(false, CODE_PROFILE_MISSING, target_id, access_type, [], [], [], [], {}, [{"code":CODE_PROFILE_MISSING, "field":"root"}])
		evaluated = _evaluate_node(Dictionary(root), target, context, bindings, entities_by_id, profile, [], diagnostics)
	else:
		evaluated = _evaluate_factor({"access_type":access_type, "factor_id":str(profile.get("factor_id", ""))}, target, context, bindings, entities_by_id)
	var granted: bool = bool(evaluated.get("granted", false))
	var code: String = CODE_GRANTED if granted else str(evaluated.get("reason_code", CODE_GROUP_FAILED))
	var matched_binding_ids: Array[String] = _unique_strings(evaluated.get("matched_binding_ids", []))
	var matched_source_ids: Array[String] = _unique_strings(evaluated.get("matched_source_ids", []))
	var consumption_plan: Array[Dictionary] = _deduplicate_consumption_plan(Array(evaluated.get("consumption_plan", [])))
	var branches: Array[Dictionary] = []
	if evaluated.has("branch_results"):
		for branch in Array(evaluated.get("branch_results", [])):
			if branch is Dictionary:
				branches.append(Dictionary(branch).duplicate(true))
	var target_patch: Dictionary = _success_patch(target, profile) if granted else {}
	return _result(granted, code, target_id, access_type, branches, matched_binding_ids, matched_source_ids, consumption_plan, target_patch, diagnostics, Dictionary(evaluated.get("details", {})))

static func validate_profile(target: Dictionary) -> Dictionary:
	var profile: Dictionary = _profile_for(target)
	var access_type: String = normalize_access_type(profile.get("access_type", target.get("access_type", target.get("lock_type", ACCESS_NONE))))
	var diagnostics: Array[Dictionary] = []
	if access_type not in ACCESS_TYPES:
		diagnostics.append({"code":CODE_INVALID_STRUCTURE, "field":"access_type", "value":access_type})
	elif access_type == ACCESS_MULTI_FACTOR:
		var root: Variant = profile.get("root", profile.get("requirement", null))
		if not root is Dictionary:
			diagnostics.append({"code":CODE_PROFILE_MISSING, "field":"root"})
		else:
			_validate_node(Dictionary(root), profile, [], diagnostics)
	return {
		"ok":diagnostics.is_empty(),
		"success":diagnostics.is_empty(),
		"code":"access.profile_valid" if diagnostics.is_empty() else str(diagnostics[0].get("code", CODE_INVALID_STRUCTURE)),
		"reason_code":"access.profile_valid" if diagnostics.is_empty() else str(diagnostics[0].get("code", CODE_INVALID_STRUCTURE)),
		"access_type":access_type,
		"diagnostics":diagnostics
	}

static func apply_consumption_plan(inventory_state: Dictionary, consumption_plan: Array[Dictionary]) -> Dictionary:
	var next_inventory: Dictionary = inventory_state.duplicate(true)
	var consumed_ids: Array[String] = []
	for entry in _deduplicate_consumption_plan(consumption_plan):
		if not bool(entry.get("consume_on_use", false)):
			continue
		var item_id: String = str(entry.get("item_id", "")).strip_edges()
		if item_id.is_empty():
			continue
		for field_name in ["pocket_items", "box_storage", "digital_buffer", "digital_storage", "collected_key_ids"]:
			var values: Array = Array(next_inventory.get(field_name, [])).duplicate(true)
			var filtered: Array = []
			for value in values:
				if _item_id(value) != item_id:
					filtered.append(value)
			next_inventory[field_name] = filtered
		if _item_id(next_inventory.get("manipulator_hold", "")) == item_id:
			next_inventory["manipulator_hold"] = ""
		var runtime_map: Dictionary = Dictionary(next_inventory.get("world_item_runtime", {})).duplicate(true)
		runtime_map.erase(item_id)
		next_inventory["world_item_runtime"] = runtime_map
		if not consumed_ids.has(item_id):
			consumed_ids.append(item_id)
	var previous_consumed: Array = Array(next_inventory.get("consumed_item_ids", [])).duplicate()
	for item_id in consumed_ids:
		if not previous_consumed.has(item_id):
			previous_consumed.append(item_id)
	next_inventory["consumed_item_ids"] = previous_consumed
	return {
		"ok":true,
		"success":true,
		"code":"access.consumption_applied",
		"reason_code":"access.consumption_applied",
		"inventory":next_inventory,
		"consumed_item_ids":consumed_ids
	}

static func _evaluate_node(node: Dictionary, target: Dictionary, context: Dictionary, bindings: Array[Dictionary], entities_by_id: Dictionary, profile: Dictionary, stack: Array[String], diagnostics: Array[Dictionary]) -> Dictionary:
	var group_ref: String = str(node.get("group_ref", "")).strip_edges()
	if not group_ref.is_empty():
		if stack.has(group_ref):
			var cycle: Array[String] = stack.duplicate()
			cycle.append(group_ref)
			diagnostics.append({"code":CODE_CYCLE, "group_id":group_ref, "cycle":cycle})
			return _branch(false, CODE_CYCLE, ACCESS_MULTI_FACTOR, group_ref, [], [], [], [], {"cycle":cycle})
		var groups: Dictionary = Dictionary(profile.get("groups", {}))
		if not groups.has(group_ref) or not groups[group_ref] is Dictionary:
			diagnostics.append({"code":CODE_INVALID_STRUCTURE, "group_id":group_ref, "reason":"group_ref_missing"})
			return _branch(false, CODE_INVALID_STRUCTURE, ACCESS_MULTI_FACTOR, group_ref)
		var next_stack: Array[String] = stack.duplicate()
		next_stack.append(group_ref)
		var referenced: Dictionary = Dictionary(groups[group_ref]).duplicate(true)
		if not referenced.has("group_id"):
			referenced["group_id"] = group_ref
		return _evaluate_node(referenced, target, context, bindings, entities_by_id, profile, next_stack, diagnostics)
	var operator: String = str(node.get("operator", node.get("type", ""))).strip_edges().to_lower().replace(" ", "_").replace("-", "_")
	if operator in GROUP_OPERATORS:
		var group_id: String = str(node.get("group_id", node.get("id", ""))).strip_edges()
		var children_value: Variant = node.get("children", node.get("requirements", []))
		if not children_value is Array or Array(children_value).is_empty():
			diagnostics.append({"code":CODE_INVALID_STRUCTURE, "group_id":group_id, "reason":"children_missing"})
			return _branch(false, CODE_INVALID_STRUCTURE, ACCESS_MULTI_FACTOR, group_id)
		var child_results: Array[Dictionary] = []
		var all_binding_ids: Array[String] = []
		var all_source_ids: Array[String] = []
		var plan: Array[Dictionary] = []
		var granted_count: int = 0
		var first_blocker: String = ""
		for child_value in Array(children_value):
			if not child_value is Dictionary:
				var invalid_child: Dictionary = _branch(false, CODE_INVALID_STRUCTURE, ACCESS_MULTI_FACTOR, "")
				child_results.append(invalid_child)
				if first_blocker.is_empty():
					first_blocker = CODE_INVALID_STRUCTURE
				continue
			var child_result: Dictionary = _evaluate_node(Dictionary(child_value), target, context, bindings, entities_by_id, profile, stack, diagnostics)
			child_results.append(child_result)
			if bool(child_result.get("granted", false)):
				granted_count += 1
			elif first_blocker.is_empty():
				first_blocker = str(child_result.get("reason_code", CODE_GROUP_FAILED))
			all_binding_ids.append_array(_unique_strings(child_result.get("matched_binding_ids", [])))
			all_source_ids.append_array(_unique_strings(child_result.get("matched_source_ids", [])))
			for plan_entry in Array(child_result.get("consumption_plan", [])):
				if plan_entry is Dictionary:
					plan.append(Dictionary(plan_entry).duplicate(true))
		var group_granted: bool = granted_count == child_results.size() if operator == OP_ALL_OF else granted_count > 0
		var reason: String = CODE_GRANTED if group_granted else first_blocker if not first_blocker.is_empty() else CODE_GROUP_FAILED
		return _branch(group_granted, reason, ACCESS_MULTI_FACTOR, group_id, child_results, _unique_strings(all_binding_ids), _unique_strings(all_source_ids), _deduplicate_consumption_plan(plan), {"operator":operator, "granted_count":granted_count, "branch_count":child_results.size()})
	return _evaluate_factor(node, target, context, bindings, entities_by_id)

static func _evaluate_factor(factor: Dictionary, target: Dictionary, context: Dictionary, bindings: Array[Dictionary], entities_by_id: Dictionary) -> Dictionary:
	var access_type: String = normalize_access_type(factor.get("access_type", factor.get("type", "")))
	var factor_id: String = str(factor.get("factor_id", factor.get("id", ""))).strip_edges()
	if access_type == ACCESS_NONE:
		return _branch(true, CODE_NOT_REQUIRED, access_type, factor_id)
	if access_type not in [ACCESS_KEY_CARD, ACCESS_DIGITAL_KEY, ACCESS_CODE, ACCESS_TERMINAL]:
		return _branch(false, CODE_INVALID_STRUCTURE, access_type, factor_id)
	var target_id: String = str(target.get("id", "")).strip_edges()
	var role: String = BindingStoreContractRef.ROLE_ACCESS_TERMINAL if access_type == ACCESS_TERMINAL else BindingStoreContractRef.ROLE_ACCESS_ITEM
	var candidates: Array[Dictionary] = _bindings_for_target(bindings, target_id, role, factor_id)
	if candidates.is_empty():
		return _branch(false, CODE_BINDING_MISSING, access_type, factor_id)
	var first_failure: Dictionary = {}
	for binding in candidates:
		var binding_id: String = str(binding.get("id", ""))
		var source_id: String = str(binding.get("source_id", "")).strip_edges()
		if not entities_by_id.has(source_id):
			if first_failure.is_empty():
				first_failure = _branch(false, CODE_SOURCE_MISSING, access_type, factor_id, [], [binding_id], [source_id])
			continue
		var source: Dictionary = Dictionary(entities_by_id[source_id])
		var source_result: Dictionary = _evaluate_terminal(source, source_id, context) if access_type == ACCESS_TERMINAL else _evaluate_credential(source, source_id, access_type, context)
		if bool(source_result.get("granted", false)):
			var consumption_plan: Array[Dictionary] = []
			if access_type != ACCESS_TERMINAL:
				consumption_plan.append({"item_id":source_id, "consume_on_use":bool(source.get("consume_on_use", false)), "binding_id":binding_id, "factor_id":factor_id})
			return _branch(true, CODE_GRANTED, access_type, factor_id, [], [binding_id], [source_id], consumption_plan, Dictionary(source_result.get("details", {})))
		if first_failure.is_empty():
			first_failure = _branch(false, str(source_result.get("reason_code", CODE_CREDENTIAL_MISSING)), access_type, factor_id, [], [binding_id], [source_id], [], Dictionary(source_result.get("details", {})))
	return first_failure if not first_failure.is_empty() else _branch(false, CODE_BINDING_MISSING, access_type, factor_id)

static func _evaluate_credential(source: Dictionary, source_id: String, expected_type: String, context: Dictionary) -> Dictionary:
	var actual_type: String = _credential_type(source)
	if actual_type != expected_type:
		return _branch(false, CODE_WRONG_TYPE, expected_type, "", [], [], [source_id], [], {"actual_type":actual_type})
	var state: String = str(source.get("credential_state", source.get("health_state", source.get("state", "valid")))).strip_edges().to_lower().replace(" ", "_").replace("-", "_")
	if bool(source.get("invalid", false)) or state in ["invalid", "expired", "revoked"]:
		return _branch(false, CODE_CREDENTIAL_INVALID, expected_type, "", [], [], [source_id])
	if bool(source.get("damaged", false)) or bool(source.get("broken", false)) or state in ["damaged", "broken", "destroyed"]:
		return _branch(false, CODE_CREDENTIAL_DAMAGED, expected_type, "", [], [], [source_id])
	if (bool(source.get("encrypted", false)) or state == "encrypted") and not bool(source.get("decrypted", false)):
		return _branch(false, CODE_CREDENTIAL_ENCRYPTED, expected_type, "", [], [], [source_id])
	if not _available_credential_ids(context).has(source_id):
		return _branch(false, CODE_CREDENTIAL_MISSING, expected_type, "", [], [], [source_id])
	return _branch(true, CODE_GRANTED, expected_type, "", [], [], [source_id])

static func _evaluate_terminal(source: Dictionary, source_id: String, context: Dictionary) -> Dictionary:
	if not _is_terminal(source):
		return _branch(false, CODE_WRONG_TYPE, ACCESS_TERMINAL, "", [], [], [source_id])
	if not _available_terminal_ids(context).has(source_id):
		return _branch(false, CODE_TERMINAL_MISSING, ACCESS_TERMINAL, "", [], [], [source_id])
	var state: String = str(source.get("operational_state", source.get("status", source.get("state", "active")))).strip_edges().to_lower()
	if bool(source.get("damaged", false)) or bool(source.get("broken", false)) or state in ["damaged", "broken", "destroyed", "disabled", "error"]:
		return _branch(false, CODE_TERMINAL_INACTIVE, ACCESS_TERMINAL, "", [], [], [source_id])
	if source.get("is_powered", true) == false or str(source.get("power_state", "")).strip_edges().to_lower() == "unpowered" or state == "unpowered":
		return _branch(false, CODE_TERMINAL_UNPOWERED, ACCESS_TERMINAL, "", [], [], [source_id])
	return _branch(true, CODE_GRANTED, ACCESS_TERMINAL, "", [], [], [source_id])

static func _bindings_for_target(bindings: Array[Dictionary], target_id: String, role: String, factor_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for binding in bindings:
		if str(binding.get("role", "")).strip_edges().to_lower() != role:
			continue
		if str(binding.get("target_id", "")).strip_edges() != target_id:
			continue
		var parameters: Dictionary = Dictionary(binding.get("parameters", {}))
		var binding_factor_id: String = str(parameters.get("factor_id", "")).strip_edges()
		if not factor_id.is_empty() and binding_factor_id != factor_id:
			continue
		result.append(binding.duplicate(true))
	result.sort_custom(func(left: Dictionary, right: Dictionary) -> bool: return str(left.get("id", "")) < str(right.get("id", "")))
	return result

static func _profile_for(target: Dictionary) -> Dictionary:
	var value: Variant = target.get("access_profile_data", target.get("access_requirement", {}))
	var profile: Dictionary = Dictionary(value).duplicate(true) if value is Dictionary else {}
	if not profile.has("access_type"):
		profile["access_type"] = target.get("access_type", target.get("lock_type", ACCESS_NONE))
	return profile

static func _success_patch(target: Dictionary, profile: Dictionary) -> Dictionary:
	var explicit_patch: Variant = profile.get("success_patch", target.get("access_success_patch", {}))
	if explicit_patch is Dictionary and not Dictionary(explicit_patch).is_empty():
		return Dictionary(explicit_patch).duplicate(true)
	var patch: Dictionary = {"access_granted":true}
	var object_group: String = str(target.get("object_group", "")).strip_edges().to_lower()
	var object_type: String = str(target.get("object_type", "")).strip_edges().to_lower()
	if object_group == "door" or object_type == "door" or object_type.contains("door") or object_type.contains("gate"):
		patch["is_locked"] = false
		patch["locked"] = false
	return patch

static func _validate_node(node: Dictionary, profile: Dictionary, stack: Array[String], diagnostics: Array[Dictionary]) -> void:
	var group_ref: String = str(node.get("group_ref", "")).strip_edges()
	if not group_ref.is_empty():
		if stack.has(group_ref):
			diagnostics.append({"code":CODE_CYCLE, "group_id":group_ref, "cycle":stack + [group_ref]})
			return
		var groups: Dictionary = Dictionary(profile.get("groups", {}))
		if not groups.has(group_ref) or not groups[group_ref] is Dictionary:
			diagnostics.append({"code":CODE_INVALID_STRUCTURE, "group_id":group_ref, "reason":"group_ref_missing"})
			return
		var next_stack: Array[String] = stack.duplicate()
		next_stack.append(group_ref)
		_validate_node(Dictionary(groups[group_ref]), profile, next_stack, diagnostics)
		return
	var operator: String = str(node.get("operator", node.get("type", ""))).strip_edges().to_lower().replace(" ", "_").replace("-", "_")
	if operator in GROUP_OPERATORS:
		var children: Variant = node.get("children", node.get("requirements", []))
		if not children is Array or Array(children).is_empty():
			diagnostics.append({"code":CODE_INVALID_STRUCTURE, "group_id":str(node.get("group_id", "")), "reason":"children_missing"})
			return
		for child in Array(children):
			if child is Dictionary:
				_validate_node(Dictionary(child), profile, stack, diagnostics)
			else:
				diagnostics.append({"code":CODE_INVALID_STRUCTURE, "reason":"child_not_dictionary"})
		return
	var access_type: String = normalize_access_type(node.get("access_type", node.get("type", "")))
	if access_type not in [ACCESS_NONE, ACCESS_KEY_CARD, ACCESS_DIGITAL_KEY, ACCESS_CODE, ACCESS_TERMINAL]:
		diagnostics.append({"code":CODE_INVALID_STRUCTURE, "field":"access_type", "value":access_type})

static func _credential_type(source: Dictionary) -> String:
	for field_name in ["access_type", "key_access_type", "key_type", "credential_type", "item_class", "digital_item_type", "item_type", "object_type", "map_constructor_prefab_id"]:
		var normalized: String = normalize_access_type(source.get(field_name, ""))
		if normalized in [ACCESS_KEY_CARD, ACCESS_DIGITAL_KEY, ACCESS_CODE]:
			return normalized
	return ""

static func _available_credential_ids(context: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for field_name in ["credential_ids", "presented_credential_ids", "collected_key_ids", "digital_key_ids", "access_code_ids"]:
		result.append_array(_ids_from_variant(context.get(field_name, [])))
	var inventory: Dictionary = Dictionary(context.get("inventory", {}))
	for field_name in ["pocket_items", "box_storage", "digital_buffer", "digital_storage", "collected_key_ids"]:
		result.append_array(_ids_from_variant(inventory.get(field_name, [])))
	result.append_array(_ids_from_variant(inventory.get("manipulator_hold", "")))
	return _unique_strings(result)

static func _available_terminal_ids(context: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for field_name in ["terminal_id", "access_terminal_id", "command_source_id", "terminal_ids", "available_terminal_ids"]:
		result.append_array(_ids_from_variant(context.get(field_name, [])))
	return _unique_strings(result)

static func _ids_from_variant(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in Array(value):
			var item_id: String = _item_id(item)
			if not item_id.is_empty():
				result.append(item_id)
	else:
		var item_id: String = _item_id(value)
		if not item_id.is_empty():
			result.append(item_id)
	return result

static func _item_id(value: Variant) -> String:
	if value is String or value is StringName:
		return str(value).strip_edges()
	if value is Dictionary:
		return str(Dictionary(value).get("id", Dictionary(value).get("item_id", ""))).strip_edges()
	return ""

static func _is_terminal(source: Dictionary) -> bool:
	var object_group: String = str(source.get("object_group", "")).strip_edges().to_lower()
	var object_type: String = str(source.get("object_type", "")).strip_edges().to_lower()
	return object_group == "terminal" or object_type in ["terminal", "information_terminal", "control_terminal", "access_terminal"]

static func _deduplicate_consumption_plan(plan: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var seen: Dictionary = {}
	for value in plan:
		if not value is Dictionary:
			continue
		var entry: Dictionary = Dictionary(value).duplicate(true)
		var item_id: String = str(entry.get("item_id", "")).strip_edges()
		if item_id.is_empty() or seen.has(item_id):
			continue
		seen[item_id] = true
		result.append(entry)
	result.sort_custom(func(left: Dictionary, right: Dictionary) -> bool: return str(left.get("item_id", "")) < str(right.get("item_id", "")))
	return result

static func _unique_strings(values: Variant) -> Array[String]:
	var result: Array[String] = []
	if values is Array:
		for value in Array(values):
			var text: String = str(value).strip_edges()
			if not text.is_empty() and not result.has(text):
				result.append(text)
	result.sort()
	return result

static func _branch(granted: bool, reason_code: String, access_type: String, factor_id: String, branch_results: Array[Dictionary] = [], matched_binding_ids: Array[String] = [], matched_source_ids: Array[String] = [], consumption_plan: Array[Dictionary] = [], details: Dictionary = {}) -> Dictionary:
	return {
		"granted":granted,
		"success":granted,
		"reason_code":reason_code,
		"access_type":access_type,
		"factor_id":factor_id,
		"branch_results":branch_results.duplicate(true),
		"matched_binding_ids":_unique_strings(matched_binding_ids),
		"matched_source_ids":_unique_strings(matched_source_ids),
		"consumption_plan":_deduplicate_consumption_plan(consumption_plan),
		"details":details.duplicate(true)
	}

static func _result(granted: bool, code: String, target_id: String, access_type: String, branch_results: Array[Dictionary], matched_binding_ids: Array[String], matched_source_ids: Array[String], consumption_plan: Array[Dictionary], target_patch: Dictionary, diagnostics: Array[Dictionary], details: Dictionary = {}) -> Dictionary:
	var structurally_valid: bool = code not in [CODE_TARGET_MISSING, CODE_PROFILE_MISSING, CODE_INVALID_STRUCTURE, CODE_CYCLE]
	return {
		"ok":structurally_valid,
		"success":granted,
		"granted":granted,
		"code":code,
		"reason_code":code,
		"first_blocking_reason_code":"" if granted else code,
		"target_id":target_id,
		"access_type":access_type,
		"branch_results":branch_results.duplicate(true),
		"matched_binding_ids":_unique_strings(matched_binding_ids),
		"matched_source_ids":_unique_strings(matched_source_ids),
		"consumption_plan":_deduplicate_consumption_plan(consumption_plan),
		"target_patch":target_patch.duplicate(true),
		"diagnostics":diagnostics.duplicate(true),
		"details":details.duplicate(true)
	}
