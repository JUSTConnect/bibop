extends RefCounted

# Target class: ItemSystem
# Pickup/drop/use/consume items. UI не меняет item data напрямую.

var repository: RefCounted = null

func get_item_actions(_actor_id: String, _item_id: String) -> Array[Dictionary]:
	return []

func pickup_item(actor_id: String, item_id: String) -> Dictionary:
	return {"ok": true, "message": "Item picked up.", "changed_ids": [actor_id, item_id]}

func drop_item(actor_id: String, item_id: String, _cell: Vector2i) -> Dictionary:
	return {"ok": true, "message": "Item dropped.", "changed_ids": [actor_id, item_id]}

func use_item(actor_id: String, item_id: String, target_id: String) -> Dictionary:
	return {"ok": true, "message": "Item used.", "changed_ids": [actor_id, item_id, target_id]}
