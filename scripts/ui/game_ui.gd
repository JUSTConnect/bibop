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
@onready var charge_button: Button = $BoxScreen/PanelContainer/VBoxContainer/ButtonRow/ChargeButton
@onready var install_module_button: Button = $BoxScreen/PanelContainer/VBoxContainer/ButtonRow/InstallModuleButton
@onready var start_mission_button: Button = $BoxScreen/PanelContainer/VBoxContainer/ButtonRow/StartMissionButton

@onready var box_title_label: Label = $BoxScreen/PanelContainer/VBoxContainer/TitleLabel

@onready var move_forward_button: Button = $CommandPanel/CommandList/MoveForwardButton
@onready var move_backward_button: Button = $CommandPanel/CommandList/MoveBackwardButton
@onready var turn_left_button: Button = $CommandPanel/CommandList/TurnLeftButton
@onready var turn_right_button: Button = $CommandPanel/CommandList/TurnRightButton
@onready var interact_button: Button = $CommandPanel/CommandList/InteractButton
@onready var end_turn_button: Button = $CommandPanel/CommandList/EndTurnButton

var scan_device_button: Button
var hack_device_button: Button
var restart_mission_button: Button
var drop_item_button: Button

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

	if box_storage_label == null:
		box_storage_label = Label.new()
		box_storage_label.name = "BoxStorageLabel"
		box_storage_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var box_vbox := box_screen.get_node_or_null("PanelContainer/VBoxContainer")
		if box_vbox != null:
			box_vbox.add_child(box_storage_label)
			if start_mission_button != null:
				box_vbox.move_child(box_storage_label, start_mission_button.get_index())

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
		charge_button.pressed.connect(_on_charge_button_pressed)
	if install_module_button != null:
		install_module_button.pressed.connect(_on_install_module_button_pressed)
	if start_mission_button != null:
		start_mission_button.pressed.connect(_on_start_mission_button_pressed)

	bipob.status_changed.connect(update_status)
	bipob.hint_requested.connect(show_hint)
	bipob.mission_completed.connect(show_box_screen)

	update_status()
	update_box_status()
	update_diagnostic_status()

func _on_charge_button_pressed() -> void:
	# BoxScreen preparation action: must not spend field action points or energy.
	bipob.charge_to_full()
	update_status()
	update_box_status()
	update_diagnostic_status()

func _on_install_module_button_pressed() -> void:
	# BoxScreen preparation action: must not spend field action points or energy.
	bipob.install_available_module()
	update_status()
	update_box_status()
	update_diagnostic_status()

func _on_start_mission_button_pressed() -> void:
	if bipob == null:
		return

	# BoxScreen preparation action: starts mission flow without field action/energy spend.
	if bipob.sector_completed:
		bipob.start_next_mission()
		update_status()
		update_box_status()
		update_diagnostic_status()
		return

	bipob.start_next_mission()
	if not bipob.sector_completed:
		hide_box_screen()
	update_status()
	update_box_status()
	update_diagnostic_status()

func show_box_screen() -> void:
	if box_screen != null:
		box_screen.visible = true
	if command_panel != null:
		command_panel.visible = false
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

	update_diagnostic_status()

	if box_title_label != null:
		box_title_label.text = "Box / Garage"

	if bipob.sector_completed:
		if box_status_label != null:
			box_status_label.text = "Sector-01 complete. Playtest build finished.\nEnergy: %d / %d" % [bipob.energy, bipob.max_energy]
	else:
		if box_status_label != null:
			box_status_label.text = "Energy: %d / %d" % [bipob.energy, bipob.max_energy]

	if bipob.found_module != null:
		if box_module_label != null:
			box_module_label.text = "Found module: %s" % bipob.get_module_display_name(bipob.found_module)
	else:
		if box_module_label != null:
			box_module_label.text = "Found module: none"

	var hand_text := "empty"
	if bipob.held_module != null:
		hand_text = bipob.get_module_display_name(bipob.held_module)
	if box_module_label != null:
		box_module_label.text += "\nHand: %s" % hand_text

	if bipob.box_storage.is_empty():
		if box_storage_label != null:
			box_storage_label.text = "Box storage: empty"
	else:
		var box_storage_text := "Box storage:"
		for module in bipob.box_storage:
			box_storage_text += "\n- %s" % bipob.get_module_display_name(module)
		if box_storage_label != null:
			box_storage_label.text = box_storage_text

	if bipob.installed_modules.is_empty():
		if installed_modules_label != null:
			installed_modules_label.text = "Installed modules: none"
	else:
		var installed_modules_text := "Installed modules:"
		for module in bipob.installed_modules:
			installed_modules_text += "\n- %s" % bipob.get_module_display_name(module)
		if installed_modules_label != null:
			installed_modules_label.text = installed_modules_text

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

	if status_label == null:
		return

	status_label.text = "Energy: %d / %d | Actions: %d / %d | Key: %s | Info-Key: %s | Hand: %s" % [
		bipob.energy,
		bipob.max_energy,
		bipob.actions_left,
		bipob.actions_per_turn,
		key_text,
		info_key_text,
		held_text
	]
	status_label.text += " | Carry: %d / %d" % [
		bipob.get_carried_physical_count(),
		bipob.physical_carry_capacity
	]


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
