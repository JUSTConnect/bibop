extends RefCounted

# Target class: ItemDefinition
# Описание типа item. Используется inventory, storage, palette, inspector и renderer.

var id: String = ""
var item_type: String = ""
var item_group: String = ""
var display_name: String = ""
var description: String = ""
var visual_id: String = ""
var stackable: bool = false
var max_stack: int = 1
var usable: bool = false
var consumable: bool = false
var config_schema: Array[Dictionary] = []
var interactions: Array[String] = []
