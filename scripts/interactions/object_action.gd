extends RefCounted

static func make(action_id: String, label: String, enabled: bool = true, reason: String = "") -> Dictionary:
	return {
		"id": action_id,
		"label": label,
		"enabled": enabled,
		"disabled_reason": reason,
	}
