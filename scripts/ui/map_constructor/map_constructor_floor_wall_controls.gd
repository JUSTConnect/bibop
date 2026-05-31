extends RefCounted
class_name MapConstructorFloorWallControls

static func compose_floor_visual_id(material_id: String, coating_id: String) -> String:
	var material: String = material_id.to_lower().strip_edges()
	var coating: String = coating_id.to_lower().strip_edges()
	if material.is_empty():
		material = "steel"
	if coating.is_empty():
		coating = "default"
	return "%s_%s" % [material, coating]

static func parse_floor_visual_id(visual_id: String) -> Dictionary:
	var normalized: String = visual_id.to_lower().strip_edges()
	var legacy: Dictionary = {
		"default_floor":"steel_default",
		"clean_lab_floor":"steel_default",
		"dark_service_floor":"concrete_dirty",
		"hazard_floor":"steel_oil",
		"power_floor":"grate_default",
		"damaged_floor":"concrete_destroyed",
		"reinforced_floor":"steel_default",
		"diagnostic_floor":"grate_default"
	}
	if legacy.has(normalized):
		normalized = String(legacy[normalized])
	var parts: PackedStringArray = normalized.split("_", false)
	if parts.size() >= 2:
		return {"material": String(parts[0]), "coating": String(parts[1])}
	return {"material":"steel", "coating":"default"}

static func normalize_wall_side(side_id: String) -> String:
	var normalized: String = side_id.to_lower().strip_edges()
	if normalized in ["north", "east", "south", "west"]:
		return normalized
	return ""

static func get_wall_side_label(side_id: String) -> String:
	match normalize_wall_side(side_id):
		"north":
			return "North"
		"east":
			return "East"
		"south":
			return "South"
		"west":
			return "West"
		_:
			return side_id.capitalize()

static func create_wall_side_picker(ui: Variant, placement_mode: String) -> Control:
	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	if placement_mode != "wall_mounted":
		return root
	var title: Label = Label.new()
	title.text = "Wall Side"
	root.add_child(title)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	var canonical_sides: Array[String] = ["north", "east", "south", "west"]
	for side_id in canonical_sides:
		var side_button: Button = Button.new()
		side_button.text = get_wall_side_label(side_id)
		side_button.toggle_mode = true
		side_button.button_pressed = ui.selected_map_constructor_wall_side == side_id
		var available: bool = ui.available_map_constructor_wall_sides.has(side_id)
		side_button.disabled = not available
		side_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		side_button.pressed.connect(func() -> void:
			if not ui.available_map_constructor_wall_sides.has(side_id):
				ui.show_hint("Wall side %s is not available for this cell." % get_wall_side_label(side_id))
				return
			ui.selected_map_constructor_wall_side = side_id
			if ui.pending_map_constructor_cell.x >= 0 and ui.pending_map_constructor_cell.y >= 0:
				ui._update_map_constructor_preview_for_cell(ui.pending_map_constructor_cell)
			ui._refresh_map_constructor_panels()
		)
		row.add_child(side_button)
	root.add_child(row)
	var selected_label: Label = Label.new()
	if ui.selected_map_constructor_wall_side.is_empty():
		selected_label.text = "Selected: n/a"
	else:
		selected_label.text = "Selected: %s" % get_wall_side_label(ui.selected_map_constructor_wall_side)
	root.add_child(selected_label)
	if ui.available_map_constructor_wall_sides.is_empty():
		var hint_label_local: Label = Label.new()
		hint_label_local.text = "No wall sides available for this target."
		root.add_child(hint_label_local)
	return root

