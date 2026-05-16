extends Resource
class_name BipobModule

<<<<<<< HEAD
@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
=======
var id: String = ""
var display_name: String = ""
var description: String = ""
var energy_bonus: int = 0
var actions_bonus: int = 0
var vision_bonus: int = 0
var granted_commands: Array[String] = []
>>>>>>> 916233b84424b88795241bbaab5f1b126863d586

@export var granted_commands: Array[String] = []

@export var energy_bonus: int = 0
@export var actions_bonus: int = 0
@export var vision_bonus: int = 0
