extends RefCounted
class_name MapConstructorUIBridge


var owner_ui: Object = null
var map_constructor_state: Object = null
var palette_panel: PanelContainer = null
var inspector_panel: PanelContainer = null
var inspector_scroll: ScrollContainer = null
var overview_hud_panel: PanelContainer = null
var overview_hud_scroll: ScrollContainer = null
var validation_overlay_control: Control = null
var place_confirm_panel: PanelContainer = null


func _init(ui_owner: Object = null, state: Object = null) -> void:
	owner_ui = ui_owner
	map_constructor_state = state


func configure(ui_owner: Object, state: Object) -> void:
	owner_ui = ui_owner
	map_constructor_state = state


func set_panel_references(
	palette: PanelContainer,
	inspector: PanelContainer,
	inspector_scroll_ref: ScrollContainer,
	overview: PanelContainer,
	overview_scroll: ScrollContainer,
	validation_overlay: Control,
	place_confirm: PanelContainer
) -> void:
	palette_panel = palette
	inspector_panel = inspector
	inspector_scroll = inspector_scroll_ref
	overview_hud_panel = overview
	overview_hud_scroll = overview_scroll
	validation_overlay_control = validation_overlay
	place_confirm_panel = place_confirm


func update_validation_overlay_reference(validation_overlay: Control) -> void:
	validation_overlay_control = validation_overlay


func get_warning_category_title(category: String) -> String:
	match category:
		"power":
			return "POWER"
		"data":
			return "DATA NETWORK"
		"external":
			return "EXTERNAL LINK"
		"cooling":
			return "COOLING"
		"thermal":
			return "THERMAL"
		"damage":
			return "DAMAGE PREVIEW"
		"overlay":
			return "OVERLAY"
		"storage":
			return "BOX STORAGE"
		"placement":
			return "PLACEMENT"
		"consistency":
			return "CONSISTENCY"
		_:
			return "GENERAL"


func get_warning_category_hint(category: String) -> String:
	match category:
		"power":
			return "Install Battery and Power Block."
		"data":
			return "Install Internal Interface and required data modules."
		"external":
			return "Install External Interface bridge for external devices."
		"cooling":
			return "Add Cooler/Radiator/Air Intake or adjust layout."
		"thermal":
			return "Reduce heat near hot modules or add cooling."
		"damage":
			return "Critical heat can damage modules later."
		"overlay":
			return "Overlay paths are hypothetical until committed."
		"storage":
			return "Check Box Storage availability."
		"placement":
			return "Move cursor or rotate selected module."
		"consistency":
			return "Constructor data needs cleanup."
		_:
			return "Check constructor setup."


func get_warning_severity_role(severity: String) -> String:
	match severity:
		"ok":
			return "ok"
		"info":
			return "info"
		"warning":
			return "warning"
		"danger":
			return "danger"
		_:
			return "neutral"


func make_constructor_warning_item(category: String, severity: String, message: String, hint: String = "") -> Dictionary:
	return {
		"category": category,
		"severity": severity,
		"message": message,
		"hint": hint
	}


func get_constructor_warning_items(readiness_result: Dictionary) -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	for item in readiness_result.get("items", []):
		if item is Dictionary:
			items.append((item as Dictionary).duplicate(true))
	return items


func get_constructor_readiness_state(readiness_result: Dictionary) -> Dictionary:
	return readiness_result.duplicate(true)


func get_warning_severity_rank(severity: String) -> int:
	match severity:
		"danger":
			return 0
		"warning":
			return 1
		"info":
			return 2
		"ok":
			return 3
		_:
			return 4


func sort_warning_items_for_display(items: Array[Dictionary]) -> Array[Dictionary]:
	var sorted_items: Array[Dictionary] = []
	for item in items:
		sorted_items.append(item)
	sorted_items.sort_custom(_compare_warning_items_for_display)
	return sorted_items


func build_warning_panel(readiness_result: Dictionary) -> Control:
	return create_constructor_warning_readiness_panel(readiness_result)


func create_constructor_readiness_banner(readiness_result: Dictionary) -> Control:
	var state: Dictionary = get_constructor_readiness_state(readiness_result)
	var panel: PanelContainer = PanelContainer.new()
	_apply_badge_style(panel, get_warning_severity_role(str(state.get("severity", "warning"))))
	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 3)
	var label: Label = Label.new()
	label.text = str(state.get("label", "NOT READY"))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_owner_label_style(label, false, true)
	root.add_child(label)
	var hint_text_label: Label = Label.new()
	hint_text_label.text = str(state.get("hint", "Review constructor setup."))
	hint_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_owner_label_style(hint_text_label, true, false)
	root.add_child(hint_text_label)
	panel.add_child(root)
	return panel


