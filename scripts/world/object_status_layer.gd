extends Node
class_name ObjectStatusLayerService

const EntityStatusEvaluatorRef = preload("res://scripts/world/entity_status_evaluator.gd")
const STATUS_SECTION_NAME := "ObjectStatusLayerSection"

func evaluate_object_status(object_data: Dictionary, context: Dictionary = {}) -> Dictionary:
	return EntityStatusEvaluatorRef.evaluate(object_data, context)

func normalize_object_status(object_data: Dictionary) -> Dictionary:
	return object_data.duplicate(true)

func ensure_object_status(_manager: Object, _entity_id: String, object_data: Dictionary) -> Dictionary:
	return evaluate_object_status(object_data)

func build_status_summary(object_data: Dictionary) -> Dictionary:
	var result: Dictionary = evaluate_object_status(object_data)
	return {"applies":not Dictionary(result.get("sections", {})).is_empty(), "total_state":"ready" if bool(result.get("is_operational", false)) else "not_ready", "warnings":[] if bool(result.get("is_operational", false)) else [str(result.get("reason_code", "blocked"))]}

func get_status_display_lines(object_data: Dictionary) -> Array[String]:
	var result: Dictionary = evaluate_object_status(object_data)
	if Dictionary(result.get("sections", {})).is_empty():
		return []
	var lines: Array[String] = []
	lines.append("Effective state: %s" % str(result.get("effective_state", "operational")))
	lines.append("Operational: %s" % str(result.get("is_operational", false)))
	if not str(result.get("reason_code", "")).is_empty():
		lines.append("Reason: %s" % str(result.get("reason_code", "")))
	return lines

func applies_to_object(object_data: Dictionary) -> bool:
	return not Dictionary(evaluate_object_status(object_data).get("sections", {})).is_empty()
