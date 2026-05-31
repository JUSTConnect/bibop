extends RefCounted
class_name RuntimeHud


static func hide_object_info(ui) -> void:
	if ui.runtime_object_info_panel != null and is_instance_valid(ui.runtime_object_info_panel):
		ui.runtime_object_info_panel.queue_free()
	ui.runtime_object_info_panel = null
	ui.runtime_object_info_cell = Vector2i(-1, -1)


static func clear_object_info(ui) -> void:
	hide_object_info(ui)


static func show_object_info(ui, cell: Vector2i) -> void:
	hide_object_info(ui)
	if ui.runtime_hud_root == null or not is_instance_valid(ui.runtime_hud_root):
		return
	if ui.field_runtime == null or not is_instance_valid(ui.field_runtime) or ui.bipob == null or not is_instance_valid(ui.bipob):
		return
	if ui.mission_manager_runtime == null or not is_instance_valid(ui.mission_manager_runtime):
		return
	RuntimeObjectHud.build(ui, cell)
