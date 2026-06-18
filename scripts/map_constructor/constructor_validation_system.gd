extends RefCounted

# Target class: ConstructorValidationSystem
# Validation for map constructor. Не применяет quick fixes без явного Apply.

var repository: RefCounted = null

func validate_constructor_state() -> Dictionary:
	return {"issues": []}

func validate_entity(_entity_kind: String, _entity_id: String) -> Array[Dictionary]:
	return []
