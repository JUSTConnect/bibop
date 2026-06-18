extends RefCounted

# Target class: ObjectInspectorPresenter
# Refreshes existing inspector values without rebuilding tree unnecessarily.

static func refresh(panel: Control, view_model: Dictionary) -> void:
	if panel == null or not is_instance_valid(panel):
		return
	panel.set_meta("last_object_inspector_view_model", view_model)
