extends RefCounted

static func merge(data: Dictionary, patch: Dictionary) -> Dictionary:
	var result: Dictionary = data.duplicate(true)
	for key: Variant in patch.keys():
		result[key] = patch[key]
	return result

static func make(instance_id: String, patch: Dictionary) -> Dictionary:
	return {"instance_id": instance_id, "patch": patch.duplicate(true)}

static func apply_all(repository: RefCounted, patches: Array) -> void:
	for value: Variant in patches:
		var info: Dictionary = Dictionary(value)
		var instance_id: String = str(info.get("instance_id", ""))
		var patch: Dictionary = Dictionary(info.get("patch", {}))
		if not instance_id.is_empty() and not patch.is_empty():
			repository.call("apply_patch", instance_id, patch)
