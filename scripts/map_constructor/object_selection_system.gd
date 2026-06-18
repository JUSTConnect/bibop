extends RefCounted

# Target class: ObjectSelectionSystem
# Selection model for map constructor.

var selected_entity_kind: String = ""
var selected_entity_id: String = ""
var selected_cell: Vector2i = Vector2i(-1, -1)

func select_entity(entity_kind: String, entity_id: String, cell: Vector2i) -> void:
	selected_entity_kind = entity_kind
	selected_entity_id = entity_id
	selected_cell = cell

func clear_selection() -> void:
	selected_entity_kind = ""
	selected_entity_id = ""
	selected_cell = Vector2i(-1, -1)
