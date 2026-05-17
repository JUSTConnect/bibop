extends CanvasLayer
class_name GameUI

@onready var bipob = get_node("../Bipob")

@onready var status_label: Label = $StatusLabel
@onready var hint_label: Label = $HintLabel
@onready var command_panel: PanelContainer = $CommandPanel
@onready var box_screen: Control = $BoxScreen

var diagnostic_label: Label

@onready var box_status_label: Label = $BoxScreen/PanelContainer/VBoxContainer/StatusLabel
@onready var box_module_label: Label = $BoxScreen/PanelContainer/VBoxContainer/ModuleLabel
@onready var installed_modules_label: Label = $BoxScreen/PanelContainer/VBoxContainer/InstalledModulesLabel
var box_storage_label: Label
var digital_storage_label: Label
@onready var charge_button: Button = $BoxScreen/PanelContainer/VBoxContainer/ButtonRow/ChargeButton
@onready var install_module_button: Button = $BoxScreen/PanelContainer/VBoxContainer/ButtonRow/InstallModuleButton
@onready var start_mission_button: Button = $BoxScreen/PanelContainer/VBoxContainer/ButtonRow/StartMissionButton
var remove_module_button: Button

@onready var box_title_label: Label = $BoxScreen/PanelContainer/VBoxContainer/TitleLabel
var box_content_scroll: ScrollContainer = null
var box_content_label: Label = null
var right_button_panel: VBoxContainer = null
var main_box_row: HBoxContainer = null
var left_panel: VBoxContainer = null

@onready var move_forward_button: Button = $CommandPanel/CommandList/MoveForwardButton
@onready var move_backward_button: Button = $CommandPanel/CommandList/MoveBackwardButton
@onready var turn_left_button: Button = $CommandPanel/CommandList/TurnLeftButton
@onready var turn_right_button: Button = $CommandPanel/CommandList/TurnRightButton
@onready var interact_button: Button = $CommandPanel/CommandList/InteractButton
@onready var end_turn_button: Button = $CommandPanel/CommandList/EndTurnButton

var scan_device_button: Button
var hack_device_button: Button
var restart_mission_button: Button
var return_to_box_button: Button
var drop_item_button: Button
var rotate_storage_button: Button
var start_mission_warning_acknowledged: bool = false
var should_advance_mission_on_start: bool = false
var selected_installed_module_index: int = 0
var selected_box_storage_index: int = 0
var prev_installed_button: Button
var next_installed_button: Button
var prev_box_button: Button
var next_box_button: Button
var box_tab_row: HBoxContainer = null
var mission_tab_button: Button
var modules_tab_button: Button
var external_tab_button: Button
var internal_tab_button: Button
var box_restart_button: Button
var box_return_button: Button

enum BoxMenuMode {
	MISSION,
	MODULES,
	EXTERNAL,
	INTERNAL
}

var box_menu_mode: BoxMenuMode = BoxMenuMode.MISSION
var selected_external_side_index: int = 1
var selected_external_slot_position: Vector2i = Vector2i(1, 1)

func _configure_box_layout() -> void:
	if box_screen == null:
		return
	var panel: PanelContainer = box_screen.get_node_or_null("PanelContainer")
	var vbox: VBoxContainer = box_screen.get_node_or_null("PanelContainer/VBoxContainer")
	if panel == null or vbox == null:
		return
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.offset_left = -540
	panel.offset_top = 16
	panel.offset_right = -16
	panel.offset_bottom = 632
	panel.custom_minimum_size = Vector2(520, 0)

	main_box_row = vbox.get_node_or_null("MainBoxRow")
	if main_box_row == null:
		main_box_row = HBoxContainer.new()
		main_box_row.name = "MainBoxRow"
		vbox.add_child(main_box_row)

	left_panel = vbox.get_node_or_null("MainBoxRow/LeftPanel")
	if left_panel == null:
		left_panel = VBoxContainer.new()
		left_panel.name = "LeftPanel"
		main_box_row.add_child(left_panel)
	left_panel.custom_minimum_size = Vector2(350, 0)
	left_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	if box_title_label != null:
		box_title_label.reparent(left_panel)

	box_tab_row = left_panel.get_node_or_null("BoxTabRow")
	if box_tab_row == null:
		box_tab_row = HBoxContainer.new()
		box_tab_row.name = "BoxTabRow"
		left_panel.add_child(box_tab_row)
	box_tab_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	box_content_scroll = left_panel.get_node_or_null("BoxContentScroll")
	if box_content_scroll == null:
		box_content_scroll = ScrollContainer.new()
		box_content_scroll.name = "BoxContentScroll"
		left_panel.add_child(box_content_scroll)
	box_content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box_content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box_content_scroll.custom_minimum_size = Vector2(320, 340)

	box_content_label = box_content_scroll.get_node_or_null("BoxContentLabel")
	if box_content_label == null:
		box_content_label = Label.new()
		box_content_label.name = "BoxContentLabel"
		box_content_scroll.add_child(box_content_label)
	box_content_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box_content_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	if box_status_label != null:
		box_status_label.visible = false
		box_status_label.text = ""
	if box_module_label != null:
		box_module_label.visible = false
		box_module_label.text = ""
	if installed_modules_label != null:
		installed_modules_label.visible = false
		installed_modules_label.text = ""
	if box_storage_label != null:
		box_storage_label.visible = false
		box_storage_label.text = ""
	if digital_storage_label != null:
		digital_storage_label.visible = false
		digital_storage_label.text = ""

	var old_button_row := vbox.get_node_or_null("ButtonRow")
	if old_button_row != null:
		old_button_row.visible = false
		for child in old_button_row.get_children():
			child.queue_free()

	for row_name in ["InstalledButtonRow", "BoxStorageButtonRow", "MissionButtonRow"]:
		var old_row := vbox.get_node_or_null(row_name)
		if old_row != null:
			old_row.visible = false
			for child in old_row.get_children():
				child.queue_free()

	right_button_panel = main_box_row.get_node_or_null("RightButtonPanel")
	if right_button_panel == null:
		right_button_panel = VBoxContainer.new()
		right_button_panel.name = "RightButtonPanel"
		main_box_row.add_child(right_button_panel)
	right_button_panel.custom_minimum_size = Vector2(140, 0)
	right_button_panel.size_flags_horizontal = Control.SIZE_SHRINK_END
	right_button_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

func get_short_module_name(module: BipobModule) -> String:
	if module == null:
		return "empty"
	return bipob.get_module_display_name(module)

func get_selected_installed_module_text() -> String:
	if bipob == null or bipob.installed_modules.is_empty():
		return "Selected installed: none"
	clamp_box_selection_indexes()
	var module: BipobModule = bipob.installed_modules[selected_installed_module_index]
	return "Selected installed: " + get_short_module_name(module)

func get_selected_box_module_text() -> String:
	if bipob == null or bipob.box_storage.is_empty():
		return "Selected box: none"
	clamp_box_selection_indexes()
	var module: BipobModule = bipob.box_storage[selected_box_storage_index]
	return "Selected box: " + get_short_module_name(module)

