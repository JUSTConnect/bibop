extends RefCounted
class_name MapConstructorObjectPalette

# Map Constructor Objects & Filters / object palette helpers.
# Keep GameUI as the root orchestrator; this helper owns only the Objects tab content.

static func build_object_palette(ui: Variant, parent: VBoxContainer) -> void:
	var list: VBoxContainer = parent
	var search_edit := LineEdit.new()
	search_edit.placeholder_text = "Search prefab (id/name/category/placement)..."
	search_edit.text = ui.map_constructor_prefab_search_text
	search_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search_edit.text_changed.connect(func(new_text: String) -> void:
		ui.map_constructor_prefab_search_text = new_text
		ui._refresh_map_constructor_panels()
	)
	list.add_child(search_edit)
	var category_option := OptionButton.new()
	for category_name in ui.MAP_CONSTRUCTOR_PREFAB_FILTER_CATEGORIES:
		category_option.add_item(category_name)
	var selected_category_index: int = ui.MAP_CONSTRUCTOR_PREFAB_FILTER_CATEGORIES.find(ui.map_constructor_prefab_category_filter)
	if selected_category_index < 0:
		selected_category_index = 0
		ui.map_constructor_prefab_category_filter = ui.MAP_CONSTRUCTOR_PREFAB_FILTER_CATEGORIES[0]
	category_option.select(selected_category_index)
	category_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	category_option.item_selected.connect(func(index: int) -> void:
		if index >= 0 and index < ui.MAP_CONSTRUCTOR_PREFAB_FILTER_CATEGORIES.size():
			ui.map_constructor_prefab_category_filter = ui.MAP_CONSTRUCTOR_PREFAB_FILTER_CATEGORIES[index]
			ui._refresh_map_constructor_panels()
	)
	list.add_child(category_option)
	var role_option: OptionButton = OptionButton.new()
	for role_name in ui.MAP_CONSTRUCTOR_PREFAB_FILTER_ROLES:
		role_option.add_item(role_name)
	role_option.select(maxi(0, ui.MAP_CONSTRUCTOR_PREFAB_FILTER_ROLES.find(ui.map_constructor_prefab_role_filter)))
	role_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	role_option.item_selected.connect(func(index: int) -> void:
		if index >= 0 and index < ui.MAP_CONSTRUCTOR_PREFAB_FILTER_ROLES.size():
			ui.map_constructor_prefab_role_filter = ui.MAP_CONSTRUCTOR_PREFAB_FILTER_ROLES[index]
			ui._refresh_map_constructor_panels())
	list.add_child(role_option)
	var placement_option: OptionButton = OptionButton.new()
	for mode_name in ui.MAP_CONSTRUCTOR_PREFAB_FILTER_PLACEMENT_MODES:
		placement_option.add_item(mode_name)
	placement_option.select(maxi(0, ui.MAP_CONSTRUCTOR_PREFAB_FILTER_PLACEMENT_MODES.find(ui.map_constructor_prefab_placement_filter)))
	placement_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	placement_option.item_selected.connect(func(index: int) -> void:
		if index >= 0 and index < ui.MAP_CONSTRUCTOR_PREFAB_FILTER_PLACEMENT_MODES.size():
			ui.map_constructor_prefab_placement_filter = ui.MAP_CONSTRUCTOR_PREFAB_FILTER_PLACEMENT_MODES[index]
			ui._refresh_map_constructor_panels())
	list.add_child(placement_option)
	var show_diag: CheckBox = CheckBox.new(); show_diag.text = "Show Diagnostics"; show_diag.button_pressed = ui.map_constructor_prefab_show_diagnostics; show_diag.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	show_diag.toggled.connect(func(v: bool) -> void: ui.map_constructor_prefab_show_diagnostics = v; ui._refresh_map_constructor_panels())
	list.add_child(show_diag)
	var show_invalid: CheckBox = CheckBox.new(); show_invalid.text = "Show Expected Invalid"; show_invalid.button_pressed = ui.map_constructor_prefab_show_expected_invalid; show_invalid.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	show_invalid.toggled.connect(func(v: bool) -> void: ui.map_constructor_prefab_show_expected_invalid = v; ui._refresh_map_constructor_panels())
	list.add_child(show_invalid)
	var show_placeable: CheckBox = CheckBox.new(); show_placeable.text = "Show Only Placeable Here"; show_placeable.button_pressed = ui.map_constructor_prefab_show_only_placeable_here; show_placeable.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	show_placeable.toggled.connect(func(v: bool) -> void: ui.map_constructor_prefab_show_only_placeable_here = v; ui._refresh_map_constructor_panels())
	list.add_child(show_placeable)

	if not ui.selected_map_constructor_prefab_id.is_empty():
		var mount_row: HBoxContainer = HBoxContainer.new()
		mount_row.add_theme_constant_override("separation", 4)
		var mount_label: Label = Label.new()
		mount_label.text = "Mount:"
		mount_row.add_child(mount_label)
		for mode_id in ["stationary", "wall_mounted"]:
			var mode_button: Button = Button.new()
			mode_button.text = "Stationary" if mode_id == "stationary" else "Wall-mounted"
			mode_button.toggle_mode = true
			mode_button.button_pressed = ui.selected_map_constructor_mounting_mode == mode_id
			mode_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			mode_button.pressed.connect(func() -> void:
				ui.selected_map_constructor_mounting_mode = mode_id
				if ui.selected_map_constructor_mounting_mode == "stationary":
					ui.selected_map_constructor_wall_side = ""
				if ui.pending_map_constructor_cell.x >= 0 and ui.pending_map_constructor_cell.y >= 0:
					ui._update_map_constructor_preview_for_cell(ui.pending_map_constructor_cell)
				ui._refresh_map_constructor_panels()
			)
			mount_row.add_child(mode_button)
		list.add_child(mount_row)
	var catalog: Array[Dictionary] = []
	if ui.mission_manager_runtime != null and ui.mission_manager_runtime.has_method("get_map_constructor_prefab_palette_rows"):
		var palette_rows: Dictionary = ui.mission_manager_runtime.call("get_map_constructor_prefab_palette_rows", {
			"search": ui.map_constructor_prefab_search_text,
			"category": ui.map_constructor_prefab_category_filter,
			"role": ui.map_constructor_prefab_role_filter,
			"placement_mode": ui.map_constructor_prefab_placement_filter,
			"show_expected_invalid": ui.map_constructor_prefab_show_expected_invalid,
			"show_diagnostics": ui.map_constructor_prefab_show_diagnostics,
			"show_only_placeable_here": ui.map_constructor_prefab_show_only_placeable_here,
			"selected_cell": ui.pending_map_constructor_cell
		})
		for row_variant in ui._safe_ui_array(palette_rows.get("rows", [])):
			if row_variant is Dictionary:
				catalog.append((row_variant as Dictionary).duplicate(true))
	var catalog_by_id: Dictionary = {}
	for entry in catalog:
		catalog_by_id[ui._safe_ui_string(entry.get("id", ""))] = entry
	var grouped_entries: Dictionary = {}
	for group_name in ui.MAP_CONSTRUCTOR_PREFAB_CATEGORY_GROUP_ORDER:
		grouped_entries[group_name] = []
	var selected_visible: bool = false
	for entry in catalog:
		if not ui._map_constructor_prefab_matches_filters(entry):
			continue
		var group_name: String = ui._get_map_constructor_prefab_group_name(entry)
		if group_name.is_empty() or not grouped_entries.has(group_name):
			group_name = "Utility"
			if not grouped_entries.has(group_name):
				grouped_entries[group_name] = []
		var group_entries: Array = grouped_entries[group_name]
		group_entries.append(entry)
		grouped_entries[group_name] = group_entries
	var favorite_entries: Array[Dictionary] = []
	for favorite_id_variant in ui.map_constructor_prefab_favorites.keys():
		var favorite_id: String = str(favorite_id_variant)
		if not bool(ui.map_constructor_prefab_favorites.get(favorite_id, false)) or not catalog_by_id.has(favorite_id):
			continue
		var favorite_entry: Dictionary = ui._safe_ui_dictionary(catalog_by_id[favorite_id])
		if ui._map_constructor_prefab_matches_filters(favorite_entry):
			favorite_entries.append(favorite_entry)
	favorite_entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("label", a.get("id", ""))) < str(b.get("label", b.get("id", "")) )
	)
	var recent_entries: Array[Dictionary] = []
	for recent_id in ui.map_constructor_prefab_recent_ids:
		if not catalog_by_id.has(recent_id):
			continue
		var recent_entry: Dictionary = ui._safe_ui_dictionary(catalog_by_id[recent_id])
		if ui._map_constructor_prefab_matches_filters(recent_entry):
			recent_entries.append(recent_entry)
	var visible_prefab_card_count: int = 0
	for section in [{"name":"Favorites","entries":favorite_entries},{"name":"Recent","entries":recent_entries}]:
		var section_entries: Array = ui._safe_ui_array(section.get("entries", []))
		if section_entries.is_empty():
			continue
		var section_header: Label = Label.new()
		section_header.text = str(section.get("name", ""))
		list.add_child(section_header)
		for entry in section_entries:
			var card: Button = ui._create_map_constructor_prefab_card(entry)
			if card.button_pressed:
				selected_visible = true
			visible_prefab_card_count += 1
			list.add_child(card)
	for group_name in ui.MAP_CONSTRUCTOR_PREFAB_CATEGORY_GROUP_ORDER:
		var entries: Array = grouped_entries[group_name]
		if entries.is_empty():
			continue
		var header := Label.new()
		header.text = group_name
		list.add_child(header)
		for entry in entries:
			var card: Button = ui._create_map_constructor_prefab_card(entry)
			if card.button_pressed:
				selected_visible = true
			visible_prefab_card_count += 1
			list.add_child(card)
	if visible_prefab_card_count <= 0:
		var empty_prefab_label: Label = Label.new()
		empty_prefab_label.text = "No objects match the current filters. Clear search/filters to show all objects."
		empty_prefab_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_prefab_label.add_theme_color_override("font_color", ui.UI_COLOR_WARNING)
		list.add_child(empty_prefab_label)
	if not selected_visible and not ui.selected_map_constructor_prefab_id.is_empty():
		ui.selected_map_constructor_prefab_id = ""
		ui.selected_map_constructor_wall_side = ""
		ui.available_map_constructor_wall_sides.clear()
		ui.pending_map_constructor_cell = Vector2i(-1, -1)
		ui._clear_map_constructor_preview_cell()
	var placement_label: Label = Label.new()
	placement_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	placement_label.text = "Placement: blocked: unsupported prefab (mode: %s)" % ui.selected_map_constructor_mounting_mode
	if ui.pending_map_constructor_cell.x >= 0 and ui.pending_map_constructor_cell.y >= 0 and not ui.selected_map_constructor_prefab_id.is_empty():
		if ui.mission_manager_runtime != null and ui.mission_manager_runtime.has_method("can_place_map_constructor_prefab"):
			var check: Dictionary = ui._update_map_constructor_preview_for_cell(ui.pending_map_constructor_cell)
			if selected_visible:
				list.add_child(ui._create_map_constructor_wall_side_picker(str(check.get("placement_mode", ""))))
			var reason: String = str(check.get("reason", "unsupported_prefab"))
			match reason:
				"ok":
					placement_label.text = "Placement: OK (mode: %s)" % ui.selected_map_constructor_mounting_mode
				"existing_object", "occupied_by_bipob":
					placement_label.text = "Placement: blocked: existing object"
				"out_of_bounds":
					placement_label.text = "Placement: blocked: out of bounds"
				"exit_cell":
					placement_label.text = "Placement: blocked: exit cell"
				"wall_or_static":
					placement_label.text = "Placement: blocked: wall/static obstacle"
				"non_floor_tile":
					placement_label.text = "Placement: blocked: non-floor tile"
				_:
					placement_label.text = "Placement: blocked: unsupported prefab"
			if str(check.get("placement_mode", "")) == "wall_mounted":
				placement_label.text += "\nWall side: %s (R to cycle)" % ui._get_map_constructor_wall_side_label(str(check.get("wall_side", ui.selected_map_constructor_wall_side)))
	list.add_child(placement_label)
	var favorite_toggle: Button = Button.new()
	var selected_is_favorite: bool = bool(ui.map_constructor_prefab_favorites.get(ui.selected_map_constructor_prefab_id, false))
	favorite_toggle.text = "★ Unfavorite Selected" if selected_is_favorite else "☆ Favorite Selected"
	favorite_toggle.disabled = ui.selected_map_constructor_prefab_id.is_empty()
	favorite_toggle.pressed.connect(func() -> void:
		if ui.selected_map_constructor_prefab_id.is_empty():
			return
		var favorite_now: bool = not bool(ui.map_constructor_prefab_favorites.get(ui.selected_map_constructor_prefab_id, false))
		ui.map_constructor_prefab_favorites[ui.selected_map_constructor_prefab_id] = favorite_now
		ui._refresh_map_constructor_panels()
	)
	list.add_child(favorite_toggle)
	var placed_title: Label = Label.new()
	placed_title.text = "Placed Objects"
	list.add_child(placed_title)
	var placed_search: LineEdit = LineEdit.new()
	placed_search.placeholder_text = "Search placed objects..."
	placed_search.text = ui.map_constructor_placed_search_text
	placed_search.text_changed.connect(func(new_text: String) -> void:
		ui.map_constructor_placed_search_text = new_text
		ui._refresh_map_constructor_panels()
	)
	list.add_child(placed_search)
	var placed_rows: Array[Dictionary] = ui._build_map_constructor_placed_object_rows()
	var selected_row_exists: bool = ui.selected_map_constructor_entity_id.is_empty()
	for row in placed_rows:
		var row_entity_id: String = str(row.get("id", ""))
		var row_entity_kind: String = str(row.get("entity_kind", ""))
		if row_entity_id == ui.selected_map_constructor_entity_id and row_entity_kind == ui.selected_map_constructor_entity_kind:
			selected_row_exists = true
	for row in placed_rows:
		if not ui._map_constructor_placed_row_matches_search(row):
			continue
		var row_cell: Vector2i = ui._safe_ui_vector2i(row.get("cell", Vector2i(-1, -1)))
		var row_anchor_cell: Vector2i = ui._safe_ui_vector2i(row.get("anchor_floor_cell", row_cell))
		var row_entity_id: String = str(row.get("id", ""))
		var row_entity_kind: String = str(row.get("entity_kind", ""))
		var row_selected: bool = row_entity_id == ui.selected_map_constructor_entity_id and row_entity_kind == ui.selected_map_constructor_entity_kind
		var row_button: Button = Button.new()
		var row_text: String = "%s | %s | c:%s | %s" % [str(row.get("id", "")), str(row.get("type_or_prefab", "")), str(row_cell), str(row.get("category_or_placement", ""))]
		if str(row.get("placement_mode", "")) == "wall_mounted":
			row_text += " | a:%s w:%s side:%s" % [str(row_anchor_cell), str(ui._safe_ui_vector2i(row.get("attached_wall_cell", Vector2i(-1, -1)))), str(row.get("wall_side", ""))]
		if row_selected:
			row_text = "▶ " + row_text
		row_button.text = row_text
		row_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row_button.pressed.connect(func() -> void:
			ui._select_map_constructor_entity_from_browser(row)
			ui._refresh_map_constructor_panels()
		)
		list.add_child(row_button)
	if not selected_row_exists:
		ui._clear_map_constructor_browser_selection()
	var browser_selection_label: Label = Label.new()
	browser_selection_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if ui.selected_map_constructor_entity_id.is_empty() or ui.selected_map_constructor_entity_kind.is_empty():
		browser_selection_label.text = "Browser selection: none"
	else:
		browser_selection_label.text = "Browser selection: %s/%s @ %s" % [ui.selected_map_constructor_entity_kind, ui.selected_map_constructor_entity_id, str(ui.selected_map_constructor_entity_cell)]
	list.add_child(browser_selection_label)


