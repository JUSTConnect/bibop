extends Node

# Target class: MapConstructorRuntime
# Coordinator for map edit mode. Не строит UI напрямую.

var map_edit_state: RefCounted = null
var mutation_service: RefCounted = null
var validation_system: RefCounted = null

func select_entity(_entity_kind: String, _entity_id: String) -> void:
	pass

func apply_edit_command(_command: Dictionary) -> Dictionary:
	return {"ok": true, "message": "Edit command accepted."}