func get_compact_module_window(modules: Array, selected_index: int, max_lines: int = 4) -> Array[String]:
	if modules.is_empty():
		return ["empty"]

	var total: int = modules.size()
	var safe_index: int = clampi(selected_index, 0, total - 1)
	var window_size: int = mini(max_lines, total)
	var start_idx: int = clampi(safe_index - int(window_size / 2), 0, total - window_size)
	var end_idx: int = start_idx + window_size - 1
	var lines: Array[String] = []

	if start_idx > 0:
		lines.append("... ")

	for index in range(start_idx, end_idx + 1):
		var marker := "  "
		if index == safe_index:
			marker = "> "
		lines.append("%s%s" % [marker, get_short_module_name(modules[index])])

	if end_idx < total - 1:
		lines.append("... ")

	return lines

func get_digital_storage_short_text() -> String:
	if bipob == null:
		return "Digital: empty"
	if bipob.has_method("get_digital_storage_short_text"):
		var short_text := str(bipob.get_digital_storage_short_text())
		if short_text.is_empty() or short_text == "empty":
			return "Digital: empty"
		return "Digital: %s" % short_text
	if bipob.has_method("get_digital_storage_text"):
		var full_text := str(bipob.get_digital_storage_text())
		if full_text.begins_with("Digital storage:\n- "):
			var list_text := full_text.trim_prefix("Digital storage:\n- ").replace("\n- ", ", ")
			if list_text.is_empty():
				return "Digital: empty"
			return "Digital: %s" % list_text
		if full_text.begins_with("Digital storage: "):
			var one_line := full_text.trim_prefix("Digital storage: ")
			if one_line.is_empty() or one_line == "empty":
				return "Digital: empty"
			return "Digital: %s" % one_line
	return "Digital: empty"

func _ready() -> void:
	if status_label != null:
		status_label.position = Vector2(100, 20)
	if hint_label != null:
		hint_label.position = Vector2(100, 50)
		hint_label.text = "Mission 1: pick up the key, open the door, reach the exit."

	diagnostic_label = Label.new()
	diagnostic_label.name = "DiagnosticLabel"
	diagnostic_label.position = Vector2(100, 80)
	diagnostic_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	diagnostic_label.custom_minimum_size = Vector2(700, 140)
	diagnostic_label.text = "Diagnostic: none"
	add_child(diagnostic_label)

	if command_panel != null:
		command_panel.position = Vector2(850, 80)
		command_panel.custom_minimum_size = Vector2(220, 260)

	if box_screen != null:
		box_screen.visible = false
	if command_panel != null:
		command_panel.visible = true
	_configure_box_layout()

	if box_storage_label == null:
		box_storage_label = Label.new()
		box_storage_label.name = "BoxStorageLabel"
		box_storage_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var box_vbox := box_screen.get_node_or_null("PanelContainer/VBoxContainer")
		if box_vbox != null:
			box_vbox.add_child(box_storage_label)
			if start_mission_button != null:
				box_vbox.move_child(box_storage_label, start_mission_button.get_index())

	if digital_storage_label == null:
		digital_storage_label = Label.new()
		digital_storage_label.name = "DigitalStorageLabel"
		digital_storage_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var digital_box_vbox := box_screen.get_node_or_null("PanelContainer/VBoxContainer")
		if digital_box_vbox != null:
			digital_box_vbox.add_child(digital_storage_label)
			if start_mission_button != null:
				digital_box_vbox.move_child(digital_storage_label, start_mission_button.get_index())

	if move_forward_button != null:
		move_forward_button.focus_mode = Control.FOCUS_NONE
	if move_backward_button != null:
		move_backward_button.focus_mode = Control.FOCUS_NONE
	if turn_left_button != null:
		turn_left_button.focus_mode = Control.FOCUS_NONE
	if turn_right_button != null:
		turn_right_button.focus_mode = Control.FOCUS_NONE
	if interact_button != null:
		interact_button.focus_mode = Control.FOCUS_NONE
	if end_turn_button != null:
		end_turn_button.focus_mode = Control.FOCUS_NONE

	drop_item_button = Button.new()
	drop_item_button.name = "DropItemButton"
	drop_item_button.text = "Drop Item"
	drop_item_button.focus_mode = Control.FOCUS_NONE

	rotate_storage_button = Button.new()
	rotate_storage_button.name = "RotateStorageButton"
	rotate_storage_button.text = "Rotate Storage"
	rotate_storage_button.focus_mode = Control.FOCUS_NONE

	scan_device_button = Button.new()
	scan_device_button.name = "ScanDeviceButton"
	scan_device_button.text = "Scan Device"
	scan_device_button.focus_mode = Control.FOCUS_NONE
	var command_list: Node = null
	if command_panel != null:
		command_list = command_panel.get_node_or_null("CommandList")
	if command_list != null:
		command_list.add_child(drop_item_button)
		drop_item_button.pressed.connect(_on_drop_item_button_pressed)
		command_list.add_child(rotate_storage_button)
		rotate_storage_button.pressed.connect(_on_rotate_storage_button_pressed)
		command_list.add_child(scan_device_button)
		scan_device_button.pressed.connect(_on_scan_device_button_pressed)
		hack_device_button = Button.new()
		hack_device_button.name = "HackDeviceButton"
		hack_device_button.text = "Hack Device"
		hack_device_button.focus_mode = Control.FOCUS_NONE
		command_list.add_child(hack_device_button)
		hack_device_button.pressed.connect(_on_hack_device_button_pressed)
		restart_mission_button = Button.new()
		restart_mission_button.name = "RestartMissionButton"
		restart_mission_button.text = "Restart Mission"
		restart_mission_button.focus_mode = Control.FOCUS_NONE
		command_list.add_child(restart_mission_button)
		restart_mission_button.pressed.connect(_on_restart_mission_button_pressed)
		return_to_box_button = Button.new()
		return_to_box_button.name = "ReturnToBoxButton"
		return_to_box_button.text = "Return to Box"
		return_to_box_button.focus_mode = Control.FOCUS_NONE
		command_list.add_child(return_to_box_button)
		return_to_box_button.pressed.connect(_on_return_to_box_button_pressed)

	if move_forward_button != null:
		move_forward_button.pressed.connect(_on_move_forward_pressed)
	if move_backward_button != null:
		move_backward_button.pressed.connect(_on_move_backward_pressed)
	if turn_left_button != null:
		turn_left_button.pressed.connect(_on_turn_left_pressed)
	if turn_right_button != null:
		turn_right_button.pressed.connect(_on_turn_right_pressed)
	if interact_button != null:
		interact_button.pressed.connect(_on_interact_pressed)
	if end_turn_button != null:
		end_turn_button.pressed.connect(_on_end_turn_pressed)

	if charge_button != null:
		charge_button.text = "Charge"
		charge_button.visible = false
		charge_button.focus_mode = Control.FOCUS_NONE
	if install_module_button != null:
		install_module_button.text = "Install"
		install_module_button.visible = false
		install_module_button.focus_mode = Control.FOCUS_NONE
	if start_mission_button != null:
		start_mission_button.text = "Start"
		start_mission_button.visible = false
		start_mission_button.focus_mode = Control.FOCUS_NONE

	remove_module_button = null

	prev_installed_button = null

	next_installed_button = null

	prev_box_button = null

	next_box_button = null

	mission_tab_button = Button.new()
	mission_tab_button.name = "MissionTabButton"
	mission_tab_button.text = "Mission"
	mission_tab_button.focus_mode = Control.FOCUS_NONE
	box_tab_row.add_child(mission_tab_button)
	mission_tab_button.pressed.connect(set_box_menu_mode_mission)

	modules_tab_button = Button.new()
	modules_tab_button.name = "ModulesTabButton"
	modules_tab_button.text = "Modules"
	modules_tab_button.focus_mode = Control.FOCUS_NONE
	box_tab_row.add_child(modules_tab_button)
	modules_tab_button.pressed.connect(set_box_menu_mode_modules)

	external_tab_button = Button.new()
	external_tab_button.name = "ExternalTabButton"
	external_tab_button.text = "External"
	external_tab_button.focus_mode = Control.FOCUS_NONE
	box_tab_row.add_child(external_tab_button)
	external_tab_button.pressed.connect(set_box_menu_mode_external)
	internal_tab_button = Button.new()
	internal_tab_button.name = "InternalTabButton"
	internal_tab_button.text = "Internal"
	internal_tab_button.focus_mode = Control.FOCUS_NONE
	box_tab_row.add_child(internal_tab_button)
	internal_tab_button.pressed.connect(set_box_menu_mode_internal)

	box_restart_button = null

	box_return_button = null

	bipob.status_changed.connect(update_status)
	bipob.hint_requested.connect(show_hint)
	bipob.mission_completed.connect(_on_mission_completed)
	bipob.returned_to_box.connect(_on_returned_to_box)

	update_status()
	rebuild_box_action_buttons()
	update_box_status()
	update_diagnostic_status()

