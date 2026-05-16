extends RefCounted
class_name BipobModule

var id: String = ""
var display_name: String = ""
var description: String = ""
var energy_bonus: int = 0
var actions_bonus: int = 0
var vision_bonus: int = 0
var granted_commands: Array[String] = []

func _init(module_id: String = "", commands: Array[String] = []) -> void:
	id = module_id
	granted_commands = commands.duplicate()