static func prefab_matches_filters(ui: Variant, entry: Dictionary) -> bool:
	var search_text: String = ui.map_constructor_prefab_search_text.strip_edges().to_lower()
	var prefab_id: String = ui._safe_ui_string(entry.get("id", ""))
	var label_text: String = ui._safe_ui_string(entry.get("display_name", entry.get("label", "")))
	var category_text: String = ui._safe_ui_string(entry.get("category", ""))
	var placement_mode: String = ui._safe_ui_string(entry.get("placement_mode", "")).to_lower()
	var roles_text: String = format_variant_list(ui, entry.get("system_roles", []))
	var tags_text: String = format_variant_list(ui, entry.get("tags", []))
	var description: String = ui._safe_ui_string(entry.get("description", ""))
	if ui.map_constructor_prefab_category_filter != "All" and category_text != ui.map_constructor_prefab_category_filter:
		return false
	if ui.map_constructor_prefab_role_filter != "All" and not get_variant_string_list(ui, entry.get("system_roles", [])).has(ui.map_constructor_prefab_role_filter):
		return false
	if ui.map_constructor_prefab_placement_filter != "All" and placement_mode != ui.map_constructor_prefab_placement_filter:
		return false
	if search_text.is_empty():
		return true
	var haystack: String = "%s %s %s %s %s %s %s" % [prefab_id.to_lower(), label_text.to_lower(), category_text.to_lower(), placement_mode.to_lower(), roles_text.to_lower(), tags_text.to_lower(), description.to_lower()]
	return haystack.find(search_text) >= 0

