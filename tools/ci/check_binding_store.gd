extends SceneTree
const BindingStoreRef = preload("res://scripts/world/binding_store.gd")
func _init() -> void:
	var store = BindingStoreRef.new()
	var added: Dictionary = store.add_binding("terminal_a", "door_a", "access")
	if not bool(added.get("ok", false)) or bool(added.get("created", false)) != true:
		quit(1); return
	store.add_binding("terminal_a", "door_a", "access")
	if store.get_bindings_for_source("terminal_a").size() != 1:
		quit(1); return
	if not store.remove_binding("terminal_a", "door_a", "access"):
		quit(1); return
	quit(0)
