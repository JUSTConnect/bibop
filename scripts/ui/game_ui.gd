extends CanvasLayer
class_name GameUI

@onready var bipob: BipobController = get_node("../Bipob")

@onready var status_label: Label = $StatusLabel
@onready var hint_label: Label = $HintLabel
@onready var command_panel: PanelContainer = $CommandPanel

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

	bipob.status_changed.connect(update_status)
	bipob.hint_requested.connect(show_hint)
	update_status()
	
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
	
	status_label.text = "Energy: %d / %d | Actions: %d / %d | Key: %s" % [
		bipob.energy,
		bipob.max_energy,
		bipob.actions_left,
		bipob.actions_per_turn,
		key_text
	]
