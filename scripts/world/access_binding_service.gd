extends RefCounted
class_name AccessBindingService

const AccessResolverRef = preload("res://scripts/world/access_resolver.gd")
const BindingStoreContractRef = preload("res://scripts/world/world_binding_store_contract.gd")
const WorldStateStoreRef = preload("res://scripts/world/world_state_store.gd")

const ACCESS_ROLES: Array[String] = [
	BindingStoreContractRef.ROLE_ACCESS_ITEM,
	BindingStoreContractRef.ROLE_ACCESS_TERMINAL
]

static func preview_relation(store: WorldStateStore, role: String, source_id: String, target_id: String, factor_id: String = "", replacing_binding_id: String = "") -> Dictionary:
	if store == null:
		return _result(false, "missing", {}, {"field":"store"})
	var normalized_role: String = role.strip_edges().to_lower()
	if normalized_role not in ACCESS_ROLES:
		return _result(false, "unsupported_role", {}, {"role":normalized_role})
	var binding: Dictionary = {
		"id":replacing_binding_id if not replacing_binding_id.is_empty() else _preview_binding_id(normalized_role, source_id, target_id, factor_id),
		"role":normalized_role,
		"source_id":source_id.strip_edges(),
		"target_id":target_id.strip_edges(),
		"parameters":{},
		"format_version":BindingStoreContractRef.FORMAT_VERSION
	}
	if not factor_id.strip_edges().is_empty():
		binding["parameters"] = {"factor_id":factor_id.strip_edges()}
	var validation: Dictionary = store.validate_binding(binding, replacing_binding_id)
	var result: Dictionary = validation.duplicate(true)
	result["binding"] = binding.duplicate(true)
	result["fix_hint"] = fix_hint_for_code(str(validation.get("code", "missing")))
	return result

static func create_or_replace_relation(store: WorldStateStore, record: Dictionary, replacing_binding_id: String = "") -> Dictionary:
	if store == null:
		return _result(false, "missing", record, {"field":"store"})
	var role: String = str(record.get("role", "")).strip_edges().to_lower()
	if role not in ACCESS_ROLES:
		return _result(false, "unsupported_role", record, {"role":role})
	var result: Dictionary
	if replacing_binding_id.strip_edges().is_empty():
		result = store.create_binding(record)
	else:
		result = store.replace_binding(replacing_binding_id.strip_edges(), record)
	result["fix_hint"] = fix_hint_for_code(str(result.get("code", "missing")))
	return result

static func remove_relation(store: WorldStateStore, binding_id: String) -> Dictionary:
	if store == null:
		return _result(false, "missing", {"id":binding_id}, {"field":"store"})
	var result: Dictionary = store.remove_binding(binding_id.strip_edges())
	result["fix_hint"] = fix_hint_for_code(str(result.get("code", "missing")))
	return result

static func filtered_target_picker(store: WorldStateStore, source_id: String, role: String, factor_id: String = "") -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	if store == null:
		return rows
	var entities: Array[Dictionary] = store.get_all_objects()
	entities.sort_custom(func(left: Dictionary, right: Dictionary) -> bool: return str(left.get("id", "")) < str(right.get("id", "")))
	for target in entities:
		var target_id: String = str(target.get("id", "")).strip_edges()
		if target_id.is_empty() or target_id == source_id:
			continue
		var preview: Dictionary = preview_relation(store, role, source_id, target_id, factor_id)
		rows.append({
			"target_id":target_id,
			"target":target.duplicate(true),
			"selectable":bool(preview.get("success", false)),
			"code":str(preview.get("code", "missing")),
			"reason_code":str(preview.get("reason_code", preview.get("code", "missing"))),
			"fix_hint":str(preview.get("fix_hint", "")),
			"preview":preview
		})
	return rows

static func reverse_index_preview(store: WorldStateStore, entity_id: String) -> Dictionary:
	if store == null:
		return {"entity_id":entity_id, "outgoing":[], "incoming":[], "roles":{}}
	var outgoing: Array[Dictionary] = _sorted_bindings(store.get_bindings_by_source_id(entity_id))
	var incoming: Array[Dictionary] = _sorted_bindings(store.get_bindings_by_target_id(entity_id))
	var roles: Dictionary = {}
	for binding in outgoing + incoming:
		var role: String = str(binding.get("role", "")).strip_edges().to_lower()
		var ids: Array = Array(roles.get(role, []))
		var binding_id: String = str(binding.get("id", ""))
		if not ids.has(binding_id):
			ids.append(binding_id)
			ids.sort()
		roles[role] = ids
	return {
		"entity_id":entity_id,
		"outgoing":outgoing,
		"incoming":incoming,
		"roles":roles
	}

static func resolve_target(store: WorldStateStore, target_id: String, context: Dictionary = {}) -> Dictionary:
	if store == null:
		return _result(false, "missing", {"target_id":target_id}, {"field":"store"})
	var target: Dictionary = store.get_object_by_id(target_id)
	var entities_by_id: Dictionary = {}
	for entity in store.get_all_objects():
		var entity_id: String = str(entity.get("id", "")).strip_edges()
		if not entity_id.is_empty():
			entities_by_id[entity_id] = entity.duplicate(true)
	return AccessResolverRef.resolve(target, context, store.get_all_bindings(), entities_by_id)

static func fix_hint_for_code(code: String) -> String:
	match code.strip_edges().to_lower():
		"valid":
			return ""
		"missing":
			return "Choose a source, target, role and stable binding id."
		"source_missing":
			return "Restore the source entity or remove the stale binding."
		"target_missing":
			return "Restore the target entity or remove the stale binding."
		"wrong_type":
			return "Choose a credential/terminal and an access-capable target compatible with this role."
		"inactive":
			return "Repair or activate the source and target before promotion."
		"capacity_exceeded":
			return "Remove or replace the existing relation before adding another."
		"duplicate":
			return "Reuse or replace the existing canonical relation."
		"cycle":
			return "Remove the relation that closes the logical cycle."
		"unsupported_role":
			return "Use access_item or access_terminal."
		"physical_relation_forbidden":
			return "Keep physical cable, reel and route topology outside BindingStore."
	return "Review the canonical binding diagnostic."

static func _preview_binding_id(role: String, source_id: String, target_id: String, factor_id: String) -> String:
	var suffix: String = factor_id.strip_edges()
	return "preview_%s_%s_%s%s" % [role, source_id.strip_edges(), target_id.strip_edges(), "_%s" % suffix if not suffix.is_empty() else ""]

static func _sorted_bindings(bindings: Array[Dictionary]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for binding in bindings:
		result.append(binding.duplicate(true))
	result.sort_custom(func(left: Dictionary, right: Dictionary) -> bool: return str(left.get("id", "")) < str(right.get("id", "")))
	return result

static func _result(success: bool, code: String, binding: Dictionary, details: Dictionary = {}) -> Dictionary:
	return {
		"ok":success,
		"success":success,
		"code":code,
		"reason_code":code,
		"binding":binding.duplicate(true),
		"details":details.duplicate(true),
		"fix_hint":fix_hint_for_code(code)
	}
