extends RefCounted

# Target class: ObjectDefinition
# Описание типа объекта. Это source of truth для palette, inspector, runtime и renderer.

var id: String = ""
var object_type: String = ""
var object_group: String = ""
var display_name: String = ""
var description: String = ""
var visual_id: String = ""
var tags: Array[String] = []
var base_parameters: Dictionary = {}
var config_schema: Array[Dictionary] = []
var links_schema: Array[Dictionary] = []
var interactions: Array[String] = []
var validation_rules: Array[Dictionary] = []
