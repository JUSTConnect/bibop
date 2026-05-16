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

func _ready() -> void:
	status_label.position = Vector2(100, 20)
	hint_label.position = Vector2(100, 50)
	hint_label.text = "Goal: pick up the key, open the door, reach the exit."

	diagnostic_label = Label.new()
	diagnostic_label.name = "DiagnosticLabel"
	diagnostic_label.position = Vector2(100, 80)
	diagnostic_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	diagnostic_label.custom_minimum_size = Vector2(700, 140)
	diagnostic_label.text = "Diagnostic: none"
	add_child(diagnostic_label)

	command_panel.position = Vector2(850, 80)
	command_panel.custom_minimum_size = Vector2(220, 260)

	box_screen.visible = false
	command_panel.visible = true

	move_forward_button.focus_mode = Control.FOCUS_NONE
	move_backward_button.focus_mode = Control.FOCUS_NONE
	turn_left_button.focus_mode = Control.FOCUS_NONE
	turn_right_button.focus_mode = Control.FOCUS_NONE
	interact_button.focus_mode = Control.FOCUS_NONE
	end_turn_button.focus_mode = Control.FOCUS_NONE

	scan_device_button = Button.new()
	scan_device_button.name = "ScanDeviceButton"
	scan_device_button.text = "Scan Device"
	scan_device_button.focus_mode = Control.FOCUS_NONE
	var command_list := command_panel.get_node_or_null("CommandList")
	if command_list != null:
		command_list.add_child(scan_device_button)
		scan_device_button.pressed.connect(_on_scan_device_button_pressed)

	move_forward_button.pressed.connect(_on_move_forward_pressed)
	move_backward_button.pressed.connect(_on_move_backward_pressed)
	turn_left_button.pressed.connect(_on_turn_left_pressed)
	turn_right_button.pressed.connect(_on_turn_right_pressed)
	interact_button.pressed.connect(_on_interact_pressed)
	end_turn_button.pressed.connect(_on_end_turn_pressed)

	charge_button.pressed.connect(_on_charge_button_pressed)
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
	bipob.charge_to_full()
	update_status()
	update_box_status()
	update_diagnostic_status()

func _on_install_module_button_pressed() -> void:
	bipob.install_found_module()
	update_status()
	update_box_status()
	update_diagnostic_status()

func _on_start_mission_button_pressed() -> void:
	bipob.start_next_mission()
	hide_box_screen()
	update_status()
	update_box_status()
	update_diagnostic_status()

func show_box_screen() -> void:
	box_screen.visible = true
	command_panel.visible = false
	update_box_status()
	
func hide_box_screen() -> void:
	box_screen.visible = false
	command_panel.visible = true
	update_status()
	update_box_status()
	update_diagnostic_status()
	
func update_box_status() -> void:
	if bipob == null:
		return

	update_diagnostic_status()

	box_status_label.text = "Energy: %d / %d" % [bipob.energy, bipob.max_energy]

	if bipob.found_module != null:
		box_module_label.text = "Found module: %s" % bipob.found_module.display_name
	else:
		box_module_label.text = "Found module: none"

	if bipob.installed_modules.is_empty():
		installed_modules_label.text = "Installed modules: none"
	else:
		var installed_modules_text := "Installed modules:"
		for module in bipob.installed_modules:
			installed_modules_text += "\n- %s" % module.display_name
		installed_modules_label.text = installed_modules_text

func show_hint(message: String) -> void:
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

func _on_scan_device_button_pressed() -> void:
	bipob.scan_device()
	update_status()
	update_diagnostic_status()
	update_box_status()

func _on_end_turn_pressed() -> void:
	bipob.end_turn()
	update_status()

func update_status() -> void:
	if bipob == null:
		return

	var key_text := "no"
	if bipob.has_key:
		key_text = "yes"

	var info_key_text := "no"
	if bipob.has_info_key:
		info_key_text = "yes"

	status_label.text = "Energy: %d / %d | Actions: %d / %d | Key: %s | Info-Key: %s" % [
		bipob.energy,
		bipob.max_energy,
		bipob.actions_left,
		bipob.actions_per_turn,
		key_text,
		info_key_text
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

	var device_name := "unknown"
	if result.device != null and not result.device.display_name.is_empty():
		device_name = result.device.display_name

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
