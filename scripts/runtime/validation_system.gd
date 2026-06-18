extends RefCounted

# Target class: ValidationSystem
# Собирает warnings/errors/quick fixes. Не меняет данные без Apply.

var repository: RefCounted = null

func validate_mission() -> Dictionary:
	return {"issues": []}

func validate_object(_object_id: String) -> Array[Dictionary]:
	return []

func validate_item(_item_id: String) -> Array[Dictionary]:
	return []

func apply_quick_fix(_fix_id: String) -> Dictionary:
	return {"ok": false, "message": "Quick fix is not implemented yet."}