func create_warning_item_card(item: Dictionary) -> Control:
	var category: String = str(item.get("category", "general"))
	var severity: String = str(item.get("severity", "warning"))
	var message: String = str(item.get("message", "Warning"))
	var hint: String = str(item.get("hint", ""))
	var panel: PanelContainer = PanelContainer.new()
	_apply_badge_style(panel, get_warning_severity_role(severity))
	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 3)
	var title: Label = Label.new()
	title.text = get_warning_category_title(category)
	_apply_owner_label_style(title, false, true)
	root.add_child(title)
	var message_label: Label = Label.new()
	message_label.text = message
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_owner_label_style(message_label, false, false)
	root.add_child(message_label)
	if not hint.is_empty():
		var hint_text_label: Label = Label.new()
		hint_text_label.text = "Next: " + hint
		hint_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_apply_owner_label_style(hint_text_label, true, false)
		root.add_child(hint_text_label)
	panel.add_child(root)
	return panel


func create_constructor_warning_readiness_panel(readiness_result: Dictionary) -> Control:
	var panel: PanelContainer = PanelContainer.new()
	_apply_owner_panel_style(panel, true)
	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var title: Label = Label.new()
	title.text = "READINESS / WARNINGS"
	_apply_owner_label_style(title, false, true)
	root.add_child(title)
	root.add_child(create_constructor_readiness_banner(readiness_result))
	var items: Array[Dictionary] = get_constructor_warning_items(readiness_result)
	if items.is_empty():
		root.add_child(create_warning_item_card(make_constructor_warning_item("general", "ok", "No constructor warnings.", "Configuration is clean for the current rule set.")))
	else:
		var sorted_items: Array[Dictionary] = sort_warning_items_for_display(items)
		var shown_count: int = 0
		var max_shown: int = 6
		for item in sorted_items:
			if shown_count >= max_shown:
				break
			root.add_child(create_warning_item_card(item))
			shown_count += 1
		if sorted_items.size() > max_shown:
			var more_label: Label = Label.new()
			more_label.text = "+%d more. Open Checkpoint for full details." % [sorted_items.size() - max_shown]
			_apply_owner_label_style(more_label, true, false)
			root.add_child(more_label)
	panel.add_child(root)
	return panel


func draw_validation_overlay(control: Control, mission_manager: Object, field_runtime: Node) -> void:
	if map_constructor_state == null:
		return
	if not bool(map_constructor_state.get("map_constructor_mode_active")) or not bool(map_constructor_state.get("map_constructor_validation_overlay_visible")):
		return
	if mission_manager == null or not mission_manager.has_method("get_map_constructor_validation_overlay"):
		return
	if field_runtime == null:
		return
	var renderer_node: Node = field_runtime.get_node_or_null("RoomVisualRenderer")
	if renderer_node == null or not (renderer_node is RoomVisualRenderer):
		return
	var renderer: RoomVisualRenderer = renderer_node
	var overlay: Dictionary = _safe_dictionary(mission_manager.call("get_map_constructor_validation_overlay"))
	var cells: Dictionary = _safe_dictionary(overlay.get("cells", {}))
	for cell_variant in cells.keys():
		var cell: Vector2i = _safe_vector2i(cell_variant)
		var row: Dictionary = _safe_dictionary(cells[cell_variant])
		var severity: String = str(row.get("severity", "none"))
		if severity == "none":
			continue
		var color: Color = Color(0, 0, 0, 0)
		if severity == "error":
			color = Color(0.95, 0.2, 0.2, 0.35)
		elif severity == "warning":
			color = Color(0.95, 0.7, 0.2, 0.35)
		elif severity == "valid":
			color = Color(0.2, 0.9, 0.4, 0.30)
		else:
			continue
		var world_center: Vector2 = renderer.to_global(renderer.grid_to_iso(cell))
		control.draw_circle(world_center, 10.0, color)
		control.draw_arc(world_center, 11.0, 0.0, TAU, 14, Color(color.r, color.g, color.b, 0.9), 2.0)


