extends RefCounted
class_name PlatformControlService

const PlatformTypesRef = preload("res://scripts/game/platform/platform_types.gd")

static func get_action_labels(platform_data: Dictionary) -> Array[Dictionary]:
	var data: Dictionary = PlatformTypesRef.normalize_platform_config(platform_data)
	var mode: String = str(data.get("platform_mode", PlatformTypesRef.MODE_ELEVATOR))
	var labels: Array[Dictionary] = []
	if mode in [PlatformTypesRef.MODE_ELEVATOR, PlatformTypesRef.MODE_ELEVATOR_ROTATOR]:
		labels.append(_action("raise", "Raise", data))
		labels.append(_action("lower", "Lower", data))
	if mode in [PlatformTypesRef.MODE_ROTATOR, PlatformTypesRef.MODE_ELEVATOR_ROTATOR]:
		labels.append(_action("rotate_left", "Rotate Left", data))
		labels.append(_action("rotate_right", "Rotate Right", data))
	return labels

static func get_activation_schedule_metadata(platform_data: Dictionary) -> Dictionary:
	var data: Dictionary = PlatformTypesRef.normalize_platform_config(platform_data)
	var delayed: bool = str(data.get("activation_mode", "instant")) == PlatformTypesRef.ACTIVATION_DELAYED
	var delay_turns: int = int(data.get("activation_delay_turns", 0)) if delayed else 0
	return {"activation_mode": str(data.get("activation_mode", "instant")), "is_delayed": delayed, "delay_turns": delay_turns, "pending_turns": delay_turns}

static func _action(id: String, label: String, data: Dictionary) -> Dictionary:
	var schedule: Dictionary = get_activation_schedule_metadata(data)
	return {"id": id, "label": label, "activation": schedule, "delayed": bool(schedule.get("is_delayed", false)), "pending_turns": int(schedule.get("pending_turns", 0))}
