extends RefCounted

const ActionProviderRef = preload("res://scripts/interactions/object_action_provider.gd")

static func create(data: Dictionary) -> Dictionary:
	return {
		"section_id": "actions",
		"title": "Actions",
		"actions": ActionProviderRef.get_actions(data),
		"entity_id": str(data.get("id", "")),
	}