static func resolve_wall_material_target_for_selection(ui: Variant, entity_info: Dictionary, data: Dictionary, fallback_cell: Vector2i) -> Dictionary:
	if ui._safe_ui_string(data.get("placement_mode", "")) == "wall_mounted":
		var anchor_cell: Vector2i = ui._safe_ui_vector2i(data.get("anchor_floor_cell", Vector2i(-1, -1)))
		var side: String = normalize_wall_side(ui._safe_ui_string(data.get("wall_side", "")))
		if anchor_cell.x >= 0 and anchor_cell.y >= 0 and not side.is_empty():
			return {"ok": true, "cell": anchor_cell, "side": side}
	var selected_side: String = normalize_wall_side(ui.selected_map_constructor_wall_side)
	if not selected_side.is_empty():
		var selected_cell: Vector2i = ui._safe_ui_vector2i(entity_info.get("cell", fallback_cell))
		if selected_cell.x >= 0 and selected_cell.y >= 0:
			return {"ok": true, "cell": selected_cell, "side": selected_side}
	return {"ok": false}

static func add_coverage_sections(ui: Variant, parent: VBoxContainer, entity_info: Dictionary, cell: Vector2i, data: Dictionary, entity_kind: String, entity_id: String, type_group: String) -> void:
	add_floor_coverage_section(ui, parent)
	add_wall_coverage_section(ui, parent, entity_info, cell, data, entity_kind, entity_id, type_group)

