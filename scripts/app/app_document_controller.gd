extends "res://scripts/app/app_controller.gd"

const MapDocumentStoreRef = preload("res://scripts/map_constructor/map_document_store.gd")
const FirstPlayableTestRoomRef = preload("res://scripts/systems/first_playable_test_room.gd")

func _save_snapshot() -> void:
	var result: Dictionary = MapDocumentStoreRef.save_document(map_edit_state.make_snapshot())
	_set_status(str(result.get("message", "Save failed.")))

func _load_snapshot() -> void:
	var result: Dictionary = MapDocumentStoreRef.load_document()
	if not bool(result.get("ok", false)):
		_set_status(str(result.get("message", "Load failed.")))
		return
	map_edit_state.load_snapshot(Dictionary(result.get("snapshot", {})))
	_sync_loaded_state()
	_set_status(str(result.get("message", "Map loaded.")))

func load_test_room() -> void:
	map_edit_state.load_snapshot(FirstPlayableTestRoomRef.make_snapshot(definitions_by_id))
	_sync_loaded_state()
	_set_status("Test room loaded: Power Source -> Terminal -> Door.")

func _sync_loaded_state() -> void:
	_ensure_selected_definition_is_valid()
	_sync_selected_index_from_state()
	_update_selected_palette_label()
	_update_tool_mode_label()
	_refresh_after_world_change()