static func prefab_matches_category_filter(ui: Variant, prefab_id: String, category_text: String, category_filter: String) -> bool:
	match category_filter:
		"Control":
			return ui.MAP_CONSTRUCTOR_CONTROL_PREFAB_IDS.has(prefab_id)
		"Power":
			return ui.MAP_CONSTRUCTOR_POWER_PREFAB_IDS.has(prefab_id)
		_:
			return category_text == category_filter

static func get_prefab_group_name(ui: Variant, entry: Dictionary) -> String:
	var prefab_id: String = ui._safe_ui_string(entry.get("id", ""))
	var category_text: String = ui._safe_ui_string(entry.get("category", ""))
	var placement_mode: String = ui._safe_ui_string(entry.get("placement_mode", ""))
	if placement_mode == "wall_mounted":
		return "Wall-mounted"
	if ui.MAP_CONSTRUCTOR_POWER_PREFAB_IDS.has(prefab_id):
		return "Power"
	if ui.MAP_CONSTRUCTOR_CONTROL_PREFAB_IDS.has(prefab_id):
		return "Control"
	match category_text:
		"Floors", "Walls", "Doors", "Terminals", "Items":
			return category_text
	return ""


static func mark_prefab_recent(ui: Variant, prefab_id: String) -> void:
	var normalized_id: String = prefab_id.strip_edges()
	if normalized_id.is_empty():
		return
	ui.map_constructor_prefab_recent_ids.erase(normalized_id)
	ui.map_constructor_prefab_recent_ids.push_front(normalized_id)
	if ui.map_constructor_prefab_recent_ids.size() > ui.MAP_CONSTRUCTOR_PREFAB_RECENT_LIMIT:
		ui.map_constructor_prefab_recent_ids.resize(ui.MAP_CONSTRUCTOR_PREFAB_RECENT_LIMIT)

