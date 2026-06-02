extends RefCounted
class_name CenterScreen

const RuntimeMissionMenuRef = preload("res://scripts/ui/runtime/runtime_mission_menu.gd")


static func build(ui) -> Control:
	var center_root: Control = ui.center_menu_root
	var background := PanelContainer.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui._apply_panel_style(background, true)
	center_root.add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	background.add_child(margin)

	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 16)
	margin.add_child(root)

	var top_row := HFlowContainer.new()
	top_row.add_theme_constant_override("separation", 8)
	top_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(top_row)
	top_row.add_child(ui._create_menu_button("TSK", Callable(ui, "_on_center_tasks_pressed"), Vector2(170, 36)))
	top_row.add_child(ui._create_menu_button("Constructor", Callable(ui, "_on_center_constructor_pressed"), Vector2(170, 36)))
	var top_spacer := Control.new()
	top_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(top_spacer)
	var top_right := VBoxContainer.new()
	top_right.add_theme_constant_override("separation", 8)
	top_right.add_child(ui._create_menu_button("Menu", Callable(ui, "_on_center_menu_pressed"), Vector2(220, 36)))
	top_row.add_child(top_right)

	var middle_row := HBoxContainer.new()
	middle_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(middle_row)
	var middle_spacer := Control.new()
	middle_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	middle_row.add_child(middle_spacer)
	middle_row.add_child(ui._create_menu_button("Shop", Callable(ui, "_on_center_shop_pressed"), Vector2(170, 56)))

	var bottom_grid := GridContainer.new()
	bottom_grid.columns = 4
	bottom_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_grid.add_theme_constant_override("h_separation", 10)
	bottom_grid.add_theme_constant_override("v_separation", 10)
	root.add_child(bottom_grid)
	bottom_grid.add_child(ui._create_menu_button("Box", Callable(ui, "_on_center_box_pressed"), Vector2(150, 54)))
	bottom_grid.add_child(ui._create_menu_button("Shop", Callable(ui, "_on_center_shop_pressed"), Vector2(150, 54)))
	bottom_grid.add_child(ui._create_menu_button("Charge", Callable(ui, "_on_center_charge_pressed"), Vector2(150, 54)))
	bottom_grid.add_child(ui._create_menu_button("Research", Callable(ui, "_on_center_research_pressed"), Vector2(150, 54)))
	bottom_grid.add_child(ui._create_menu_button("Repair", Callable(ui, "_on_center_repair_pressed"), Vector2(150, 54)))
	bottom_grid.add_child(ui._create_menu_button("Programmer", Callable(ui, "_on_center_programmer_pressed"), Vector2(150, 54)))

	ui.center_menu_overlay = RuntimeMissionMenuRef.build_overlay(ui, center_root, 24.0, false)
	return center_root


static func refresh(_ui) -> void:
	pass


static func show_menu(ui) -> void:
	RuntimeMissionMenuRef.open_overlay(ui.center_menu_overlay)
