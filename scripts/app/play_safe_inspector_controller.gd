extends "res://scripts/app/object_inspector_controller.gd"

func apply_row_update(row: Dictionary, value: Variant) -> void:
	if str(map_editor.call("app_mode")) != "edit":
		_emit_status("Object configuration is locked in Play mode.")
		return
	super.apply_row_update(row, value)