func _on_charge_button_pressed() -> void:
	# BoxScreen preparation action: must not spend field action points or energy.
	bipob.charge_to_full()
	start_mission_warning_acknowledged = false
	update_status()
	update_box_status()
	update_diagnostic_status()

func _on_install_module_button_pressed() -> void:
	# BoxScreen preparation action: must not spend field action points or energy.
	_on_install_selected_box_module_pressed()

func clamp_box_selection_indexes() -> void:
	if bipob == null:
		selected_installed_module_index = 0
		selected_box_storage_index = 0
		return

	if bipob.installed_modules.is_empty():
		selected_installed_module_index = 0
	else:
		selected_installed_module_index = clampi(selected_installed_module_index, 0, bipob.installed_modules.size() - 1)

	if bipob.box_storage.is_empty():
		selected_box_storage_index = 0
	else:
		selected_box_storage_index = clampi(selected_box_storage_index, 0, bipob.box_storage.size() - 1)

func _on_prev_installed_pressed() -> void:
	if bipob == null:
		return
	if bipob.installed_modules.is_empty():
		show_hint("No installed modules.")
		return
	selected_installed_module_index -= 1
	if selected_installed_module_index < 0:
		selected_installed_module_index = bipob.installed_modules.size() - 1
	update_box_status()

func _on_next_installed_pressed() -> void:
	if bipob == null:
		return
	if bipob.installed_modules.is_empty():
		show_hint("No installed modules.")
		return
	selected_installed_module_index += 1
	if selected_installed_module_index >= bipob.installed_modules.size():
		selected_installed_module_index = 0
	update_box_status()

func _on_remove_selected_module_pressed() -> void:
	if bipob == null:
		return
	if bipob.installed_modules.is_empty():
		show_hint("No installed modules to remove.")
		return
	clamp_box_selection_indexes()
	bipob.remove_installed_module_to_box_by_index(selected_installed_module_index)
	start_mission_warning_acknowledged = false
	clamp_box_selection_indexes()
	update_status()
	update_box_status()
	update_diagnostic_status()

func _on_prev_box_pressed() -> void:
	if bipob == null:
		return
	if bipob.box_storage.is_empty():
		show_hint("Box storage is empty.")
		return
	selected_box_storage_index -= 1
	if selected_box_storage_index < 0:
		selected_box_storage_index = bipob.box_storage.size() - 1
	update_box_status()

func _on_next_box_pressed() -> void:
	if bipob == null:
		return
	if bipob.box_storage.is_empty():
		show_hint("Box storage is empty.")
		return
	selected_box_storage_index += 1
	if selected_box_storage_index >= bipob.box_storage.size():
		selected_box_storage_index = 0
	update_box_status()

func _on_install_selected_box_module_pressed() -> void:
	if bipob == null:
		return
	if bipob.box_storage.is_empty():
		show_hint("No module in Box Storage to install.")
		return
	clamp_box_selection_indexes()
	bipob.install_module_from_box_storage(selected_box_storage_index)
	start_mission_warning_acknowledged = false
	clamp_box_selection_indexes()
	update_status()
	update_box_status()
	update_diagnostic_status()

func _on_remove_module_button_pressed() -> void:
	_on_remove_selected_module_pressed()

func get_selected_external_side_id() -> String:
	if bipob == null:
		return ""
	if selected_external_side_index < 0:
		selected_external_side_index = 0
	if selected_external_side_index >= bipob.EXTERNAL_SIDE_ORDER.size():
		selected_external_side_index = 0
	return String(bipob.EXTERNAL_SIDE_ORDER[selected_external_side_index])

func clamp_external_selection() -> void:
	if bipob == null:
		return

	if selected_external_side_index < 0:
		selected_external_side_index = bipob.EXTERNAL_SIDE_ORDER.size() - 1
	elif selected_external_side_index >= bipob.EXTERNAL_SIDE_ORDER.size():
		selected_external_side_index = 0

	var side_id := get_selected_external_side_id()
	var side_size: Vector2i = bipob.get_external_side_size(side_id)
	selected_external_slot_position.x = clampi(selected_external_slot_position.x, 0, side_size.x - 1)
	selected_external_slot_position.y = clampi(selected_external_slot_position.y, 0, side_size.y - 1)

func get_external_module_marker(module: BipobModule) -> String:
	if module == null:
		return "M"
	match module.id:
		"wheels_v1":
			return "W"
		"legs_v1":
			return "L"
		"tracks_v1":
			return "T"
		"visor_v1", "visor_v2":
			return "V"
		"manipulator_v1":
			return "M"
		"interface_v1":
			return "I"
		_:
			var module_name: String = bipob.get_module_display_name(module).to_upper()
			if module_name.is_empty():
				return "M"
			return module_name.substr(0, 1)

func get_yes_no(value: bool) -> String:
	return "yes" if value else "no"

func get_selected_box_module_allowed_sides_text() -> String:
	if bipob == null or bipob.box_storage.is_empty():
		return "Allowed sides: n/a"
	clamp_box_selection_indexes()
	var module: BipobModule = bipob.box_storage[selected_box_storage_index]
	if module == null:
		return "Allowed sides: n/a"
	return "Allowed sides: %s" % bipob.get_allowed_external_sides_text(module)

