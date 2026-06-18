extends RefCounted

# Target class: ConstructorMutationService
# Единая точка изменения данных в map constructor.

var repository: RefCounted = null

func apply_entity_patch(entity_kind: String, entity_id: String, patch: Dictionary) -> Dictionary:
	if repository != null and entity_kind == "world_object" and repository.has_method("apply_object_patch"):
		return repository.call("apply_object_patch", entity_id, patch)
	if repository != null and entity_kind == "item" and repository.has_method("apply_item_patch"):
		return repository.call("apply_item_patch", entity_id, patch)
	return {"ok": false, "message": "Unsupported entity patch."}
