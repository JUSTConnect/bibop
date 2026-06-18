extends RefCounted

# Target class: RuntimeHudViewModel
# Данные для Runtime HUD. Не создаёт UI и не меняет runtime state.

static func from_snapshot(snapshot: Dictionary) -> Dictionary:
	return {
		"energy": snapshot.get("energy", 0),
		"actions": snapshot.get("actions", 0),
		"controls": Array(snapshot.get("controls", [])),
		"notifications": Array(snapshot.get("notifications", [])),
	}
