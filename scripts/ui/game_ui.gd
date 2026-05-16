extends CanvasLayer
class_name GameUI

@onready var bipob = get_node("../Bipob")

@onready var status_label: Label = $StatusLabel
@onready var hint_label: Label = $HintLabel
@onready var command_panel: PanelContainer = $CommandPanel
@onready var box_screen: Control = $BoxScreen

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

func _ready() -> void:
	status_label.position = Vector2(100, 20)
	hint_label.position = Vector2(100, 50)
	hint_label.text = "Goal: pick up the key, open the door, reach the exit."

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

	hide_box_screen()


	update_status()
	update_box_status()
	
	

func _on_charge_button_pressed() -> void:
	bipob.charge_to_full()
	update_status()
	update_box_status()

func _on_install_module_button_pressed() -> void:
	bipob.install_found_module()
	update_status()
	update_box_status()

func _on_start_mission_button_pressed() -> void:
	box_screen.visible = false
	command_panel.visible = true
	bipob.start_next_mission()
	update_status()
	update_box_status()

func show_box_screen() -> void:
	box_screen.visible = true
	command_panel.visible = false
	update_box_status()
	
func hide_box_screen() -> void:
	box_screen.visible = false
	command_panel.visible = true
	update_status()
	update_box_status()
	
func update_box_status() -> void:
	if bipob == null:
		return

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
