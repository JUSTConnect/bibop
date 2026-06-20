extends RefCounted
class_name MapConstructorSessionState

# Plain Map Constructor UI/session state holder.


var map_constructor_inspector_expanded: bool = false
var map_constructor_validation_overlay_visible: bool = true
var map_constructor_mode_active: bool = false
var map_constructor_active_tab: String = "map_settings"
var map_constructor_active_inspector_tab_id: String = ""
var map_constructor_active_inspector_entity_id: String = ""
var map_constructor_active_inspector_entity_kind: String = ""
var map_constructor_tab_scroll_positions: Dictionary = {}
var selected_map_constructor_prefab_id: String = ""
var pending_map_constructor_cell: Vector2i = Vector2i(-1, -1)
var map_constructor_pending_place_prefab_id: String = ""
var map_constructor_pending_place_cell: Vector2i = Vector2i(-1, -1)
var map_constructor_pending_place_rotation: int = 0
var selected_map_constructor_entity_kind: String = ""
var selected_map_constructor_entity_id: String = ""
var selected_map_constructor_entity_cell: Vector2i = Vector2i(-1, -1)
var selected_map_constructor_wall_side: String = ""
var selected_map_constructor_mounting_mode: String = "stationary"
var available_map_constructor_wall_sides: Array[String] = []
var map_constructor_picker_entity_kind: String = ""
var map_constructor_picker_entity_id: String = ""
var map_constructor_picker_field_name: String = ""
var map_constructor_preset_name: String = "preset"
var map_constructor_preset_entries: Variant = []:
	set(value):
		map_constructor_preset_entries = _normalize_dictionary_array(value, "presets")
var map_constructor_selected_preset_name: String = ""
var map_constructor_patch_name: String = "mission_patch"
var map_constructor_patch_entries: Variant = []:
	set(value):
		map_constructor_patch_entries = _normalize_dictionary_array(value, "patches")
var map_constructor_selected_patch_name: String = ""
var map_constructor_geometry_width_text: String = "20"
var map_constructor_geometry_height_text: String = "12"
var map_constructor_marker_mode: String = ""
var map_constructor_prefab_search_text: String = ""
var map_constructor_prefab_category_filter: String = "All"
var map_constructor_prefab_role_filter: String = "All"
var map_constructor_prefab_placement_filter: String = "All"
var map_constructor_prefab_show_diagnostics: bool = true
var map_constructor_prefab_show_expected_invalid: bool = true
var map_constructor_prefab_show_only_placeable_here: bool = false
var map_constructor_prefab_favorites: Dictionary = {}
var map_constructor_prefab_recent_ids: Array[String] = []
var map_constructor_placed_search_text: String = ""
var map_constructor_issue_filter: String = "All"
var map_constructor_selected_issue_id: String = ""
var map_constructor_cleanup_preview: Dictionary = {}
var map_constructor_cleanup_pending_apply_key: String = ""
var map_constructor_autofix_preview: Dictionary = {}
var map_constructor_autofix_pending_apply_key: String = ""
var map_constructor_new_power_network_id: String = "mapedit_power_A"
var map_constructor_patch_json_text: String = ""
var map_constructor_patch_preview: Dictionary = {}
var map_constructor_patch_parsed: Dictionary = {}
var map_constructor_patch_pending_apply: bool = false
var map_constructor_change_history_filter: String = "All"
var map_constructor_multi_selected_entities: Array[Dictionary] = []
var map_constructor_batch_preview: Dictionary = {}
var map_constructor_batch_pending_apply_operation: String = ""
var map_constructor_batch_pending_apply_key: String = ""
var map_constructor_batch_offset_x: int = 0
var map_constructor_batch_offset_y: int = 0
var map_constructor_batch_power_network_id: String = "mapedit_power_A"
var map_constructor_selected_kit_id: String = ""
var map_constructor_selected_template_id: String = ""
var map_constructor_template_rotation: int = 0
var map_constructor_template_mirror_x: bool = false
var map_constructor_template_mirror_y: bool = false
var map_constructor_kit_preview: Dictionary = {}
var map_constructor_template_preview: Dictionary = {}
var map_constructor_kit_pending_apply_key: String = ""
var map_constructor_template_pending_apply_key: String = ""
var map_constructor_kit_preview_can_apply: bool = false
var map_constructor_template_preview_can_apply: bool = false
var map_constructor_design_notes_text: String = ""
var selected_room_visual_preset_id: String = ""
var room_visual_preset_preview: Dictionary = {}
var map_constructor_overlay_mode: String = "None"
var map_constructor_overlay_visibility: Dictionary = {"show_preview": true, "show_validation": true, "show_links": true, "show_power": true, "show_wall_side_arrows": true, "show_multi_select": true}
var map_constructor_pipeline_report: Dictionary = {}
var map_constructor_overview_hud_visible: bool = false
var map_constructor_overview_filter: String = "All"
var map_constructor_overview_show_issues: bool = true
var map_constructor_overview_show_power: bool = true
var map_constructor_overview_show_items: bool = true
var map_constructor_overview_show_wall_mounted: bool = true
var map_constructor_overview_show_history: bool = true

static func _normalize_dictionary_array(value: Variant, preferred_key: String = "") -> Array[Dictionary]:
	var source: Variant = value
	if source is Dictionary:
		var source_dict: Dictionary = Dictionary(source)
		if not preferred_key.is_empty() and source_dict.has(preferred_key):
			source = source_dict.get(preferred_key, [])
		elif source_dict.has("presets"):
			source = source_dict.get("presets", [])
		elif source_dict.has("patches"):
			source = source_dict.get("patches", [])
		elif source_dict.has("entries"):
			source = source_dict.get("entries", [])
		else:
			return []
	var normalized: Array[Dictionary] = []
	if source is Array:
		for entry_variant in Array(source):
			if entry_variant is Dictionary:
				normalized.append(Dictionary(entry_variant))
	return normalized

func reset_selection() -> void:
	selected_map_constructor_prefab_id = ""
	pending_map_constructor_cell = Vector2i(-1, -1)
	selected_map_constructor_entity_kind = ""
	selected_map_constructor_entity_id = ""
	selected_map_constructor_entity_cell = Vector2i(-1, -1)
	selected_map_constructor_wall_side = ""
	available_map_constructor_wall_sides = []

func reset_pending_placement() -> void:
	map_constructor_pending_place_prefab_id = ""
	map_constructor_pending_place_cell = Vector2i(-1, -1)
	map_constructor_pending_place_rotation = 0

func reset_picker() -> void:
	map_constructor_picker_entity_kind = ""
	map_constructor_picker_entity_id = ""
	map_constructor_picker_field_name = ""
