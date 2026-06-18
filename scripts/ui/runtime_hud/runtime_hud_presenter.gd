extends RefCounted

# Target class: RuntimeHudPresenter
# Refreshes HUD values. Does not rebuild layout every tick.

static func refresh(root: Control, view_model: Dictionary) -> void:
	if root == null or not is_instance_valid(root):
		return
	root.set_meta("last_runtime_hud_view_model", view_model)