static func add_floor_coverage_section(ui: Variant, parent: VBoxContainer) -> void:
	var floor_section: VBoxContainer = ui._create_inspector_section("7. Floor Coverage")
	var floor_target_cell: Vector2i = ui.pending_map_constructor_cell
	if floor_target_cell.x < 0 or floor_target_cell.y < 0:
		floor_target_cell = ui.selected_map_constructor_entity_cell
	var floor_target_label: Label = Label.new()
	floor_target_label.text = str(floor_target_cell)
	floor_section.add_child(ui._create_property_row("Target", floor_target_label))
	if floor_target_cell.x >= 0 and floor_target_cell.y >= 0:
		var floor_materials: Array[Dictionary] = [
			{"id":"steel", "label":"Сталь"},
			{"id":"concrete", "label":"Бетон"},
			{"id":"grate", "label":"Решетка"}
		]
		var floor_coatings: Array[Dictionary] = [
			{"id":"default", "label":"Дефолт"},
			{"id":"destroyed", "label":"Разрушен"},
			{"id":"dirty", "label":"Грязь"},
			{"id":"water", "label":"Вода"},
			{"id":"oil", "label":"Масло"}
		]
		var selected_floor_material_id: String = "steel_default"
		if ui.mission_manager_runtime != null and ui.mission_manager_runtime.has_method("get_map_constructor_floor_material"):
			var current_floor_override: Dictionary = ui._safe_ui_dictionary(ui.mission_manager_runtime.call("get_map_constructor_floor_material", floor_target_cell))
			selected_floor_material_id = ui._safe_ui_string(ui._safe_ui_dictionary(current_floor_override.get("override", {})).get("material_id", "steel_default"), "steel_default")
		var parsed_floor: Dictionary = parse_floor_visual_id(selected_floor_material_id)
		var floor_material_option: OptionButton = OptionButton.new()
		var floor_coating_option: OptionButton = OptionButton.new()
		for floor_material in floor_materials:
			floor_material_option.add_item(String(floor_material.get("label", "")))
			floor_material_option.set_item_metadata(floor_material_option.item_count - 1, String(floor_material.get("id", "steel")))
			if String(floor_material.get("id", "steel")) == String(parsed_floor.get("material", "steel")):
				floor_material_option.select(floor_material_option.item_count - 1)
		for floor_coating in floor_coatings:
			floor_coating_option.add_item(String(floor_coating.get("label", "")))
			floor_coating_option.set_item_metadata(floor_coating_option.item_count - 1, String(floor_coating.get("id", "default")))
			if String(floor_coating.get("id", "default")) == String(parsed_floor.get("coating", "default")):
				floor_coating_option.select(floor_coating_option.item_count - 1)
		if floor_material_option.selected < 0:
			floor_material_option.select(0)
		if floor_coating_option.selected < 0:
			floor_coating_option.select(0)
		var floor_row: HBoxContainer = HBoxContainer.new()
		floor_row.add_theme_constant_override("separation", 6)
		floor_material_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		floor_coating_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		floor_row.add_child(ui._create_property_row("Материал", floor_material_option))
		floor_row.add_child(ui._create_property_row("Покрытие", floor_coating_option))
		floor_section.add_child(floor_row)
		var floor_summary_label: Label = Label.new()
		floor_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		floor_summary_label.text = "Floor visual id: %s" % compose_floor_visual_id(String(floor_material_option.get_selected_metadata()), String(floor_coating_option.get_selected_metadata()))
		var update_floor_summary := func(_idx: int = 0) -> void:
			floor_summary_label.text = "Floor visual id: %s" % compose_floor_visual_id(String(floor_material_option.get_selected_metadata()), String(floor_coating_option.get_selected_metadata()))
		floor_material_option.item_selected.connect(update_floor_summary)
		floor_coating_option.item_selected.connect(update_floor_summary)
		floor_section.add_child(floor_summary_label)
		var apply_floor_button: Button = Button.new(); apply_floor_button.text = "Apply Floor Material"
		apply_floor_button.pressed.connect(func() -> void:
			if ui.mission_manager_runtime == null or not ui.mission_manager_runtime.has_method("set_map_constructor_floor_material"):
				return
			var floor_material_id_apply: String = compose_floor_visual_id(String(floor_material_option.get_selected_metadata()), String(floor_coating_option.get_selected_metadata()))
			var floor_apply_result: Dictionary = ui._safe_ui_dictionary(ui.mission_manager_runtime.call("set_map_constructor_floor_material", floor_target_cell, floor_material_id_apply))
			ui.show_hint(ui._safe_ui_string(floor_apply_result.get("message", "Floor material updated."), "Floor material updated."))
			ui._refresh_map_constructor_panels()
			if ui.field_runtime != null and ui.field_runtime.has_method("request_visual_refresh"): ui.field_runtime.call("request_visual_refresh")
			ui._show_map_constructor_inspector(ui.selected_map_constructor_entity_cell, ui.selected_map_constructor_entity_kind, ui.selected_map_constructor_entity_id)
		)
		var clear_floor_button: Button = Button.new(); clear_floor_button.text = "Clear Floor Material"
		clear_floor_button.pressed.connect(func() -> void:
			if ui.mission_manager_runtime == null or not ui.mission_manager_runtime.has_method("clear_map_constructor_floor_material"):
				return
			var floor_clear_result: Dictionary = ui._safe_ui_dictionary(ui.mission_manager_runtime.call("clear_map_constructor_floor_material", floor_target_cell))
			ui.show_hint(ui._safe_ui_string(floor_clear_result.get("message", "Floor material cleared."), "Floor material cleared."))
			ui._refresh_map_constructor_panels()
			if ui.field_runtime != null and ui.field_runtime.has_method("request_visual_refresh"): ui.field_runtime.call("request_visual_refresh")
			ui._show_map_constructor_inspector(ui.selected_map_constructor_entity_cell, ui.selected_map_constructor_entity_kind, ui.selected_map_constructor_entity_id)
		)
		floor_section.add_child(apply_floor_button)
		floor_section.add_child(clear_floor_button)
	else:
		var floor_missing_label: Label = Label.new()
		floor_missing_label.text = "Select or hover a valid cell to edit floor materials."
		floor_section.add_child(floor_missing_label)
	parent.add_child(floor_section)