func sync_overlay_visuals(field_runtime: Node, mission_manager: Object, overlay_links: Array[Dictionary], overlay_power: Array[Dictionary]) -> void:
	if map_constructor_state == null:
		return
	if field_runtime == null:
		return
	var renderer_node: Node = field_runtime.get_node_or_null("RoomVisualRenderer")
	if renderer_node == null or not (renderer_node is RoomVisualRenderer):
		return
	var renderer: RoomVisualRenderer = renderer_node
	renderer.set_map_constructor_overlay_preferences(_safe_dictionary(map_constructor_state.get("map_constructor_overlay_visibility")))
	var cleanup_preview: Dictionary = _safe_dictionary(map_constructor_state.get("map_constructor_cleanup_preview"))
	var overlay_data: Dictionary = {
		"map_constructor_active": bool(map_constructor_state.get("map_constructor_mode_active")),
		"selected": {"cell": _safe_vector2i(map_constructor_state.get("selected_map_constructor_entity_cell")), "wall_side": str(map_constructor_state.get("selected_map_constructor_wall_side"))},
		"hover": {"cell": _safe_vector2i(map_constructor_state.get("pending_map_constructor_cell"))},
		"preview": {"mode": "destructive" if not cleanup_preview.is_empty() else "place", "wall_side": str(map_constructor_state.get("selected_map_constructor_wall_side"))},
		"validation": [],
		"links": overlay_links,
		"power": overlay_power,
		"multi_select": _safe_array(map_constructor_state.get("map_constructor_multi_selected_entities"))
	}
	var room_visual_preview: Dictionary = _safe_dictionary(map_constructor_state.get("room_visual_preset_preview"))
	if not room_visual_preview.is_empty():
		overlay_data["room_visual_preview"] = {
			"walls": _safe_array(room_visual_preview.get("affected_walls", [])).duplicate(true),
			"doors": _safe_array(room_visual_preview.get("affected_doors", [])).duplicate(true),
			"terminals": _safe_array(room_visual_preview.get("affected_terminals", [])).duplicate(true),
			"floors": _safe_array(room_visual_preview.get("affected_floors", [])).duplicate(true)
		}
	if mission_manager != null and mission_manager.has_method("get_map_constructor_validation_issues"):
		overlay_data["validation"] = _safe_array(mission_manager.call("get_map_constructor_validation_issues"))
	renderer.set_map_constructor_overlay_data(overlay_data)


func refresh(owner: Object) -> void:
	if owner != null and owner.has_method("_refresh_map_constructor_panels"):
		owner.call("_refresh_map_constructor_panels")
	update_overlay(owner)


func update_overlay(owner: Object) -> void:
	if owner == null:
		return
	if owner.has_method("_sync_map_constructor_overlay_visuals"):
		owner.call("_sync_map_constructor_overlay_visuals")
	if owner.has_method("_request_map_constructor_field_visual_refresh"):
		owner.call("_request_map_constructor_field_visual_refresh")


func _compare_warning_items_for_display(a: Dictionary, b: Dictionary) -> bool:
	var rank_a: int = get_warning_severity_rank(str(a.get("severity", "warning")))
	var rank_b: int = get_warning_severity_rank(str(b.get("severity", "warning")))
	if rank_a != rank_b:
		return rank_a < rank_b
	return str(a.get("category", "general")) < str(b.get("category", "general"))


func _apply_badge_style(panel: PanelContainer, role: String) -> void:
	if owner_ui == null or not owner_ui.has_method("_make_status_badge_style"):
		return
	var style: StyleBox = owner_ui.call("_make_status_badge_style", role) as StyleBox
	if style != null:
		panel.add_theme_stylebox_override("panel", style)


func _apply_owner_label_style(label: Label, small: bool, bold: bool) -> void:
	if owner_ui != null and owner_ui.has_method("_apply_label_style"):
		owner_ui.call("_apply_label_style", label, small, bold)


func _apply_owner_panel_style(panel: PanelContainer, strong: bool) -> void:
	if owner_ui != null and owner_ui.has_method("_apply_panel_style"):
		owner_ui.call("_apply_panel_style", panel, strong)


func _safe_dictionary(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value
	return {}


func _safe_array(value: Variant) -> Array:
	if value is Array:
		return value
	return []


func _safe_vector2i(value: Variant, fallback: Vector2i = Vector2i(-1, -1)) -> Vector2i:
	if value is Vector2i:
		return value
	if value is Vector2:
		return Vector2i(int(value.x), int(value.y))
	return fallback
