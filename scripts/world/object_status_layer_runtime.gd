extends ObjectStatusLayerService
class_name ObjectStatusLayerRuntimeService

const SECTION_NAME := "UnifiedObjectStatusLayerSection"

func _process(_delta: float) -> void:
	var ui: Object = _get_game_ui()
	if ui == null or not is_instance_valid(ui):
		return
	var manager: Object = ui.get("mission_manager_runtime") as Object
	if manager == null or not is_instance_valid(manager):
		return
	decorate_current_inspector(ui, manager)

func _get_game_ui() -> Object:
	if get_tree() == null:
		return null
	var scene: Node = get_tree().current_scene
	if scene != null:
		var direct_ui: Node = scene.get_node_or_null("UI")
		if _looks_like_game_ui(direct_ui):
			return direct_ui
		if _looks_like_game_ui(scene):
			return scene
	return null

func _looks_like_game_ui(node: Object) -> bool:
	return node != null and _has_property(node, "runtime_map_constructor_inspector_panel") and _has_property(node, "mission_manager_runtime")

func _has_property(target: Object, property_name: String) -> bool:
	if target == null:
		return false
	for property_data in target.get_property_list():
		if str(property_data.get("name", "")) == property_name:
			return true
	return false