static func select_prefab(ui: Variant, prefab_id: String) -> void:
	ui.selected_map_constructor_prefab_id = prefab_id
	ui.selected_map_constructor_wall_side = ""
	ui.selected_map_constructor_mounting_mode = "stationary"
	if ui.mission_manager_runtime != null and ui.mission_manager_runtime.has_method("get_map_constructor_prefab_metadata"):
		var metadata_result: Dictionary = ui._safe_ui_dictionary(ui.mission_manager_runtime.call("get_map_constructor_prefab_metadata", prefab_id))
		var metadata: Dictionary = ui._safe_ui_dictionary(metadata_result.get("prefab", {}))
		if ui._safe_ui_string(metadata.get("placement_mode", "")).to_lower() == "wall_mounted":
			ui.selected_map_constructor_mounting_mode = "wall_mounted"
	elif ui.mission_manager_runtime != null and ui.mission_manager_runtime.has_method("get_map_constructor_prefab_catalog"):
		var catalog_entries: Array = ui._safe_ui_array(ui.mission_manager_runtime.call("get_map_constructor_prefab_catalog"))
		for entry_variant in catalog_entries:
			if not (entry_variant is Dictionary):
				continue
			var entry: Dictionary = ui._safe_ui_dictionary(entry_variant)
			if ui._safe_ui_string(entry.get("id", "")) != prefab_id:
				continue
			if ui._safe_ui_string(entry.get("placement_mode", "")).to_lower() == "wall_mounted":
				ui.selected_map_constructor_mounting_mode = "wall_mounted"
			break
	var wall_mounted_prefab_defaults: Dictionary = {"light": true, "light_switch": true, "fuse_box": true, "circuit_breaker": true}
	if bool(wall_mounted_prefab_defaults.get(prefab_id.strip_edges().to_lower(), false)):
		ui.selected_map_constructor_mounting_mode = "wall_mounted"
	ui.available_map_constructor_wall_sides.clear()
	ui.pending_map_constructor_cell = Vector2i(-1, -1)
	ui._clear_map_constructor_pending_placement()
	ui._clear_map_constructor_preview_cell()
	mark_prefab_recent(ui, prefab_id)