func get_external_side_orientation_text(side_id: String) -> String:
	var lines: Array[String] = []
	match side_id:
		bipob.EXTERNAL_SIDE_TOP:
			lines.append("Orientation: FRONT ↑ / BACK ↓ / LEFT ← / RIGHT →")
		bipob.EXTERNAL_SIDE_BOTTOM:
			lines.append("Orientation: FRONT ↑ / BACK ↓ / LEFT ← / RIGHT →")
			lines.append("Note: viewed from outside bottom.")
		bipob.EXTERNAL_SIDE_FRONT:
			lines.append("Orientation: TOP ↑ / BOTTOM ↓ / LEFT ← / RIGHT →")
		bipob.EXTERNAL_SIDE_BACK:
			lines.append("Orientation: TOP ↑ / BOTTOM ↓ / RIGHT ← / LEFT →")
			lines.append("Note: viewed from outside back.")
		bipob.EXTERNAL_SIDE_LEFT:
			lines.append("Orientation: TOP ↑ / BOTTOM ↓ / FRONT ← / BACK →")
		bipob.EXTERNAL_SIDE_RIGHT:
			lines.append("Orientation: TOP ↑ / BOTTOM ↓ / BACK ← / FRONT →")
		_:
			lines.append("Orientation: n/a")
	return "\n".join(lines)

func get_external_side_installed_list_text(side_id: String) -> String:
	var side_size: Vector2i = bipob.get_external_side_size(side_id)
	var lines: Array[String] = []
	var seen_modules: Array[BipobModule] = []
	for y in range(side_size.y):
		for x in range(side_size.x):
			var module: BipobModule = bipob.get_external_module_at(side_id, Vector2i(x, y))
			if module == null or seen_modules.has(module):
				continue
			seen_modules.append(module)
			var origin := Vector2i(side_size.x, side_size.y)
			for yy in range(side_size.y):
				for xx in range(side_size.x):
					if bipob.get_external_module_at(side_id, Vector2i(xx, yy)) == module:
						origin.x = mini(origin.x, xx)
						origin.y = mini(origin.y, yy)
			var module_size: Vector2i = bipob.get_external_module_size(module)
			lines.append("- x%d,y%d: %s (%dx%d)" % [origin.x, origin.y, bipob.get_module_display_name(module), module_size.x, module_size.y])
	if lines.is_empty():
		return "none"
	return "\n".join(lines)

func _on_start_mission_button_pressed() -> void:
	if bipob == null:
		return

	# BoxScreen preparation action: starts mission flow without field action/energy spend.
	if bipob.sector_completed and should_advance_mission_on_start:
		bipob.start_next_mission()
		start_mission_warning_acknowledged = false
		update_status()
		update_box_status()
		update_diagnostic_status()
		return

	var warnings: Array[String] = bipob.get_pre_mission_warnings()
	if not bipob.can_start_mission_from_box():
		show_hint("Cannot start mission. Battery depleted. Charge first.")
		start_mission_warning_acknowledged = false
		update_box_status()
		return

	if not warnings.is_empty() and not start_mission_warning_acknowledged:
		start_mission_warning_acknowledged = true
		show_hint("Warnings before mission. Press Start Mission again to continue anyway.")
		update_box_status()
		return

	if should_advance_mission_on_start:
		bipob.start_next_mission()
	else:
		bipob.start_mission(bipob.current_mission_index)
	should_advance_mission_on_start = false
	start_mission_warning_acknowledged = false
	if not bipob.sector_completed:
		hide_box_screen()
	update_status()
	update_box_status()
	update_diagnostic_status()

func _on_mission_completed() -> void:
	should_advance_mission_on_start = true
	show_box_screen()
	update_box_status()

func _on_returned_to_box() -> void:
	should_advance_mission_on_start = false
	show_box_screen()
	update_box_status()

func show_box_screen() -> void:
	if box_screen != null:
		box_screen.visible = true
	if command_panel != null:
		command_panel.visible = false
	start_mission_warning_acknowledged = false
	update_box_status()
	
func hide_box_screen() -> void:
	if box_screen != null:
		box_screen.visible = false
	if command_panel != null:
		command_panel.visible = true
	update_status()
	update_box_status()
	update_diagnostic_status()
	
func update_box_status() -> void:
	if bipob == null:
		return

	clamp_box_selection_indexes()
	update_diagnostic_status()

	if box_title_label != null:
		if box_menu_mode == BoxMenuMode.MISSION:
			box_title_label.text = "Box / Garage — Mission"
		elif box_menu_mode == BoxMenuMode.EXTERNAL:
			box_title_label.text = "Box / Garage — External Constructor"
		elif box_menu_mode == BoxMenuMode.INTERNAL:
			box_title_label.text = "Box / Garage — Internal Constructor"
		else:
			box_title_label.text = "Box / Garage — Modules"

	var content_text: String
	if box_menu_mode == BoxMenuMode.MISSION:
		content_text = get_box_mission_menu_text()
	elif box_menu_mode == BoxMenuMode.EXTERNAL:
		content_text = get_box_external_menu_text()
	elif box_menu_mode == BoxMenuMode.INTERNAL:
		content_text = get_box_internal_menu_text()
	else:
		content_text = get_box_modules_menu_text()
	update_box_button_visibility()

	if box_content_label != null:
		box_content_label.text = content_text

func get_box_mission_menu_text() -> String:
	var content_lines: Array[String] = []
	var mission_name := "n/a"
	if bipob.has_method("get_mission_name"):
		mission_name = str(bipob.get_mission_name(bipob.current_mission_index))
	content_lines.append("Mission:")
	content_lines.append("Mission %d — %s" % [bipob.current_mission_index + 1, mission_name])
	content_lines.append("")
	content_lines.append("Energy:")
	content_lines.append("%d / %d" % [bipob.energy, bipob.max_energy])

	var warnings: Array = bipob.get_pre_mission_warnings()
	content_lines.append("")
	if warnings.is_empty():
		content_lines.append("Warnings: none")
	else:
		content_lines.append("Warnings:")
		var warning_limit := mini(2, warnings.size())
		for index in range(warning_limit):
			content_lines.append("- %s" % str(warnings[index]))
		if warnings.size() > warning_limit:
			content_lines.append("- ... +%d more" % (warnings.size() - warning_limit))

	var hand_text := "empty"
	if bipob.held_module != null:
		hand_text = bipob.get_module_display_name(bipob.held_module)
	var storage_text := "empty"
	if bipob.stored_physical_module != null:
		storage_text = bipob.get_module_display_name(bipob.stored_physical_module)
	content_lines.append("")
	content_lines.append("Carry:")
	content_lines.append("Hand: %s" % hand_text)
	content_lines.append("Robot storage: %s" % storage_text)
	content_lines.append("Carry: %d / %d" % [bipob.get_carried_physical_count(), bipob.physical_carry_capacity])

	content_lines.append("")
	content_lines.append(get_digital_storage_short_text())
	content_lines.append("")
	if bipob.found_module != null:
		content_lines.append("Found: %s" % bipob.get_module_display_name(bipob.found_module))
	else:
		content_lines.append("Found: none")
	content_lines.append("Box storage: %d modules" % bipob.box_storage.size())
	content_lines.append("Installed: %d modules" % bipob.installed_modules.size())
	return "\n".join(content_lines)

