extends Resource
class_name BipobModule

@export var id: String = ""
@export var module_id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var placement_type: String = "unknown"
@export var category: String = "utility"
@export var version: String = "V1"

# External metadata
@export var external_width: int = 0
@export var external_height: int = 0
@export var allowed_external_sides: Array = []

# Internal metadata
@export var internal_size: Vector3i = Vector3i(1, 1, 1)
@export var size_x: int = 1
@export var size_y: int = 1
@export var size_z: int = 1
@export var internal_rotatable: bool = true
@export var internal_role: String = "none"
@export var internal_family: String = "none"
@export var module_version: int = 1

# Shared stats
@export var energy_cost: int = 0
@export var heat_value: int = 0
@export var scan_range: int = 0
@export var scan_accuracy: int = 0
@export var armor_bonus: int = 0
@export var shield_value: int = 0
@export var damage_value: String = ""
@export var weapon_range_type: String = ""
@export var special_effect_text: String = ""
@export var energy_effect_text: String = ""
@export var action_modifier: int = 0
@export var install_notes: String = ""
@export var characteristics_text: String = ""
@export var movement_type: String = ""
@export var terrain_type: String = ""
@export var gear_speed: int = 0
@export var ignore_terrain_debuff: bool = false

# Internal stat outputs
@export var energy_capacity: int = 0
@export var action_capacity: int = 0
@export var digital_storage_slots: int = 0
@export var hack_value: int = 0
@export var gpu_value: int = 0
@export var cooling_value: int = 0
@export var power_distribution: int = 0
@export var interface_role: String = ""
@export var ports: int = 0
@export var power_ports: int = 0

# Legacy compatibility fields
@export var granted_commands: Array[String] = []
@export var energy_bonus: int = 0
@export var actions_bonus: int = 0
@export var vision_bonus: int = 0
@export var effect_value: int = 0
@export var battery_capacity: int = 0
@export var storage_capacity: int = 0
@export var actions_capacity: int = 0
@export var hack_level: int = 0

# Heat / cooling legacy fields
@export var heat_idle: int = 0
@export var heat_active: int = 0
@export var cooling_power: int = 0
@export var cooling_type: String = "none"
@export var requires_air_intake: bool = false
@export var is_non_volume_cooling_path: bool = false

# Damage / repair
@export var can_be_damaged: bool = true
@export var damage_threshold_heat: int = 5
@export var repair_complexity: int = 1
@export var repair_category: String = "standard"


func get_display_name() -> String:
	if not display_name.is_empty():
		return display_name
	return id


func get_external_size() -> Vector2i:
	return Vector2i(external_width, external_height)


func get_internal_size() -> Vector3i:
	return internal_size
