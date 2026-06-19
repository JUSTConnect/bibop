extends RefCounted

const ObjectInteractionSystemRef = preload("res://scripts/systems/object_interaction_system.gd")
const ObjectPowerSystemRef = preload("res://scripts/systems/object_power_system.gd")

func use_object(selected_data: Dictionary, objects: Array[Dictionary]) -> Dictionary:
	return ObjectInteractionSystemRef.use_object(selected_data, objects)

func evaluate_world(objects: Array[Dictionary]) -> Array[Dictionary]:
	var patches: Array[Dictionary] = []
	for value: Variant in ObjectPowerSystemRef.evaluate_all(objects):
		patches.append(Dictionary(value))
	return patches

func apply_patches(map_editor: RefCounted, patches: Array) -> void:
	for value: Variant in patches:
		var info: Dictionary = Dictionary(value)
		var instance_id: String = str(info.get("instance_id", ""))
		var patch: Dictionary = Dictionary(info.get("patch", {}))
		if not instance_id.is_empty() and not patch.is_empty():
			map_editor.call("apply_runtime_patch", instance_id, patch)
