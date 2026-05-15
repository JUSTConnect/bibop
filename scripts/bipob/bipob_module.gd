extends RefCounted
class_name BipobModule

var id: String = ""
var granted_commands: Array[String] = []

func _init(module_id: String = "", commands: Array[String] = []) -> void:
	id = module_id
	granted_commands = commands.duplicate()
