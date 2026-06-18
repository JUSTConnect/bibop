extends RefCounted

# Target class: PalettePanelPresenter
# Refreshes palette state without rebuilding unrelated UI.

static func refresh(panel: Control, view_model: Dictionary) -> void:
	if panel == null or not is_instance_valid(panel):
		return
	panel.set_meta("last_palette_view_model", view_model)
