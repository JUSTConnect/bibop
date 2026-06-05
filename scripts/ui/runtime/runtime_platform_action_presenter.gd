extends RefCounted
class_name RuntimePlatformActionPresenter

const PlatformControlServiceRef = preload("res://scripts/game/platform/platform_control_service.gd")

static func get_presented_actions(platform_data: Dictionary) -> Array[Dictionary]:
	return PlatformControlServiceRef.get_action_labels(platform_data)

static func get_action_summary_text(platform_data: Dictionary) -> String:
	var labels: Array[String] = []
	for action_variant in get_presented_actions(platform_data):
		var action: Dictionary = Dictionary(action_variant)
		var label: String = str(action.get("label", "Action"))
		if bool(action.get("delayed", false)):
			label += " (%d turns pending)" % int(action.get("pending_turns", 0))
		labels.append(label)
	return ", ".join(labels)
