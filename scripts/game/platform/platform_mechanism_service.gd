extends RefCounted
class_name PlatformMechanismService

const PlatformTypesRef = preload("res://scripts/game/platform/platform_types.gd")

static func get_mechanism_summary(mechanism_id: String, world_objects: Array = []) -> Dictionary:
	var normalized_id: String = mechanism_id.strip_edges()
	var members: Array[Dictionary] = []
	for object_variant in world_objects:
		var object_data: Dictionary = Dictionary(object_variant)
		if not PlatformTypesRef.is_platform_data(object_data):
			continue
		if str(object_data.get("mechanism_id", "")).strip_edges() != normalized_id:
			continue
		members.append({"id": str(object_data.get("id", "")), "cell": object_data.get("position", Vector2i(-1, -1)), "role": str(object_data.get("mechanism_role", "single")), "level": int(object_data.get("platform_level", 0))})
	return {"ok": true, "mechanism_id": normalized_id, "member_count": members.size(), "members": members, "warnings": _warnings(normalized_id, members)}

static func validate_mechanism(mechanism_id: String, world_objects: Array = []) -> Dictionary:
	var summary: Dictionary = get_mechanism_summary(mechanism_id, world_objects)
	var warnings: Array = Array(summary.get("warnings", []))
	return {"ok": warnings.is_empty(), "mechanism_id": str(summary.get("mechanism_id", "")), "warnings": warnings, "errors": [], "summary": summary}

static func _warnings(mechanism_id: String, members: Array[Dictionary]) -> Array[String]:
	var warnings: Array[String] = []
	if mechanism_id.is_empty():
		warnings.append("mechanism_id_empty_single_platform_only")
	elif members.is_empty():
		warnings.append("mechanism_has_no_members")
	return warnings
