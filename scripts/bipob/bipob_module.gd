extends Resource
class_name BipobModule

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var placement_type: String = "unknown"

@export var granted_commands: Array[String] = []

@export var energy_bonus: int = 0
@export var actions_bonus: int = 0
@export var vision_bonus: int = 0

@export var size_x: int = 1
@export var size_y: int = 1
@export var size_z: int = 1
@export var internal_rotatable: bool = true
@export var internal_role: String = "none"