func get_box_modules_menu_text() -> String:
	var content_lines: Array[String] = []
	content_lines.append(get_selected_installed_module_text())
	content_lines.append("")
	content_lines.append("Installed modules (%d):" % bipob.installed_modules.size())
	content_lines.append_array(get_compact_module_window(bipob.installed_modules, selected_installed_module_index, 5))
	content_lines.append("")
	content_lines.append(get_selected_box_module_text())
	content_lines.append("")
	content_lines.append("Box storage (%d):" % bipob.box_storage.size())
	content_lines.append_array(get_compact_module_window(bipob.box_storage, selected_box_storage_index, 5))
	content_lines.append("")
	content_lines.append("External build: %d module(s)" % bipob.external_modules_by_slot.size())
	return "\n".join(content_lines)

func get_box_external_menu_text() -> String:
	clamp_external_selection()
	var side_id := get_selected_external_side_id()
	var side_size: Vector2i = bipob.get_external_side_size(side_id)
	var side_name: String = bipob.get_external_side_display_name(side_id)
	var slot_module: BipobModule = bipob.get_external_module_at(side_id, selected_external_slot_position)
	var content_lines: Array[String] = []

	var selected_box_module: BipobModule = null
	if not bipob.box_storage.is_empty():
		clamp_box_selection_indexes()
		selected_box_module = bipob.box_storage[selected_box_storage_index]

	var placement_error := ""
	var preview_footprint: Array[Vector2i] = []
	var preview_safe_area: Array[Vector2i] = []
	if selected_box_module != null:
		preview_footprint = bipob.get_external_module_footprint_cells(selected_box_module, selected_external_slot_position)
		preview_safe_area = bipob.get_external_module_safe_area_cells(selected_box_module, selected_external_slot_position)
		placement_error = bipob.get_external_module_placement_error(selected_box_module, side_id, selected_external_slot_position)

	content_lines.append("Selected side: %s" % side_name)
	content_lines.append("Side size: %d x %d" % [side_size.x, side_size.y])
	content_lines.append(get_external_side_orientation_text(side_id))
	content_lines.append("")

	var header_cells: Array[String] = ["   "]
	for x in range(side_size.x):
		header_cells.append("x%d" % x)
	content_lines.append("  ".join(header_cells))
	for y in range(side_size.y):
		var row_cells: Array[String] = ["y%d" % y]
		for x in range(side_size.x):
			var slot_pos := Vector2i(x, y)
			var module: BipobModule = bipob.get_external_module_at(side_id, slot_pos)
			var is_selected: bool = slot_pos == selected_external_slot_position
			var has_footprint_preview := selected_box_module != null and preview_footprint.has(slot_pos)
			var has_safe_preview := selected_box_module != null and preview_safe_area.has(slot_pos)
			var cell_text := "[ ]"
			if has_safe_preview:
				cell_text = "[.]" if module == null else "[x]"
			if module != null:
				cell_text = "[%s]" % get_external_module_marker(module)
			if has_footprint_preview:
				cell_text = "[+]" if module == null else "[!]"
			if is_selected and selected_box_module == null:
				cell_text = "[>]" if module == null else "[>%s]" % get_external_module_marker(module)
			row_cells.append(cell_text)
		content_lines.append(" ".join(row_cells))

	content_lines.append("")
	content_lines.append("Selected slot: x=%d, y=%d" % [selected_external_slot_position.x, selected_external_slot_position.y])
	if slot_module == null:
		content_lines.append("Slot status: empty")
	else:
		content_lines.append("Slot status: %s" % bipob.get_module_display_name(slot_module))

	if selected_box_module == null:
		content_lines.append("Selected Box module: none")
		content_lines.append("Module size: n/a")
		content_lines.append("Allowed sides: n/a")
		content_lines.append("Placement: n/a")
	else:
		var module_size: Vector2i = bipob.get_external_module_size(selected_box_module)
		content_lines.append("Selected Box module: %s" % bipob.get_module_display_name(selected_box_module))
		content_lines.append("Module size: %d x %d" % [module_size.x, module_size.y])
		content_lines.append("Allowed sides: %s" % bipob.get_allowed_external_sides_text(selected_box_module))
		if placement_error.is_empty():
			content_lines.append("Placement: valid")
		else:
			content_lines.append("Placement: invalid — %s" % placement_error)

	content_lines.append("")
	content_lines.append("Installed on %s:" % side_name)
	content_lines.append(get_external_side_installed_list_text(side_id))
	content_lines.append("")
	content_lines.append(bipob.get_external_build_summary_text())

	return "\n".join(content_lines)

func _add_box_action_button(button_text: String, handler: Callable) -> void:
	if right_button_panel == null:
		return
	var button := Button.new()
	button.text = button_text
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_button_panel.add_child(button)
	button.pressed.connect(handler)

func rebuild_box_action_buttons() -> void:
	if right_button_panel == null:
		return
	for child in right_button_panel.get_children():
		child.queue_free()

	var actions_label := Label.new()
	actions_label.name = "ActionsLabel"
	actions_label.text = "Actions"
	right_button_panel.add_child(actions_label)

	if box_menu_mode == BoxMenuMode.MISSION:
		_add_box_action_button("Charge", Callable(self, "_on_charge_button_pressed"))
		_add_box_action_button("Start", Callable(self, "_on_start_mission_button_pressed"))
		_add_box_action_button("Restart", Callable(self, "_on_restart_mission_button_pressed"))
	elif box_menu_mode == BoxMenuMode.EXTERNAL:
		_add_box_action_button("Prev Side", Callable(self, "_on_prev_external_side_pressed"))
		_add_box_action_button("Next Side", Callable(self, "_on_next_external_side_pressed"))
		_add_box_action_button("Prev Slot", Callable(self, "_on_prev_external_slot_pressed"))
		_add_box_action_button("Next Slot", Callable(self, "_on_next_external_slot_pressed"))
		right_button_panel.add_spacer(false)
		_add_box_action_button("Place", Callable(self, "_on_place_external_module_pressed"))
		_add_box_action_button("Remove", Callable(self, "_on_remove_external_module_pressed"))
	elif box_menu_mode == BoxMenuMode.INTERNAL:
		_add_box_action_button("Prev Internal Box", Callable(self, "_on_prev_internal_box_pressed"))
		_add_box_action_button("Next Internal Box", Callable(self, "_on_next_internal_box_pressed"))
		right_button_panel.add_spacer(false)
		_add_box_action_button("X-", Callable(self, "_on_internal_x_minus_pressed"))
		_add_box_action_button("X+", Callable(self, "_on_internal_x_plus_pressed"))
		_add_box_action_button("Y-", Callable(self, "_on_internal_y_minus_pressed"))
		_add_box_action_button("Y+", Callable(self, "_on_internal_y_plus_pressed"))
		_add_box_action_button("Z-", Callable(self, "_on_internal_z_minus_pressed"))
		_add_box_action_button("Z+", Callable(self, "_on_internal_z_plus_pressed"))
		right_button_panel.add_spacer(false)
		_add_box_action_button("Rotate Internal", Callable(self, "_on_rotate_internal_pressed"))
		_add_box_action_button("Place Internal", Callable(self, "_on_place_internal_pressed"))
		_add_box_action_button("Remove Internal", Callable(self, "_on_remove_internal_pressed"))
		_add_box_action_button("Reset Internal Cursor", Callable(self, "_on_reset_internal_cursor_pressed"))
	else:
		_add_box_action_button("Remove", Callable(self, "_on_remove_selected_module_pressed"))
		_add_box_action_button("Prev Inst", Callable(self, "_on_prev_installed_pressed"))
		_add_box_action_button("Next Inst", Callable(self, "_on_next_installed_pressed"))
		right_button_panel.add_spacer(false)
		_add_box_action_button("Install", Callable(self, "_on_install_selected_box_module_pressed"))
		_add_box_action_button("Prev Box", Callable(self, "_on_prev_box_pressed"))
		_add_box_action_button("Next Box", Callable(self, "_on_next_box_pressed"))

