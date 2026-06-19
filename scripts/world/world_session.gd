extends RefCounted

var base_snapshot: Dictionary = {}

func capture(snapshot: Dictionary) -> void:
	base_snapshot = snapshot.duplicate(true)

func has_snapshot() -> bool:
	return not base_snapshot.is_empty()

func restore() -> Dictionary:
	return base_snapshot.duplicate(true)

func clear() -> void:
	base_snapshot.clear()
