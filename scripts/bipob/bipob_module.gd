extends Resource
class_name BipobModule

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var placement_type: String = "unknown"
@export var category: String = "utility"

@export var granted_commands: Array[String] = []

@export var energy_bonus: int = 0
@export var actions_bonus: int = 0
@export var vision_bonus: int = 0

@export var size_x: int = 1
@export var size_y: int = 1
@export var size_z: int = 1
@export var internal_rotatable: bool = true
@export var internal_role: String = "none"

@export var heat_idle: int = 0
@export var heat_active: int = 0
@export var cooling_power: int = 0
@export var cooling_type: String = "none"
@export var requires_air_intake: bool = false
@export var is_non_volume_cooling_path: bool = false