func update_box_button_visibility() -> void:
	var is_mission := box_menu_mode == BoxMenuMode.MISSION
	var is_modules := box_menu_mode == BoxMenuMode.MODULES
	var is_external := box_menu_mode == BoxMenuMode.EXTERNAL
	var is_internal := box_menu_mode == BoxMenuMode.INTERNAL
	if mission_tab_button != null:
		mission_tab_button.disabled = is_mission
	if modules_tab_button != null:
		modules_tab_button.disabled = is_modules
	if external_tab_button != null:
		external_tab_button.disabled = is_external
	if internal_tab_button != null:
		internal_tab_button.disabled = is_internal

func set_box_menu_mode_mission() -> void:
	box_menu_mode = BoxMenuMode.MISSION
	update_box_status()
	rebuild_box_action_buttons()

func set_box_menu_mode_modules() -> void:
	box_menu_mode = BoxMenuMode.MODULES
	update_box_status()
	rebuild_box_action_buttons()

func set_box_menu_mode_external() -> void:
	box_menu_mode = BoxMenuMode.EXTERNAL
	clamp_external_selection()
	update_box_status()
	rebuild_box_action_buttons()


func set_box_menu_mode_internal() -> void:
	box_menu_mode = BoxMenuMode.INTERNAL
	update_box_status()
	rebuild_box_action_buttons()

func _get_internal_box_modules() -> Array[BipobModule]:
	var internal_modules: Array[BipobModule] = []
	for module in bipob.box_storage:
		if bipob.is_internal_module(module):
			internal_modules.append(module)
	return internal_modules

func _clamp_internal_selection() -> void:
	var modules := _get_internal_box_modules()
	if modules.is_empty():
		bipob.selected_internal_box_index = 0
	else:
		bipob.selected_internal_box_index = clampi(bipob.selected_internal_box_index, 0, modules.size() - 1)
	bipob.selected_internal_rotation = posmod(bipob.selected_internal_rotation, 3)
	var v: Vector3i = bipob.get_internal_volume_size()
	bipob.selected_internal_origin.x = clampi(bipob.selected_internal_origin.x, 0, v.x - 1)
	bipob.selected_internal_origin.y = clampi(bipob.selected_internal_origin.y, 0, v.y - 1)
	bipob.selected_internal_origin.z = clampi(bipob.selected_internal_origin.z, 0, v.z - 1)

func _get_selected_internal_module() -> BipobModule:
	var modules := _get_internal_box_modules()
	if modules.is_empty():
		return null
	_clamp_internal_selection()
	return modules[bipob.selected_internal_box_index]

func get_internal_module_marker(module: BipobModule) -> String:
	if module == null:
		return "X"
	match module.internal_role:
		"battery":
			return "B"
		"processor":
			return "P"
		"external_interface":
			return "E"
		"internal_interface":
			return "I"
		"memory":
			return "M"
		"power_block":
			return "W"
		"storage":
			return "H"
		_:
			return "X"

func _build_internal_axis_header(prefix: String, count: int) -> String:
	var labels: Array[String] = []
	for i in range(count):
		labels.append("%s%d" % [prefix, i])
	return "    %s" % " ".join(labels)

func _get_internal_cell_marker(cell: Vector3i, preview_cells_map: Dictionary, can_place: bool) -> String:
	var is_origin := cell == bipob.selected_internal_origin
	var occupied_module: BipobModule = bipob.get_internal_module_at_cell(cell)
	var is_occupied := occupied_module != null
	var in_preview := preview_cells_map.has(bipob.get_internal_slot_key(cell))
	if in_preview:
		if can_place:
			return "[>]" if is_origin else "[*]"
		if is_origin and is_occupied:
			return "[>%s]" % get_internal_module_marker(occupied_module)
		return "[!]"
	if is_origin and is_occupied:
		return "[>%s]" % get_internal_module_marker(occupied_module)
	if is_origin:
		return "[>]"
	if is_occupied:
		return "[%s]" % get_internal_module_marker(occupied_module)
	return "[ ]"

func _on_prev_external_side_pressed() -> void:
	if bipob == null:
		return
	selected_external_side_index -= 1
	clamp_external_selection()
	update_box_status()

func _on_next_external_side_pressed() -> void:
	if bipob == null:
		return
	selected_external_side_index += 1
	clamp_external_selection()
	update_box_status()

func _move_external_slot_by(delta: int) -> void:
	if bipob == null:
		return
	clamp_external_selection()
	var side_id := get_selected_external_side_id()
	var side_size: Vector2i = bipob.get_external_side_size(side_id)
	var width := side_size.x
	var total_slots := width * side_size.y
	if total_slots <= 0:
		return
	var index := selected_external_slot_position.y * width + selected_external_slot_position.x
	index = (index + delta) % total_slots
	if index < 0:
		index += total_slots
	selected_external_slot_position.x = index % width
	selected_external_slot_position.y = int(index / width)

func _on_prev_external_slot_pressed() -> void:
	_move_external_slot_by(-1)
	update_box_status()

func _on_next_external_slot_pressed() -> void:
	_move_external_slot_by(1)
	update_box_status()

func _on_place_external_module_pressed() -> void:
	if bipob == null:
		return
	if bipob.box_storage.is_empty():
		show_hint("Box storage is empty.")
		return
	clamp_box_selection_indexes()
	clamp_external_selection()
	var side_id := get_selected_external_side_id()
	if bipob.place_external_module_from_box_storage(
		selected_box_storage_index,
		side_id,
		selected_external_slot_position
	):
		clamp_box_selection_indexes()
		clamp_external_selection()
		update_box_status()

