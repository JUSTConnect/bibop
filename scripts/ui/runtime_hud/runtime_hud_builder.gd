extends RefCounted

# Target class: RuntimeHudBuilder
# Builds RuntimeHudRoot once from RuntimeHudViewModel.

static func build(_view_model: Dictionary) -> Control:
	var root := Control.new()
	root.name = "RuntimeHudRoot"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bottom_left := VBoxContainer.new()
	bottom_left.name = "RuntimeBottomLeft"
	root.add_child(bottom_left)
	var stats := HBoxContainer.new()
	stats.name = "RuntimeStatsStrip"
	bottom_left.add_child(stats)
	var controls := HBoxContainer.new()
	controls.name = "RuntimeControlsPanel"
	bottom_left.add_child(controls)
	return root