static func get_variant_string_list(ui: Variant, value: Variant) -> Array[String]:
	var items: Array[String] = []
	if value == null:
		return items
	if value is Array or value is PackedStringArray:
		for item: Variant in value:
			var item_text: String = ui._safe_ui_string(item).strip_edges()
			if not item_text.is_empty():
				items.append(item_text)
		return items
	var scalar_text: String = ui._safe_ui_string(value).strip_edges()
	if not scalar_text.is_empty():
		items.append(scalar_text)
	return items

static func format_variant_list(ui: Variant, value: Variant, separator: String = ", ") -> String:
	return separator.join(get_variant_string_list(ui, value))

static func get_prefab_placeability(entry: Dictionary) -> Dictionary:
	var placeability: Dictionary = {}
	var placeability_variant: Variant = entry.get("placeability", {})
	if placeability_variant is Dictionary:
		placeability = placeability_variant.duplicate(true)
	return placeability

static func get_prefab_preview_kind(ui: Variant, entry: Dictionary) -> String:
	var prefab_id: String = ui._safe_ui_string(entry.get("id", "")).to_lower()
	var category_text: String = ui._safe_ui_string(entry.get("category", "")).to_lower()
	var placement_mode: String = ui._safe_ui_string(entry.get("placement_mode", "")).to_lower()
	var tags_text: String = format_variant_list(ui, entry.get("tags", []), " ").to_lower()
	var roles_text: String = format_variant_list(ui, entry.get("system_roles", []), " ").to_lower()
	var combined: String = "%s %s %s %s %s" % [prefab_id, category_text, placement_mode, tags_text, roles_text]
	if placement_mode == "wall_mounted":
		return "wall_mounted"
	if combined.find("cool") >= 0:
		return "cooling"
	if combined.find("door") >= 0 or combined.find("gate") >= 0:
		return "door"
	if combined.find("terminal") >= 0 or combined.find("firewall") >= 0:
		return "terminal"
	if combined.find("power") >= 0 or combined.find("socket") >= 0 or combined.find("cable") >= 0 or combined.find("switch") >= 0 or combined.find("fuse") >= 0:
		return "power"
	if category_text == "item" or category_text == "items" or combined.find("key") >= 0 or combined.find("item") >= 0:
		return "item"
	if category_text == "structural" or combined.find("wall") >= 0 or combined.find("floor") >= 0 or combined.find("structural") >= 0:
		return "structural"
	if category_text == "diagnostic" or combined.find("diagnostic") >= 0:
		return "diagnostic"
	return "utility"