func _on_remove_external_module_pressed() -> void:
	if bipob == null:
		return
	clamp_external_selection()
	var side_id := get_selected_external_side_id()
	if bipob.remove_external_module_to_box_storage(side_id, selected_external_slot_position):
		clamp_box_selection_indexes()
		update_box_status()

func show_hint(message: String) -> void:
	if hint_label != null:
		hint_label.text = message

func _on_move_forward_pressed() -> void:
	bipob.move_forward()
	update_status()

func _on_move_backward_pressed() -> void:
	bipob.move_backward()
	update_status()

func _on_turn_left_pressed() -> void:
	bipob.turn_left()
	update_status()

func _on_turn_right_pressed() -> void:
	bipob.turn_right()
	update_status()

func _on_interact_pressed() -> void:
	bipob.interact()
	update_status()

func _on_drop_item_button_pressed() -> void:
	bipob.drop_held_item()
	update_status()
	update_diagnostic_status()
	update_box_status()

func _on_rotate_storage_button_pressed() -> void:
	bipob.rotate_physical_storage()
	update_status()
	update_diagnostic_status()
	update_box_status()

func _on_scan_device_button_pressed() -> void:
	bipob.scan_device()
	update_status()
	update_diagnostic_status()
	update_box_status()

func _on_hack_device_button_pressed() -> void:
	bipob.hack_device()
	update_status()
	update_diagnostic_status()
	update_box_status()

func _on_end_turn_pressed() -> void:
	bipob.end_turn()
	update_status()

func _on_restart_mission_button_pressed() -> void:
	if bipob == null:
		return

	# Mission reset action: should not spend field action points or energy as button press.
	bipob.restart_current_mission()
	if box_screen != null and box_screen.visible:
		hide_box_screen()
	else:
		if command_panel != null:
			command_panel.visible = true

	update_status()
	update_diagnostic_status()
	update_box_status()

func _on_return_to_box_button_pressed() -> void:
	if bipob == null:
		return
	bipob.return_to_box()
	if box_screen != null and not box_screen.visible:
		show_box_screen()
	update_status()
	update_box_status()
	update_diagnostic_status()

func update_status() -> void:
	if bipob == null:
		return

	var key_text := "no"
	if bipob.has_key:
		key_text = "yes"

	var info_key_text := "no"
	if bipob.has_info_key:
		info_key_text = "yes"
	var held_text := "empty"
	if bipob.held_module != null:
		held_text = bipob.get_module_display_name(bipob.held_module)
	elif bipob.current_mission_index == 7 and bipob.mission7_is_dragging_cable:
		held_text = "Cable End"
	var storage_text := "empty"
	if bipob.stored_physical_module != null:
		storage_text = bipob.get_module_display_name(bipob.stored_physical_module)

	if status_label == null:
		return

	status_label.text = "Energy: %d / %d | Actions: %d / %d | Key: %s | Info-Key: %s | Hand: %s | Storage: %s" % [
		bipob.energy,
		bipob.max_energy,
		bipob.actions_left,
		bipob.actions_per_turn,
		key_text,
		info_key_text,
		held_text,
		storage_text
	]
	status_label.text += " | Carry: %d / %d" % [
		bipob.get_carried_physical_count(),
		bipob.physical_carry_capacity
	]
	var digital_storage_short_text := "empty"
	if bipob.has_method("get_digital_storage_short_text"):
		digital_storage_short_text = str(bipob.get_digital_storage_short_text())
	elif bipob.has_method("get_digital_storage_text"):
		var full_storage_text := str(bipob.get_digital_storage_text())
		if full_storage_text.begins_with("Digital storage: "):
			digital_storage_short_text = full_storage_text.trim_prefix("Digital storage: ")
		elif full_storage_text.begins_with("Digital storage:\n- "):
			digital_storage_short_text = full_storage_text.trim_prefix("Digital storage:\n- ").replace("\n- ", ", ")
		elif not full_storage_text.is_empty():
			digital_storage_short_text = full_storage_text
	status_label.text += " | Data: %s" % digital_storage_short_text
	if bipob.has_method("get_mission8_airflow_status_text"):
		var mission8_status := str(bipob.get_mission8_airflow_status_text())
		if not mission8_status.is_empty():
			status_label.text += " | %s" % mission8_status
	if bipob.current_mission_index == 7 and bipob.has_method("get_mission7_cable_status_text"):
		status_label.text += " | %s" % str(bipob.get_mission7_cable_status_text())


func update_diagnostic_status() -> void:
	if bipob == null:
		return

	if diagnostic_label == null:
		return

	var result = bipob.last_diagnostic_result
	if result == null:
		diagnostic_label.text = "Diagnostic: none"
		return

	var device_name: String = str(result.device_name)

	if device_name.is_empty():
		device_name = "unknown"

	var status_text: String = str(result.get_status_text())

	if status_text.is_empty():
		status_text = "UNKNOWN"

	var supported_action: String = str(result.supported_action)
	if supported_action.is_empty():
		supported_action = "none"

	var reason: String = str(result.reason)
	if reason.is_empty():
		reason = "n/a"

	var recommendation: String = str(result.recommendation)
	if recommendation.is_empty():
		recommendation = "n/a"

	var estimated_risk: String = str(result.estimated_risk)
	if estimated_risk.is_empty():
		estimated_risk = "n/a"

	diagnostic_label.text = "Diagnostic:\nDevice: %s\nStatus: %s\nAction: %s\nReason: %s\nRecommendation: %s\nRisk: %s" % [
		device_name,
		status_text,
		supported_action,
		reason,
		recommendation,
		estimated_risk
	]


