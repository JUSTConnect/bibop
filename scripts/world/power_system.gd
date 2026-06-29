extends RefCounted
class_name PowerSystem

const PowerControlResolverRef = preload("res://scripts/world/power_control_resolver.gd")

const POWER_MODE_NONE := PowerControlResolverRef.POWER_MODE_NONE
const POWER_MODE_INTERNAL := PowerControlResolverRef.POWER_MODE_INTERNAL
const POWER_MODE_EXTERNAL := PowerControlResolverRef.POWER_MODE_EXTERNAL
const POWER_STATE_NONE := PowerControlResolverRef.POWER_STATE_NONE
const POWER_STATE_POWERED := PowerControlResolverRef.POWER_STATE_POWERED
const POWER_STATE_UNPOWERED := PowerControlResolverRef.POWER_STATE_UNPOWERED
const POWER_STATE_AMBIGUOUS := PowerControlResolverRef.POWER_STATE_AMBIGUOUS
const POWER_STATE_INVALID := PowerControlResolverRef.POWER_STATE_INVALID
const CONTROL_MODE_NONE := PowerControlResolverRef.CONTROL_MODE_NONE
const CONTROL_MODE_INTERNAL := PowerControlResolverRef.CONTROL_MODE_INTERNAL
const CONTROL_MODE_EXTERNAL := PowerControlResolverRef.CONTROL_MODE_EXTERNAL

static func preview_world(objects: Array[Dictionary], bindings: Array[Dictionary] = [], options: Dictionary = {}) -> Dictionary:
	return PowerControlResolverRef.resolve_world(objects, bindings, options)

static func apply_world(objects: Array[Dictionary], bindings: Array[Dictionary] = [], options: Dictionary = {}) -> Dictionary:
	return PowerControlResolverRef.apply_world_results(objects, bindings, options)

static func preview_network(objects: Array[Dictionary], network_id: String, bindings: Array[Dictionary] = []) -> Dictionary:
	return PowerControlResolverRef.resolve_world(objects, bindings, {"network_id":network_id})

static func recalculate_network(objects: Array[Dictionary], network_id: String, bindings: Array[Dictionary] = []) -> Array[Dictionary]:
	PowerControlResolverRef.apply_scoped_event(objects, bindings, {
		"event_type":"power.network_recalculated",
		"network_id":network_id
	})
	return objects

static func recalculate_entities(objects: Array[Dictionary], entity_ids: Array[String], bindings: Array[Dictionary] = [], event_type: String = "power.entities_recalculated") -> Dictionary:
	return PowerControlResolverRef.apply_scoped_event(objects, bindings, {
		"event_type":event_type,
		"entity_ids":entity_ids.duplicate()
	})

static func apply_explicit_power_event(objects: Array[Dictionary], bindings: Array[Dictionary], event: Dictionary) -> Dictionary:
	return PowerControlResolverRef.apply_scoped_event(objects, bindings, event)

static func resolve_entity_power(objects: Array[Dictionary], entity_id: String, bindings: Array[Dictionary] = []) -> Dictionary:
	var world_result: Dictionary = PowerControlResolverRef.resolve_world(objects, bindings, {"entity_id":entity_id})
	return Dictionary(Dictionary(world_result.get("power_results", {})).get(entity_id, {})).duplicate(true)

static func resolve_entity_control(objects: Array[Dictionary], entity_id: String, bindings: Array[Dictionary] = []) -> Dictionary:
	var world_result: Dictionary = PowerControlResolverRef.resolve_world(objects, bindings, {"entity_id":entity_id})
	return Dictionary(Dictionary(world_result.get("control_results", {})).get(entity_id, {})).duplicate(true)

static func build_control_loss_patch(object_data: Dictionary, control_result: Dictionary) -> Dictionary:
	return PowerControlResolverRef.build_control_loss_patch(object_data, control_result)

static func power_mode_for(object_data: Dictionary) -> String:
	return PowerControlResolverRef.power_mode_for(object_data)

static func control_mode_for(object_data: Dictionary) -> String:
	return PowerControlResolverRef.control_mode_for(object_data)

static func control_loss_behavior_for(object_data: Dictionary) -> String:
	return PowerControlResolverRef.control_loss_behavior_for(object_data)
