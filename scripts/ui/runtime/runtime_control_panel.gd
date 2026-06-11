extends RefCounted
class_name RuntimeControlPanel

const RuntimeInteractionPresenterRef = preload("res://scripts/ui/runtime/runtime_interaction_presenter.gd")


static func build(ui, bridge = null) -> Control:
	var panel := PanelContainer.new()
	panel.name = "RuntimeControlsPanel"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(0, 88)
	panel.add_theme_stylebox_override("panel", ui._make_panel_style(ui.UI_COLOR_PANEL_DARK, ui.UI_COLOR_BORDER_DIM, 1, 6))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin)

	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 6)
	margin.add_child(root)

	ui.runtime_interaction_actions_row = HBoxContainer.new()
	ui.runtime_interaction_actions_row.name = "RuntimeInteractionActionRow"
	ui.runtime_interaction_actions_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ui.runtime_interaction_actions_row.add_theme_constant_override("separation", 8)
	ui.runtime_interaction_actions_row.visible = false
	root.add_child(ui.runtime_interaction_actions_row)

	var grid := GridContainer.new()
	grid.name = "RuntimeBaseControlRow"
	grid.columns = 7
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 4)
	root.add_child(grid)
	ui.runtime_base_controls_grid = grid

	var callback_owner: Object = bridge if bridge != null else ui
	ui.runtime_move_forward_button = ui._create_runtime_control_button("Forward", Callable(callback_owner, "on_move_forward_pressed") if bridge != null else Callable(ui, "_on_move_forward_pressed"))
	ui.runtime_move_forward_button.visible = false
	grid.add_child(ui.runtime_move_forward_button)
	ui.runtime_move_backward_button = ui._create_runtime_control_button("Back", Callable(callback_owner, "on_move_backward_pressed") if bridge != null else Callable(ui, "_on_move_backward_pressed"))
	ui.runtime_move_backward_button.visible = false
	grid.add_child(ui.runtime_move_backward_button)
	ui.runtime_turn_left_button = ui._create_runtime_control_button("L", Callable(callback_owner, "on_turn_left_pressed") if bridge != null else Callable(ui, "_on_turn_left_pressed"))
	grid.add_child(ui.runtime_turn_left_button)
	ui.runtime_turn_right_button = ui._create_runtime_control_button("R", Callable(callback_owner, "on_turn_right_pressed") if bridge != null else Callable(ui, "_on_turn_right_pressed"))
	grid.add_child(ui.runtime_turn_right_button)
	ui.runtime_action_button = ui._create_runtime_control_button("Act", Callable(callback_owner, "on_action_pressed") if bridge != null else Callable(ui, "_on_interact_pressed"), "primary")
	grid.add_child(ui.runtime_action_button)
	ui.runtime_connect_button = ui._create_runtime_control_button("Connect", Callable(callback_owner, "on_connect_pressed") if bridge != null else Callable(ui, "_on_connect_pressed"), "primary")
	grid.add_child(ui.runtime_connect_button)
	ui.runtime_heavy_claw_button = ui._create_runtime_control_button("Claw", Callable(callback_owner, "on_heavy_claw_pressed") if bridge != null else Callable(ui, "_on_heavy_claw_pressed"), "primary")
	grid.add_child(ui.runtime_heavy_claw_button)
	ui.runtime_repair_button = ui._create_runtime_control_button("Repair", Callable(callback_owner, "on_repair_pressed") if bridge != null else Callable(ui, "_on_runtime_repair_pressed"), "primary")
	grid.add_child(ui.runtime_repair_button)
	ui.runtime_end_turn_button = ui._create_runtime_control_button("End", Callable(callback_owner, "on_end_turn_pressed") if bridge != null else Callable(ui, "_on_end_turn_pressed"), "reference")
	grid.add_child(ui.runtime_end_turn_button)
	refresh(ui)

	return panel


static func refresh(ui) -> void:
	RuntimeInteractionPresenterRef.refresh(ui)
