extends RefCounted
class_name AccessRuntimeService

const AccessResolverRef = preload("res://scripts/world/access_resolver.gd")
const WorldStateStoreRef = preload("res://scripts/world/world_state_store.gd")

static func preview(store: WorldStateStore, target_id: String, context: Dictionary = {}) -> Dictionary:
	if store == null:
		return _failure("access.store_missing", target_id)
	var target: Dictionary = store.get_object_by_id(target_id)
	if target.is_empty():
		return _failure(AccessResolverRef.CODE_TARGET_MISSING, target_id)
	var entities_by_id: Dictionary = _index_entities(store.get_all_objects())
	return AccessResolverRef.resolve(target, context.duplicate(true), store.get_all_bindings(), entities_by_id)

static func apply_access(store: WorldStateStore, target_id: String, context: Dictionary = {}, inventory_state: Dictionary = {}) -> Dictionary:
	if store == null:
		return _failure("access.store_missing", target_id, inventory_state)
	var effective_context: Dictionary = context.duplicate(true)
	effective_context["inventory"] = inventory_state.duplicate(true)
	var before_target: Dictionary = store.get_object_by_id(target_id)
	if before_target.is_empty():
		return _failure(AccessResolverRef.CODE_TARGET_MISSING, target_id, inventory_state)
	var resolution: Dictionary = preview(store, target_id, effective_context)
	if not bool(resolution.get("granted", false)):
		return _unchanged_result(resolution, before_target, inventory_state)
	var patch: Dictionary = Dictionary(resolution.get("target_patch", {})).duplicate(true)
	var plan: Array[Dictionary] = []
	for entry in Array(resolution.get("consumption_plan", [])):
		if entry is Dictionary:
			plan.append(Dictionary(entry).duplicate(true))
	if patch.is_empty():
		return _unchanged_result(resolution, before_target, inventory_state)
	var update_result: Dictionary = store.update_object_state(target_id, patch)
	if not bool(update_result.get("ok", false)):
		return {
			"ok":false,
			"success":false,
			"granted":false,
			"code":"access.target_commit_failed",
			"reason_code":"access.target_commit_failed",
			"first_blocking_reason_code":"access.target_commit_failed",
			"target_id":target_id,
			"resolution":resolution,
			"update":update_result,
			"target_before":before_target.duplicate(true),
			"target_after":before_target.duplicate(true),
			"inventory_before":inventory_state.duplicate(true),
			"inventory_after":inventory_state.duplicate(true),
			"consumed_item_ids":[],
			"mutated":false
		}
	var consumption: Dictionary = AccessResolverRef.apply_consumption_plan(inventory_state, plan)
	var result: Dictionary = resolution.duplicate(true)
	result["target_before"] = before_target.duplicate(true)
	result["target_after"] = store.get_object_by_id(target_id)
	result["inventory_before"] = inventory_state.duplicate(true)
	result["inventory_after"] = Dictionary(consumption.get("inventory", inventory_state)).duplicate(true)
	result["consumed_item_ids"] = Array(consumption.get("consumed_item_ids", [])).duplicate()
	result["update"] = update_result
	result["consumption"] = consumption
	result["mutated"] = true
	return result

static func _unchanged_result(resolution: Dictionary, target: Dictionary, inventory_state: Dictionary) -> Dictionary:
	var result: Dictionary = resolution.duplicate(true)
	result["target_before"] = target.duplicate(true)
	result["target_after"] = target.duplicate(true)
	result["inventory_before"] = inventory_state.duplicate(true)
	result["inventory_after"] = inventory_state.duplicate(true)
	result["consumed_item_ids"] = []
	result["update"] = {}
	result["consumption"] = {}
	result["mutated"] = false
	return result

static func _index_entities(objects: Array[Dictionary]) -> Dictionary:
	var result: Dictionary = {}
	for object_data in objects:
		var entity_id: String = str(object_data.get("id", "")).strip_edges()
		if not entity_id.is_empty():
			result[entity_id] = object_data.duplicate(true)
	return result

static func _failure(code: String, target_id: String, inventory_state: Dictionary = {}) -> Dictionary:
	return {
		"ok":false,
		"success":false,
		"granted":false,
		"code":code,
		"reason_code":code,
		"first_blocking_reason_code":code,
		"target_id":target_id,
		"target_before":{},
		"target_after":{},
		"inventory_before":inventory_state.duplicate(true),
		"inventory_after":inventory_state.duplicate(true),
		"consumed_item_ids":[],
		"mutated":false
	}
