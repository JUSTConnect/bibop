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
var box_restart_button: Button
var box_return_button: Button

enum BoxMenuMode {
	MISSION,
	MODULES,
	EXTERNAL
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

func _get_external_slot_mark(module: BipobModule) -> String:
	var module_name: String = bipob.get_module_display_name(module).to_upper()
	if module_name.is_empty():
		return "M"
	return module_name.substr(0, 1)

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
			box_title_label.text = "Box / Garage — External"
		else:
			box_title_label.text = "Box / Garage — Modules"

	var content_text: String
	if box_menu_mode == BoxMenuMode.MISSION:
		content_text = get_box_mission_menu_text()
	elif box_menu_mode == BoxMenuMode.EXTERNAL:
		content_text = get_box_external_menu_text()
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
	return "\n".join(content_lines)

func get_box_external_menu_text() -> String:
	clamp_external_selection()
	var side_id := get_selected_external_side_id()
	var side_size: Vector2i = bipob.get_external_side_size(side_id)
	var content_lines: Array[String] = []
	content_lines.append("Side: %s" % side_id)
	content_lines.append("Selected slot: %d,%d" % [selected_external_slot_position.x, selected_external_slot_position.y])
	content_lines.append(get_selected_box_module_text())
	content_lines.append("")
	content_lines.append("External side %s (%dx%d):" % [side_id, side_size.x, side_size.y])

	for y in range(side_size.y):
		var row_cells: Array[String] = []
		for x in range(side_size.x):
			var slot_pos := Vector2i(x, y)
			var module: BipobModule = bipob.get_external_module_at(side_id, slot_pos)
			var is_selected: bool = slot_pos == selected_external_slot_position

			if module == null:
				row_cells.append("[>]" if is_selected else "[ ]")
			else:
				var mark: String = _get_external_slot_mark(module)
				row_cells.append("[>%s]" % mark if is_selected else "[%s]" % mark)
		content_lines.append("".join(row_cells))

	content_lines.append("")
	content_lines.append("Legend:")
	content_lines.append("- empty slot: [ ]")
	content_lines.append("- selected empty slot: [>]")
	content_lines.append("- occupied slot: [V] or [M]")
	content_lines.append("- selected occupied slot: [>V]")
	content_lines.append("")
	content_lines.append("External build summary:")
	content_lines.append(str(bipob.get_external_build_summary_text()))
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
	if mission_tab_button != null:
		mission_tab_button.disabled = is_mission
	if modules_tab_button != null:
		modules_tab_button.disabled = is_modules
	if external_tab_button != null:
		external_tab_button.disabled = is_external

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
