extends RefCounted
class_name RuntimeHud


static func hide_object_info(ui) -> void:
	RuntimeObjectHud.hide(ui)


static func clear_object_info(ui) -> void:
	RuntimeObjectHud.clear(ui)


static func show_object_info(ui, cell: Vector2i) -> void:
	RuntimeObjectHud.show(ui, cell)


static func refresh_object_info_position(ui) -> void:
	RuntimeObjectHud.refresh_position(ui)
