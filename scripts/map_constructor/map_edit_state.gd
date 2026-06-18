extends RefCounted

# Target class: MapEditState
# Данные текущего состояния редактора карты.

var selected_cell: Vector2i = Vector2i(-1, -1)
var selected_entity_kind: String = ""
var selected_entity_id: String = ""
var active_tool_mode: String = "select"
var active_inspector_tab_id: String = "objects"
