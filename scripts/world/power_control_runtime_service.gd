extends RefCounted
class_name PowerControlRuntimeService

const ResolverRef = preload("res://scripts/world/power_control_resolver.gd")
const WorldStateStoreRef = preload("res://scripts/world/world_state_store.gd")

static func preview(store: WorldStateStore, options: Dictionary = {}) -> Dictionary:
	if store == null:
		return _result(false, "power_control.store_missing")
	return ResolverRef.resolve_world(store.get_all_objects(), store.get_all_bindings(), options)

static func apply_event(store: WorldStateStore, event: Dictionary) -> Dictionary:
	if store == null:
		return _result(false, "power_control.store_missing")
	var objects: Array[Dictionary] = store.get_all_objects()
	var bindings: Array[Dictionary] = store.get_all_bindings()
	var resolution: Dictionary = ResolverRef.apply_scoped_event(objects, bindings, event)
	var event_type: String = str(event.get("event_type", event.get("type", "power.explicit"))).strip_edges().to_lower().replace(" ", "_")
	if event_type.is_empty():
		event_type = "power.explicit"
	var commit: Dictionary = store.apply_non_structural_snapshot(objects, "power_control_%s" % event_type.replace(".", "_"))
	if not bool(commit.get("ok", false)):
		return {
			"ok":false,
			"success":false,
			"code":"power_control.commit_failed",
			"reason_code":"power_control.commit_failed",
			"event_type":event_type,
			"resolution":resolution,
			"commit":commit
		}
	resolution["commit"] = commit
	resolution["event_type"] = event_type
	return resolution

static func recalculate_network(store: WorldStateStore, network_id: String, event_type: String = "power.network_recalculated") -> Dictionary:
	return apply_event(store, {"event_type":event_type, "network_id":network_id})

static func resolve_entity_power(store: WorldStateStore, entity_id: String) -> Dictionary:
	var result: Dictionary = preview(store, {"entity_id":entity_id})
	return Dictionary(Dictionary(result.get("power_results", {})).get(entity_id, {})).duplicate(true)

static func resolve_entity_control(store: WorldStateStore, entity_id: String) -> Dictionary:
	var result: Dictionary = preview(store, {"entity_id":entity_id})
	return Dictionary(Dictionary(result.get("control_results", {})).get(entity_id, {})).duplicate(true)

static func apply_control_loss(store: WorldStateStore, entity_id: String) -> Dictionary:
	if store == null:
		return _result(false, "power_control.store_missing")
	var object_data: Dictionary = store.get_object_by_id(entity_id)
	if object_data.is_empty():
		return _result(false, "control.target_missing", {"entity_id":entity_id})
	var control_result: Dictionary = resolve_entity_control(store, entity_id)
	var patch_result: Dictionary = ResolverRef.build_control_loss_patch(object_data, control_result)
	var patch: Dictionary = Dictionary(patch_result.get("patch", {}))
	if patch.is_empty():
		var no_change: Dictionary = patch_result.duplicate(true)
		no_change["entity_id"] = entity_id
		no_change["control_result"] = control_result
		return no_change
	var update: Dictionary = store.update_object_state(entity_id, patch)
	if not bool(update.get("ok", false)):
		return _result(false, "control.loss_commit_failed", {"entity_id":entity_id, "patch":patch, "update":update})
	var result: Dictionary = patch_result.duplicate(true)
	result["entity_id"] = entity_id
	result["control_result"] = control_result
	result["update"] = update
	return result

static func _result(success: bool, code: String, details: Dictionary = {}) -> Dictionary:
	return {
		"ok":success,
		"success":success,
		"code":code,
		"reason_code":code,
		"details":details.duplicate(true)
	}