static func get_prefab_preview_symbol(preview_kind: String) -> String:
	match preview_kind:
		"structural":
			return "W"
		"door":
			return "D"
		"terminal":
			return "T"
		"power":
			return "P"
		"item":
			return "I"
		"cooling":
			return "C"
		"wall_mounted":
			return "M"
		"diagnostic":
			return "?"
		_:
			return "U"

static func get_prefab_preview_label(preview_kind: String) -> String:
	match preview_kind:
		"structural":
			return "Structure"
		"door":
			return "Door"
		"terminal":
			return "Terminal"
		"power":
			return "Power"
		"item":
			return "Item"
		"cooling":
			return "Cooling"
		"wall_mounted":
			return "Wall"
		"diagnostic":
			return "Diag"
		_:
			return "Utility"

static func get_prefab_preview_color(preview_kind: String) -> Color:
	match preview_kind:
		"structural":
			return Color(0.360, 0.410, 0.470, 1.0)
		"door":
			return Color(0.620, 0.430, 0.210, 1.0)
		"terminal":
			return Color(0.180, 0.520, 0.820, 1.0)
		"power":
			return Color(0.900, 0.720, 0.180, 1.0)
		"item":
			return Color(0.610, 0.780, 0.950, 1.0)
		"cooling":
			return Color(0.190, 0.730, 0.820, 1.0)
		"wall_mounted":
			return Color(0.520, 0.500, 0.760, 1.0)
		"diagnostic":
			return Color(0.960, 0.580, 0.170, 1.0)
		_:
			return Color(0.430, 0.560, 0.520, 1.0)

