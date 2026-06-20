extends RefCounted
class_name MapConstructorActions

static func move_entity_to_cell(ui: Variant, entity_kind: String, entity_id: String, target_cell: Vector2i) -> Dictionary:
	if not _is_valid_map_cell(target_cell):
		ui.show_hint("Move target must be a valid map cell.")
		return {}
	if ui.mission_manager_runtime == null or not ui.mission_manager_runtime.has_method("move_map_constructor_entity_to_cell"):
		return {}
	var result: Dictionary = ui._safe_ui_dictionary(ui.mission_manager_runtime.call("move_map_constructor_entity_to_cell", entity_kind, entity_id, target_cell))
	ui.show_hint(ui._safe_ui_string(result.get("message", "Move complete."), "Move complete."))
	refresh_after_mutation(ui, result, target_cell, entity_kind, entity_id)
	return result

static func duplicate_entity_to_cell(ui: Variant, entity_kind: String, entity_id: String, target_cell: Vector2i) -> Dictionary:
	if not _is_valid_map_cell(target_cell):
		ui.show_hint("Duplicate target must be a valid map cell.")
		return {}
	if ui.mission_manager_runtime == null or not ui.mission_manager_runtime.has_method("duplicate_map_constructor_entity_to_cell"):
		return {}
	var result: Dictionary = ui._safe_ui_dictionary(ui.mission_manager_runtime.call("duplicate_map_constructor_entity_to_cell", entity_kind, entity_id, target_cell))
	ui.show_hint(ui._safe_ui_string(result.get("message", "Duplicate complete."), "Duplicate complete."))
	var duplicated_entity_id: String = ui._safe_ui_string(result.get("entity_id", ""))
	refresh_after_mutation(ui, result, target_cell, entity_kind, duplicated_entity_id, not duplicated_entity_id.is_empty())
	return result

static func delete_entity_at_cell(ui: Variant, cell: Vector2i) -> Dictionary:
	if ui.mission_manager_runtime == null or not ui.mission_manager_runtime.has_method("remove_map_constructor_object_at_cell"):
		return {}
	var result: Dictionary = ui._safe_ui_dictionary(ui.mission_manager_runtime.call("remove_map_constructor_object_at_cell", cell))
	ui.show_hint(ui._safe_ui_string(result.get("message", "Deleted."), "Deleted."))
	refresh_after_mutation(ui)
	ui._clear_map_constructor_link_target()
	return result

static func delete_entity_by_id(ui: Variant, entity_kind: String, entity_id: String, fallback_cell: Vector2i = Vector2i(-1, -1)) -> Dictionary:
	if ui.mission_manager_runtime == null or not ui.mission_manager_runtime.has_method("_remove_map_constructor_entity_by_id"):
		return {}
	var result: Dictionary = ui._safe_ui_dictionary(ui.mission_manager_runtime.call("_remove_map_constructor_entity_by_id", entity_kind, entity_id))
	ui.show_hint(ui._safe_ui_string(result.get("message", "Deleted."), "Deleted."))
	refresh_after_mutation(ui, result, fallback_cell)
	ui._clear_map_constructor_link_target()
	return result

static func apply_prefab_placement(ui: Variant, prefab_id: String, cell: Vector2i, options: Dictionary = {}) -> Dictionary:
	if ui.mission_manager_runtime == null or not ui.mission_manager_runtime.has_method("place_map_constructor_prefab"):
		return {}
	var wall_side: String = ui._safe_ui_string(options.get("wall_side", ui.map_constructor_state.selected_map_constructor_wall_side))
	var rotation: int = int(options.get("rotation", ui.map_constructor_state.map_constructor_pending_place_rotation))
	var mounting_mode: String = ui._safe_ui_string(options.get("mounting_mode", ui.map_constructor_state.selected_map_constructor_mounting_mode))
	return ui._safe_ui_dictionary(ui.mission_manager_runtime.call("place_map_constructor_prefab", prefab_id, cell, wall_side, rotation, mounting_mode))

static func apply_floor_material(ui: Variant, cell: Vector2i, material_id: String, floor_height: String = "default") -> Dictionary:
	if ui.mission_manager_runtime == null or not ui.mission_manager_runtime.has_method("set_map_constructor_floor_material"):
		return {}
	var result: Dictionary = ui._safe_ui_dictionary(ui.mission_manager_runtime.call("set_map_constructor_floor_material", cell, material_id, floor_height))
	ui.show_hint(ui._safe_ui_string(result.get("message", "Floor material updated."), "Floor material updated."))
	refresh_after_mutation(ui, {}, ui.map_constructor_state.selected_map_constructor_entity_cell, ui.map_constructor_state.selected_map_constructor_entity_kind, ui.map_constructor_state.selected_map_constructor_entity_id)
	return result

static func clear_floor_material(ui: Variant, cell: Vector2i) -> Dictionary:
	if ui.mission_manager_runtime == null or not ui.mission_manager_runtime.has_method("clear_map_constructor_floor_material"):
		return {}
	var result: Dictionary = ui._safe_ui_dictionary(ui.mission_manager_runtime.call("clear_map_constructor_floor_material", cell))
	ui.show_hint(ui._safe_ui_string(result.get("message", "Floor material cleared."), "Floor material cleared."))
	refresh_after_mutation(ui, {}, ui.map_constructor_state.selected_map_constructor_entity_cell, ui.map_constructor_state.selected_map_constructor_entity_kind, ui.map_constructor_state.selected_map_constructor_entity_id)
	return result