func get_box_internal_menu_text() -> String:
	_clamp_internal_selection()
	var selected_module := _get_selected_internal_module()
	var preview_cells: Array[Vector3i] = []
	var preview_cells_map := {}
	var placement_error := "No internal module selected."
	var can_place := false
	if selected_module != null:
		preview_cells = bipob.get_internal_module_covered_cells(selected_module, bipob.selected_internal_origin, bipob.selected_internal_rotation)
		for cell in preview_cells:
			preview_cells_map[bipob.get_internal_slot_key(cell)] = true
		placement_error = bipob.get_internal_module_placement_error(selected_module, bipob.selected_internal_origin, bipob.selected_internal_rotation)
		can_place = placement_error.is_empty()
	if can_place:
		placement_error = "OK"
	var selected_cell_module := bipob.get_internal_module_at_cell(bipob.selected_internal_origin)

	var lines: Array[String] = []
	lines.append("Selected internal module: %s" % ("none" if selected_module == null else ""))
	if selected_module == null:
		pass
	else:
		var base_size: Vector3i = bipob.get_internal_module_base_size(selected_module)
		var rotated_size: Vector3i = bipob.get_rotated_internal_size(selected_module, bipob.selected_internal_rotation)
		lines.append("> %s" % bipob.get_module_display_name(selected_module))
		lines.append("Size: %d×%d×%d" % [base_size.x, base_size.y, base_size.z])
		lines.append("Rotated: %d×%d×%d" % [rotated_size.x, rotated_size.y, rotated_size.z])
		lines.append("Role: %s" % selected_module.internal_role)
	lines.append("")
	lines.append("Selected cell: %s" % ("empty" if selected_cell_module == null else "occupied by %s" % bipob.get_module_display_name(selected_cell_module)))
	lines.append("")
	lines.append("Internal box storage:")
	var internal_modules := _get_internal_box_modules()
	if internal_modules.is_empty():
		lines.append("empty")
	else:
		for i in range(internal_modules.size()):
			lines.append(("> " if i == bipob.selected_internal_box_index else "  ") + bipob.get_module_display_name(internal_modules[i]))
	lines.append("")
	lines.append("Marker legend:")
	lines.append("[ ] empty")
	lines.append("[>] selected origin")
	lines.append("[*] valid preview footprint")
	lines.append("[!] invalid preview footprint")
	lines.append("[X] occupied (default)")
	lines.append("[>X] selected occupied cell")
	lines.append("")
	var v: Vector3i = bipob.get_internal_volume_size()
	lines.append("Front view X/Y at Z=%d" % bipob.selected_internal_origin.z)
	lines.append(_build_internal_axis_header("x", v.x))
	for y in range(v.y):
		var row: Array[String] = []
		for x in range(v.x):
			var cell: Vector3i = Vector3i(x, y, bipob.selected_internal_origin.z)
			var marker: String = " " if bipob.get_internal_module_at_cell(cell) == null else "[X]"
			if preview_cells.has(cell):
				marker = "[*]" if can_place else "[!]"
			if x == bipob.selected_internal_origin.x and y == bipob.selected_internal_origin.y:
				marker = "[>]"
			row.append(marker)
		lines.append(" ".join(row))

			var cell := Vector3i(x, y, bipob.selected_internal_origin.z)
			row.append(_get_internal_cell_marker(cell, preview_cells_map, can_place))
		lines.append("y%d %s" % [y, " ".join(row)])

	lines.append("")
	lines.append("Vertical slice Z/Y at X=%d" % bipob.selected_internal_origin.x)
	lines.append(_build_internal_axis_header("z", v.z))
	for y in range(v.y):
		var row: Array[String] = []
		for z in range(v.z):
			var cell := Vector3i(bipob.selected_internal_origin.x, y, z)
			row.append(_get_internal_cell_marker(cell, preview_cells_map, can_place))
		lines.append("y%d %s" % [y, " ".join(row)])
	lines.append("")
	lines.append("Horizontal slice X/Z at Y=%d" % bipob.selected_internal_origin.y)
	lines.append(_build_internal_axis_header("x", v.x))
	for z in range(v.z):
		var row: Array[String] = []
		for x in range(v.x):
			var cell := Vector3i(x, bipob.selected_internal_origin.y, z)
			row.append(_get_internal_cell_marker(cell, preview_cells_map, can_place))
		lines.append("z%d %s" % [z, " ".join(row)])
	lines.append("")
	lines.append("Placed internal modules:")
	if bipob.placed_internal_modules.is_empty():
		lines.append("none")
	else:
		for record_variant in bipob.placed_internal_modules:
			var record: Dictionary = record_variant
			var placed_module: BipobModule = record.get("module", null)
			if placed_module == null:
				continue
			var origin: Vector3i = record.get("origin", Vector3i.ZERO)
			var rotation: int = int(record.get("rotation", 0))
			var size: Vector3i = bipob.get_rotated_internal_size(placed_module, rotation)
			lines.append("- %s at %d,%d,%d size %d×%d×%d rot %d" % [
				bipob.get_module_display_name(placed_module),
				origin.x, origin.y, origin.z,
				size.x, size.y, size.z,
				rotation
			])
	lines.append("")
	lines.append("Placement:")
	var placement_size := Vector3i.ZERO if selected_module == null else bipob.get_rotated_internal_size(selected_module, bipob.selected_internal_rotation)
	lines.append("Origin: %d,%d,%d" % [bipob.selected_internal_origin.x, bipob.selected_internal_origin.y, bipob.selected_internal_origin.z])
	lines.append("Rotation: %d" % bipob.selected_internal_rotation)
	lines.append("Rotated size: %d×%d×%d" % [placement_size.x, placement_size.y, placement_size.z])
	lines.append("Valid: %s" % get_yes_no(can_place))
	lines.append("Reason: %s" % placement_error)
	lines.append("")
	lines.append("Connection model:")
	lines.append("Power: %s" % ("available" if bipob.is_virtual_power_available() else "unavailable"))
	lines.append("Internal data: %s" % ("available" if bipob.is_internal_data_network_available() else "unavailable"))
	lines.append("External data: %s" % ("available" if bipob.is_external_data_network_available() else "unavailable"))
	return "\n".join(lines)

func _move_internal_cursor(dx: int, dy: int, dz: int) -> void:
	var v: Vector3i = bipob.get_internal_volume_size()
	bipob.selected_internal_origin.x = clampi(bipob.selected_internal_origin.x + dx, 0, v.x - 1)
	bipob.selected_internal_origin.y = clampi(bipob.selected_internal_origin.y + dy, 0, v.y - 1)
	bipob.selected_internal_origin.z = clampi(bipob.selected_internal_origin.z + dz, 0, v.z - 1)
	update_box_status()

func _on_prev_internal_box_pressed() -> void:
	var modules := _get_internal_box_modules()
	if modules.is_empty():
		show_hint("No internal modules in Box storage.")
		return
	bipob.selected_internal_box_index = posmod(bipob.selected_internal_box_index - 1, modules.size())
	update_box_status()

func _on_next_internal_box_pressed() -> void:
	var modules := _get_internal_box_modules()
	if modules.is_empty():
		show_hint("No internal modules in Box storage.")
		return
	bipob.selected_internal_box_index = posmod(bipob.selected_internal_box_index + 1, modules.size())
	update_box_status()

func _on_internal_x_minus_pressed() -> void: _move_internal_cursor(-1, 0, 0)
func _on_internal_x_plus_pressed() -> void: _move_internal_cursor(1, 0, 0)
func _on_internal_y_minus_pressed() -> void: _move_internal_cursor(0, -1, 0)
func _on_internal_y_plus_pressed() -> void: _move_internal_cursor(0, 1, 0)
func _on_internal_z_minus_pressed() -> void: _move_internal_cursor(0, 0, -1)
func _on_internal_z_plus_pressed() -> void: _move_internal_cursor(0, 0, 1)
func _on_rotate_internal_pressed() -> void:
	bipob.selected_internal_rotation = posmod(bipob.selected_internal_rotation + 1, 3)
	update_box_status()
func _on_place_internal_pressed() -> void:
	var module := _get_selected_internal_module()
	if module == null:
		show_hint("No internal module selected.")
		return
	if bipob.place_internal_module(module, bipob.selected_internal_origin, bipob.selected_internal_rotation):
		update_box_status()
func _on_remove_internal_pressed() -> void:
	if bipob.remove_internal_module(bipob.selected_internal_origin):
		update_box_status()
func _on_reset_internal_cursor_pressed() -> void:
	bipob.selected_internal_origin = Vector3i.ZERO
	bipob.selected_internal_rotation = 0
	update_box_status()
