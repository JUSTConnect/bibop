extends RefCounted

# Target class: InventorySystem
# Inventory ownership, stacks and transfer.

var repository: RefCounted = null

func get_inventory(_inventory_id: String) -> Dictionary:
	return {"items": []}

func add_item(inventory_id: String, item_id: String) -> Dictionary:
	return {"ok": true, "message": "Item added.", "changed_ids": [inventory_id, item_id]}

func remove_item(inventory_id: String, item_id: String, _amount: int = 1) -> Dictionary:
	return {"ok": true, "message": "Item removed.", "changed_ids": [inventory_id, item_id]}
