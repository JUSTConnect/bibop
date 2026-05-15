extends Resource
class_name BipobModule

# MVP module model for Bipob progression.
# Keeps module data minimal and non-invasive for current milestone.
@export var id: String
@export var display_name: String
@export var description: String
@export var granted_commands: Array[String] = []
@export var energy_bonus: int = 0
@export var actions_bonus: int = 0
@export var vision_bonus: int = 0