static func apply_wall_material(ui: Variant, cell: Vector2i, side: String, material_id: String) -> Dictionary:
	if ui.mission_manager_runtime == null or not ui.mission_manager_runtime.has_method("set_map_constructor_wall_material"):
		ui.show_hint("Wall material action unavailable.")
		return {}
	var result: Dictionary = ui._safe_ui_dictionary(ui.mission_manager_runtime.call("set_map_constructor_wall_material", cell, side, material_id))
	ui.show_hint(ui._safe_ui_string(result.get("message", "Wall material updated."), "Wall material updated."))
	refresh_after_mutation(ui, {}, ui.map_constructor_state.selected_map_constructor_entity_cell, ui.map_constructor_state.selected_map_constructor_entity_kind, ui.map_constructor_state.selected_map_constructor_entity_id)
	return result

static func clear_wall_material(ui: Variant, cell: Vector2i, side: String) -> Dictionary:
	if ui.mission_manager_runtime == null or not ui.mission_manager_runtime.has_method("clear_map_constructor_wall_material"):
		ui.show_hint("Wall material action unavailable.")
		return {}
	var result: Dictionary = ui._safe_ui_dictionary(ui.mission_manager_runtime.call("clear_map_constructor_wall_material", cell, side))
	ui.show_hint(ui._safe_ui_string(result.get("message", "Wall material cleared."), "Wall material cleared."))
	refresh_after_mutation(ui, {}, ui.map_constructor_state.selected_map_constructor_entity_cell, ui.map_constructor_state.selected_map_constructor_entity_kind, ui.map_constructor_state.selected_map_constructor_entity_id)
	return result

static func apply_wall_height(ui: Variant, cell: Vector2i, side: String, wall_height: String) -> Dictionary:
	if ui.mission_manager_runtime == null or not ui.mission_manager_runtime.has_method("set_map_constructor_wall_height"):
		ui.show_hint("Wall height action unavailable.")
		return {}
	var result: Dictionary = ui._safe_ui_dictionary(ui.mission_manager_runtime.call("set_map_constructor_wall_height", cell, side, wall_height))
	ui.show_hint(ui._safe_ui_string(result.get("message", "Wall height updated."), "Wall height updated."))
	refresh_after_mutation(ui, {}, ui.map_constructor_state.selected_map_constructor_entity_cell, ui.map_constructor_state.selected_map_constructor_entity_kind, ui.map_constructor_state.selected_map_constructor_entity_id)
	return result

static func apply_wall_breach_side(ui: Variant, cell: Vector2i, side: String, breach_side: String) -> Dictionary:
	if ui.mission_manager_runtime == null or not ui.mission_manager_runtime.has_method("set_map_constructor_wall_breach_side"):
		ui.show_hint("Breach Side action unavailable.")
		return {}
	var result: Dictionary = ui._safe_ui_dictionary(ui.mission_manager_runtime.call("set_map_constructor_wall_breach_side", cell, side, breach_side))
	ui.show_hint(ui._safe_ui_string(result.get("message", "Breach Side updated."), "Breach Side updated."))
	refresh_after_mutation(ui, {}, ui.map_constructor_state.selected_map_constructor_entity_cell, ui.map_constructor_state.selected_map_constructor_entity_kind, ui.map_constructor_state.selected_map_constructor_entity_id)
	return result

static func apply_wall_mounted_side(ui: Variant, entity_kind: String, entity_id: String, selected_side: String) -> Dictionary:
	var normalized_side: String = ui._normalize_map_constructor_wall_side(selected_side)
	if normalized_side.is_empty():
		ui.show_hint("Select a valid wall side before applying.")
		return {}
	if ui.mission_manager_runtime == null or not ui.mission_manager_runtime.has_method("set_map_constructor_wall_mounted_side"):
		ui.show_hint("Wall-mounted side action unavailable.")
		return {}
	var result: Dictionary = ui._safe_ui_dictionary(ui.mission_manager_runtime.call("set_map_constructor_wall_mounted_side", entity_kind, entity_id, normalized_side))
	ui.show_hint(ui._safe_ui_string(result.get("message", "Updated side."), "Updated side."))
	refresh_after_mutation(ui, {}, ui.map_constructor_state.selected_map_constructor_entity_cell, ui.map_constructor_state.selected_map_constructor_entity_kind, ui.map_constructor_state.selected_map_constructor_entity_id)
	return result

static func refresh_after_mutation(ui: Variant, result: Dictionary = {}, fallback_cell: Vector2i = Vector2i(-1, -1), entity_kind: String = "", entity_id: String = "", reopen_inspector: bool = true) -> void:
	ui._refresh_map_constructor_panels()
	if ui.field_runtime != null and ui.field_runtime.has_method("request_visual_refresh"):
		ui.field_runtime.call("request_visual_refresh")
	if reopen_inspector:
		ui._show_map_constructor_inspector(ui._safe_ui_vector2i(result.get("cell", fallback_cell)), entity_kind, entity_id)

static func _is_valid_map_cell(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0