static func add_wall_coverage_section(ui: Variant, parent: VBoxContainer, entity_info: Dictionary, cell: Vector2i, data: Dictionary, entity_kind: String, entity_id: String, type_group: String) -> void:
	var deferred_wall_section: VBoxContainer = null
	var wall_target: Dictionary = resolve_wall_material_target_for_selection(ui, entity_info, data, cell)
	if type_group != "item" and (type_group == "wall" or ui._safe_ui_string(data.get("placement_mode", "")) == "wall_mounted" or not ui.selected_map_constructor_wall_side.is_empty()):
		var wall_section: VBoxContainer = ui._create_inspector_section("8. Wall Coverage")
		if bool(wall_target.get("ok", false)):
			var wall_cell: Vector2i = ui._safe_ui_vector2i(wall_target.get("cell", Vector2i(-1, -1)))
			var wall_side: String = ui._safe_ui_string(wall_target.get("side", ""))
			var catalog_result: Dictionary = {"materials": []}
			if ui.mission_manager_runtime != null and ui.mission_manager_runtime.has_method("get_map_constructor_wall_material_catalog"):
				catalog_result = ui._safe_ui_dictionary(ui.mission_manager_runtime.call("get_map_constructor_wall_material_catalog"))
			var material_option: OptionButton = OptionButton.new()
			var material_rows: Array = ui._safe_ui_array(catalog_result.get("materials", []))
			var selected_material_id: String = ""
			if ui.mission_manager_runtime != null and ui.mission_manager_runtime.has_method("get_map_constructor_wall_material"):
				var current_override: Dictionary = ui._safe_ui_dictionary(ui.mission_manager_runtime.call("get_map_constructor_wall_material", wall_cell, wall_side))
				selected_material_id = ui._safe_ui_string(ui._safe_ui_dictionary(current_override.get("override", {})).get("material_id", ""))
			var description_label: Label = Label.new()
			for row_variant in material_rows:
				var material_row: Dictionary = ui._safe_ui_dictionary(row_variant)
				var material_id: String = ui._safe_ui_string(material_row.get("id", ""))
				material_option.add_item(ui._safe_ui_string(material_row.get("display_name", material_id), material_id))
				var added_index: int = material_option.item_count - 1
				material_option.set_item_metadata(added_index, material_id)
				if selected_material_id == material_id:
					material_option.select(added_index)
					description_label.text = ui._safe_ui_string(material_row.get("description", ""))
			if material_option.item_count > 0 and material_option.selected < 0:
				material_option.select(0)
			material_option.item_selected.connect(func(_idx: int) -> void:
				var current_id: String = ui._safe_ui_string(material_option.get_selected_metadata())
				for row_variant_inner in material_rows:
					var material_row_inner: Dictionary = ui._safe_ui_dictionary(row_variant_inner)
					if ui._safe_ui_string(material_row_inner.get("id", "")) == current_id:
						description_label.text = ui._safe_ui_string(material_row_inner.get("description", ""))
						break
			)
			wall_section.add_child(ui._create_property_row("Target", Label.new()))
			var target_label: Label = Label.new(); target_label.text = "%s / %s" % [str(wall_cell), wall_side]
			wall_section.add_child(target_label)
			wall_section.add_child(ui._create_property_row("Material", material_option))
			wall_section.add_child(description_label)
			var apply_material: Button = Button.new(); apply_material.text = "Apply Wall Material"
			apply_material.pressed.connect(func() -> void:
				if ui.mission_manager_runtime == null or not ui.mission_manager_runtime.has_method("set_map_constructor_wall_material"):
					ui.show_hint("Wall material action unavailable.")
					return
				var mat_id: String = ui._safe_ui_string(material_option.get_selected_metadata())
				var apply_result: Dictionary = ui._safe_ui_dictionary(ui.mission_manager_runtime.call("set_map_constructor_wall_material", wall_cell, wall_side, mat_id))
				ui.show_hint(ui._safe_ui_string(apply_result.get("message", "Wall material updated."), "Wall material updated."))
				ui._refresh_map_constructor_panels()
				if ui.field_runtime != null and ui.field_runtime.has_method("request_visual_refresh"): ui.field_runtime.call("request_visual_refresh")
				ui._show_map_constructor_inspector(ui.selected_map_constructor_entity_cell, ui.selected_map_constructor_entity_kind, ui.selected_map_constructor_entity_id)
			)
			var clear_material: Button = Button.new(); clear_material.text = "Clear Wall Material"
			clear_material.pressed.connect(func() -> void:
				if ui.mission_manager_runtime == null or not ui.mission_manager_runtime.has_method("clear_map_constructor_wall_material"):
					ui.show_hint("Wall material action unavailable.")
					return
				var clear_result: Dictionary = ui._safe_ui_dictionary(ui.mission_manager_runtime.call("clear_map_constructor_wall_material", wall_cell, wall_side))
				ui.show_hint(ui._safe_ui_string(clear_result.get("message", "Wall material cleared."), "Wall material cleared."))
				ui._refresh_map_constructor_panels()
				if ui.field_runtime != null and ui.field_runtime.has_method("request_visual_refresh"): ui.field_runtime.call("request_visual_refresh")
				ui._show_map_constructor_inspector(ui.selected_map_constructor_entity_cell, ui.selected_map_constructor_entity_kind, ui.selected_map_constructor_entity_id)
			)
			wall_section.add_child(apply_material)
			wall_section.add_child(clear_material)
		else:
			var missing_label: Label = Label.new()
			missing_label.text = "Select a wall side or wall-mounted anchor to edit wall material."
			wall_section.add_child(missing_label)
		deferred_wall_section = wall_section
	if ui._safe_ui_string(data.get("placement_mode", "")) == "wall_mounted" and ui.mission_manager_runtime != null and ui.mission_manager_runtime.has_method("get_map_constructor_wall_mounted_status"):
		if deferred_wall_section == null:
			deferred_wall_section = ui._create_inspector_section("8. Wall Coverage")
		var wm: Dictionary = ui._safe_ui_dictionary(ui.mission_manager_runtime.call("get_map_constructor_wall_mounted_status", entity_kind, entity_id))
		ui._set_map_constructor_wall_mounted_selection(ui._safe_ui_vector2i(wm.get("anchor_floor_cell", Vector2i(-1,-1))), ui._safe_ui_vector2i(wm.get("attached_wall_cell", Vector2i(-1,-1))), entity_id)
		var anchor_label: Label = Label.new()
		anchor_label.text = ui._safe_ui_string(wm.get("anchor_floor_cell", Vector2i(-1, -1)), str(Vector2i(-1, -1)))
		deferred_wall_section.add_child(ui._create_property_row("anchor_floor_cell", anchor_label))
		var attached_label: Label = Label.new()
		attached_label.text = ui._safe_ui_string(wm.get("attached_wall_cell", Vector2i(-1, -1)), str(Vector2i(-1, -1)))
		deferred_wall_section.add_child(ui._create_property_row("attached_wall_cell", attached_label))
		var wall_side_picker: Control = create_wall_side_picker(ui, "wall_mounted")
		deferred_wall_section.add_child(ui._create_property_row("wall_side", wall_side_picker))
		var apply_side: Button = Button.new(); apply_side.text = "Apply Side"
		apply_side.pressed.connect(func() -> void:
			var selected_side: String = normalize_wall_side(ui.selected_map_constructor_wall_side)
			if selected_side.is_empty():
				ui.show_hint("Select a valid wall side before applying.")
				return
			if ui.mission_manager_runtime == null or not ui.mission_manager_runtime.has_method("set_map_constructor_wall_mounted_side"):
				ui.show_hint("Wall-mounted side action unavailable.")
				return
			var rr: Dictionary = ui._safe_ui_dictionary(ui.mission_manager_runtime.call("set_map_constructor_wall_mounted_side", entity_kind, entity_id, selected_side))
			ui.show_hint(ui._safe_ui_string(rr.get("message", "Updated side."), "Updated side."))
			ui._refresh_map_constructor_panels()
			if ui.field_runtime != null and ui.field_runtime.has_method("request_visual_refresh"): ui.field_runtime.call("request_visual_refresh")
			ui._show_map_constructor_inspector(ui.selected_map_constructor_entity_cell, ui.selected_map_constructor_entity_kind, ui.selected_map_constructor_entity_id)
		)
		deferred_wall_section.add_child(apply_side)
	if deferred_wall_section != null:
		parent.add_child(deferred_wall_section)