static func format_prefab_placeability(ui: Variant, entry: Dictionary) -> Dictionary:
	if bool(entry.get("is_expected_invalid_tool", false)):
		return {"text":"Expected invalid", "role":"warning"}
	if entry.has("placeability"):
		var placeability: Dictionary = get_prefab_placeability(entry)
		if bool(placeability.get("ok", false)):
			return {"text":"Placeable", "role":"ok"}
		var message: String = ui._safe_ui_string(placeability.get("message", "Not placeable here."), "Not placeable here.").strip_edges()
		if message.is_empty():
			message = "Not placeable here."
		return {"text":"Not placeable here — %s" % message, "role":"danger"}
	var placement_hint: String = ui._safe_ui_string(entry.get("placement_hint", "")).strip_edges()
	if placement_hint.is_empty():
		placement_hint = "choose a target cell"
	return {"text":"Placeable — %s" % placement_hint, "role":"info"}

static func create_prefab_preview(ui: Variant, entry: Dictionary) -> Control:
	var preview_kind: String = get_prefab_preview_kind(ui, entry)
	var placement_mode: String = ui._safe_ui_string(entry.get("placement_mode", "unknown"), "unknown")
	var preview_panel: PanelContainer = PanelContainer.new()
	preview_panel.custom_minimum_size = Vector2(56, 64)
	preview_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	preview_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	preview_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var preview_color: Color = get_prefab_preview_color(preview_kind)
	preview_panel.add_theme_stylebox_override("panel", ui._make_panel_style(preview_color.darkened(0.28), preview_color.lightened(0.20), 2, 8))
	var preview_stack: VBoxContainer = VBoxContainer.new()
	preview_stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	preview_stack.add_theme_constant_override("separation", 0)
	preview_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_panel.add_child(preview_stack)

	# Symbolic preview: use entry-provided preview/icon text when available, otherwise fall back to category letters.
	var symbol_text: String = ui._safe_ui_string(entry.get("preview_symbol", entry.get("icon_symbol", ""))).strip_edges()
	if symbol_text.is_empty():
		symbol_text = get_prefab_preview_symbol(preview_kind)
	var symbol_label: Label = Label.new()
	symbol_label.text = symbol_text
	symbol_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	symbol_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	symbol_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	symbol_label.add_theme_color_override("font_color", Color.WHITE)
	symbol_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_stack.add_child(symbol_label)

	var kind_label: Label = Label.new()
	kind_label.text = get_prefab_preview_label(preview_kind)
	kind_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kind_label.clip_text = true
	kind_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	kind_label.add_theme_color_override("font_color", ui.UI_COLOR_TEXT)
	kind_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_stack.add_child(kind_label)

	var mode_label: Label = Label.new()
	mode_label.text = "wall" if placement_mode == "wall_mounted" else placement_mode
	mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mode_label.clip_text = true
	mode_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	mode_label.add_theme_color_override("font_color", ui.UI_COLOR_TEXT_DIM)
	mode_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_stack.add_child(mode_label)
	return preview_panel

