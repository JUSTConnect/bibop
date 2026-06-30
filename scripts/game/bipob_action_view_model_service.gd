extends RefCounted
class_name BipobActionViewModelService

const ActionBuilderRef = preload("res://scripts/game/presentation/runtime_action_view_model_builder.gd")
const SnapshotServiceRef = preload("res://scripts/game/presentation/runtime_presentation_snapshot_service.gd")

static func should_hide_action_from_generic_menu(controller: Variant, world_object: Dictionary, action_id: String) -> bool:
	return ActionBuilderRef.should_hide_action(controller, world_object, action_id)

static func build_runtime_action_view_model(controller: Variant, target_object: Dictionary, target_position: Vector2i) -> Dictionary:
	var view_model: Dictionary = ActionBuilderRef.build(controller, target_object, target_position)
	view_model["presentation_snapshot"] = SnapshotServiceRef.build(controller, Dictionary(view_model.get("target", target_object)), target_position, view_model, {"mode":"runtime"})
	return view_model

static func build_runtime_presentation_snapshot(controller: Variant, target_object: Dictionary, target_position: Vector2i, action_view_model: Dictionary, context: Dictionary = {}) -> Dictionary:
	return SnapshotServiceRef.build(controller, target_object, target_position, action_view_model, context)