static func create_prefab_tile(ui: Variant, entry: Dictionary) -> Button:
	var prefab_id: String = ui._safe_ui_string(entry.get("id", ""))
	var selected: bool = prefab_id == ui.selected_map_constructor_prefab_id
	var card: Button = Button.new()
	card.toggle_mode = true
	card.button_pressed = selected
	card.text = ""
	card.clip_text = true
	card.custom_minimum_size = Vector2(0, 132)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var border_color: Color = ui.UI_COLOR_SELECTED if selected else ui.UI_COLOR_BORDER_DIM
	var bg_color: Color = Color(0.105, 0.125, 0.155, 0.98) if selected else ui.UI_COLOR_PANEL_DARK
	card.add_theme_stylebox_override("normal", ui._make_panel_style(bg_color, border_color, 2 if selected else 1, 8))
	card.add_theme_stylebox_override("hover", ui._make_panel_style(bg_color.lightened(0.08), ui.UI_COLOR_ACCENT, 2, 8))
	card.add_theme_stylebox_override("pressed", ui._make_panel_style(ui.UI_COLOR_SELECTED.darkened(0.55), ui.UI_COLOR_SELECTED, 2, 8))
	card.add_theme_stylebox_override("focus", ui._make_panel_style(bg_color, ui.UI_COLOR_SELECTED, 2, 8))

	var row: HBoxContainer = HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 8
	row.offset_right = -8
	row.offset_top = 6
	row.offset_bottom = -6
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(row)
	row.add_child(create_prefab_preview(ui, entry))

	var text_stack: VBoxContainer = VBoxContainer.new()
	text_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_stack.clip_contents = true
	text_stack.add_theme_constant_override("separation", 2)
	text_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(text_stack)

	var display_name: String = ui._safe_ui_string(entry.get("display_name", entry.get("label", prefab_id)), prefab_id)
	var title_label: Label = Label.new()
	title_label.text = ("▶ " if selected else "") + display_name
	title_label.tooltip_text = display_name
	title_label.clip_text = true
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title_label.add_theme_color_override("font_color", ui.UI_COLOR_SELECTED if selected else ui.UI_COLOR_TEXT)
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_stack.add_child(title_label)

	var category_text: String = ui._safe_ui_string(entry.get("category", "Uncategorized"), "Uncategorized")
	var placement_mode: String = ui._safe_ui_string(entry.get("placement_mode", "unknown"), "unknown")
	var roles_text: String = format_variant_list(ui, entry.get("system_roles", []))
	if roles_text.is_empty():
		roles_text = "no role"
	var meta_label: Label = Label.new()
	meta_label.text = "id: %s • %s • %s • %s" % [prefab_id, category_text, placement_mode, roles_text]
	meta_label.tooltip_text = meta_label.text
	meta_label.clip_text = true
	meta_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	meta_label.add_theme_color_override("font_color", ui.UI_COLOR_TEXT_DIM)
	meta_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_stack.add_child(meta_label)

	var description: String = ui._safe_ui_string(entry.get("description", "")).strip_edges()
	if description.is_empty():
		description = ui._safe_ui_string(entry.get("placement_hint", "No description available."), "No description available.")
	var description_label: Label = Label.new()
	description_label.text = description
	description_label.tooltip_text = description
	description_label.clip_text = true
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.max_lines_visible = 2
	description_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	description_label.add_theme_color_override("font_color", ui.UI_COLOR_TEXT)
	description_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_stack.add_child(description_label)

	var status: Dictionary = format_prefab_placeability(ui, entry)
	var prefab_status_label: Label = Label.new()
	prefab_status_label.text = ui._safe_ui_string(status.get("text", "Placeability unknown"), "Placeability unknown")
	prefab_status_label.tooltip_text = prefab_status_label.text
	prefab_status_label.clip_text = true
	prefab_status_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	match ui._safe_ui_string(status.get("role", "neutral"), "neutral"):
		"ok":
			prefab_status_label.add_theme_color_override("font_color", ui.UI_COLOR_OK)
		"warning":
			prefab_status_label.add_theme_color_override("font_color", ui.UI_COLOR_WARNING)
		"danger":
			prefab_status_label.add_theme_color_override("font_color", ui.UI_COLOR_DANGER)
		"info":
			prefab_status_label.add_theme_color_override("font_color", ui.UI_COLOR_ACCENT)
		_:
			prefab_status_label.add_theme_color_override("font_color", ui.UI_COLOR_TEXT_DIM)
	prefab_status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_stack.add_child(prefab_status_label)

	if ui.map_constructor_prefab_show_diagnostics:
		var diagnostic_bits: Array[String] = []
		if bool(entry.get("is_destructive", false)):
			diagnostic_bits.append("destructive")
		if bool(entry.get("can_have_links", false)):
			diagnostic_bits.append("links")
		if bool(entry.get("can_have_power_network", false)):
			diagnostic_bits.append("power network")
		if bool(entry.get("requires_wall", false)):
			diagnostic_bits.append("requires wall")
		if bool(entry.get("requires_floor", false)):
			diagnostic_bits.append("requires floor")
		if entry.has("placeability"):
			var placeability: Dictionary = get_prefab_placeability(entry)
			var reason: String = ui._safe_ui_string(placeability.get("reason", "")).strip_edges()
			if not reason.is_empty() and reason != "ok":
				diagnostic_bits.append(reason)
		if not diagnostic_bits.is_empty():
			var prefab_diagnostic_label: Label = Label.new()
			prefab_diagnostic_label.text = "Diagnostics: %s" % ", ".join(diagnostic_bits)
			prefab_diagnostic_label.tooltip_text = prefab_diagnostic_label.text
			prefab_diagnostic_label.max_lines_visible = 1
			prefab_diagnostic_label.clip_text = true
			prefab_diagnostic_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			prefab_diagnostic_label.add_theme_color_override("font_color", ui.UI_COLOR_TEXT_DIM)
			prefab_diagnostic_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			text_stack.add_child(prefab_diagnostic_label)
	card.pressed.connect(func() -> void:
		select_prefab(ui, prefab_id)
		ui._refresh_map_constructor_panels()
	)
	return card
