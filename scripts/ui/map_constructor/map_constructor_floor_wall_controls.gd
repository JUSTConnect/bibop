extends RefCounted
class_name MapConstructorFloorWallControls

static func compose_floor_visual_id(material_id: String, _coating_id: String = "") -> String:
	var material: String = material_id.to_lower().strip_edges()
	match material:
		"steel", "concrete", "titan":
			return material
		"titanium":
			return "titan"
		_:
			return "concrete"

static func normalize_floor_height_level(value: String) -> String:
	var normalized_value: String = value.strip_edges().to_lower()
	normalized_value = normalized_value.replace(" ", "")
	normalized_value = normalized_value.replace("-", "")
	normalized_value = normalized_value.replace("_", "")
	match normalized_value:
		"", "empty", "default", "flat", "normal":
			return "default"
		"1", "step1", "low", "groundlow":
			return "step_1"
		"2", "step2", "halflow", "groundhalflow":
			return "step_2"
	return "default"

static func parse_floor_visual_id(visual_id: String) -> Dictionary:
	var normalized: String = visual_id.to_lower().strip_edges()
	var legacy: Dictionary = {
		"default_floor":"concrete",
		"floor_default":"concrete",
		"steel_default":"steel",
		"concrete_default":"concrete",
		"titanium_default":"titan",
		"titan_default":"titan",
		"clean_lab_floor":"steel",
		"dark_service_floor":"concrete",
		"hazard_floor":"concrete",
		"power_floor":"steel",
		"damaged_floor":"concrete",
		"reinforced_floor":"steel",
		"diagnostic_floor":"steel",
		"grate_default":"steel",
		"grate":"steel"
	}
	if legacy.has(normalized):
		normalized = str(legacy[normalized])
	var parts: PackedStringArray = normalized.split("_", false)
	if normalized == "titanium":
		normalized = "titan"
	if normalized in ["steel", "concrete", "titan"]:
		return {"material": normalized, "coating": "default"}
	if parts.size() >= 1 and str(parts[0]) in ["steel", "concrete", "titan"]:
		return {"material": str(parts[0]), "coating": "default"}
	return {"material":"concrete", "coating":"default"}

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

static func _get_wall_side_delta(side_id: String) -> Vector2i:
	match normalize_wall_side(side_id):
		"north":
			return Vector2i(0, -1)
		"east":
			return Vector2i(1, 0)
		"south":
			return Vector2i(0, 1)
		"west":
			return Vector2i(-1, 0)
		_:
			return Vector2i.ZERO


static func _cell_is_wall(ui: Variant, cell: Vector2i) -> bool:
	if ui.mission_manager_runtime != null and ui.mission_manager_runtime.has_method("_is_map_constructor_wall_cell"):
		return bool(ui.mission_manager_runtime.call("_is_map_constructor_wall_cell", cell))
	return false


static func _resolve_wall_layer_material_target(ui: Variant, wall_cell: Vector2i) -> Dictionary:
	for side_id in ["north", "east", "south", "west"]:
		var delta: Vector2i = _get_wall_side_delta(side_id)
		var floor_cell: Vector2i = wall_cell - delta
		if floor_cell.x < 0 or floor_cell.y < 0:
			continue
		if not _cell_is_wall(ui, floor_cell):
			return {"ok": true, "cell": floor_cell, "side": side_id, "wall_cell": wall_cell}
	return {"ok": false}


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
	if ui._safe_ui_string(data.get("object_type", "")).strip_edges().to_lower() == "wall" or ui._safe_ui_string(data.get("object_group", "")).strip_edges().to_lower() == "wall" or ui._safe_ui_string(entity_info.get("entity_kind", "")).strip_edges().to_lower() == "wall":
		var wall_cell: Vector2i = ui._safe_ui_vector2i(entity_info.get("cell", fallback_cell))
		var wall_target: Dictionary = _resolve_wall_layer_material_target(ui, wall_cell)
		if bool(wall_target.get("ok", false)):
			return wall_target
	var selected_side: String = normalize_wall_side(ui.selected_map_constructor_wall_side)
	if not selected_side.is_empty():
		var selected_cell: Vector2i = ui._safe_ui_vector2i(entity_info.get("cell", fallback_cell))
		if selected_cell.x >= 0 and selected_cell.y >= 0:
			return {"ok": true, "cell": selected_cell, "side": selected_side}
	return {"ok": false}

static func add_coverage_sections(ui: Variant, parent: VBoxContainer, entity_info: Dictionary, cell: Vector2i, data: Dictionary, entity_kind: String, entity_id: String, type_group: String, include_floor_coverage: bool = true, include_wall_coverage: bool = true) -> void:
	if include_floor_coverage:
		add_floor_coverage_section(ui, parent)
	if include_wall_coverage:
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
			{"id":"concrete", "label":"Concrete"},
			{"id":"steel", "label":"Steel"},
			{"id":"titan", "label":"Titan"}
		]
		var selected_floor_material_id: String = "concrete"
		var selected_floor_height: String = "default"
		if ui.mission_manager_runtime != null and ui.mission_manager_runtime.has_method("get_map_constructor_floor_material"):
			var current_floor_override: Dictionary = ui._safe_ui_dictionary(ui.mission_manager_runtime.call("get_map_constructor_floor_material", floor_target_cell))
			var current_floor_override_data: Dictionary = ui._safe_ui_dictionary(current_floor_override.get("override", {}))
			selected_floor_material_id = ui._safe_ui_string(current_floor_override_data.get("material_id", "concrete"), "concrete")
			selected_floor_height = normalize_floor_height_level(ui._safe_ui_string(current_floor_override_data.get("floor_height", current_floor_override_data.get("floor_visual_height", current_floor_override_data.get("ground_height", "default"))), "default"))
		var parsed_floor: Dictionary = parse_floor_visual_id(selected_floor_material_id)
		var floor_material_option: OptionButton = OptionButton.new()
		for floor_material in floor_materials:
			floor_material_option.add_item(str(floor_material.get("label", "")))
			floor_material_option.set_item_metadata(floor_material_option.item_count - 1, str(floor_material.get("id", "concrete")))
			if str(floor_material.get("id", "concrete")) == str(parsed_floor.get("material", "concrete")):
				floor_material_option.select(floor_material_option.item_count - 1)
		if floor_material_option.selected < 0:
			floor_material_option.select(0)
		var floor_height_option: OptionButton = OptionButton.new()
		var floor_heights: Array[Dictionary] = [
			{"id":"default", "label":"Default"},
			{"id":"step_1", "label":"1 Step"},
			{"id":"step_2", "label":"2 Step"}
		]
		for floor_height in floor_heights:
			floor_height_option.add_item(str(floor_height.get("label", "")))
			floor_height_option.set_item_metadata(floor_height_option.item_count - 1, str(floor_height.get("id", "default")))
			if str(floor_height.get("id", "default")) == selected_floor_height:
				floor_height_option.select(floor_height_option.item_count - 1)
		if floor_height_option.selected < 0:
			floor_height_option.select(0)
		var floor_row: HBoxContainer = HBoxContainer.new()
		floor_row.add_theme_constant_override("separation", 6)
		floor_material_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		floor_height_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		floor_row.add_child(ui._create_property_row("Material", floor_material_option))
		floor_row.add_child(ui._create_property_row("Height", floor_height_option))
		floor_section.add_child(floor_row)
		var floor_summary_label: Label = Label.new()
		floor_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		floor_summary_label.text = "Floor visual id: %s / height: %s" % [compose_floor_visual_id(str(floor_material_option.get_selected_metadata())), normalize_floor_height_level(str(floor_height_option.get_selected_metadata()))]
		var update_floor_summary := func(_idx: int = 0) -> void:
			floor_summary_label.text = "Floor visual id: %s / height: %s" % [compose_floor_visual_id(str(floor_material_option.get_selected_metadata())), normalize_floor_height_level(str(floor_height_option.get_selected_metadata()))]
		floor_material_option.item_selected.connect(update_floor_summary)
		floor_height_option.item_selected.connect(update_floor_summary)
		floor_section.add_child(floor_summary_label)
		var apply_floor_button: Button = Button.new(); apply_floor_button.text = "Apply Floor Material"
		apply_floor_button.pressed.connect(func() -> void:
			var floor_material_id_apply: String = compose_floor_visual_id(str(floor_material_option.get_selected_metadata()))
			var floor_height_apply: String = normalize_floor_height_level(str(floor_height_option.get_selected_metadata()))
			MapConstructorActions.apply_floor_material(ui, floor_target_cell, floor_material_id_apply, floor_height_apply)
		)
		var clear_floor_button: Button = Button.new(); clear_floor_button.text = "Clear Floor Material"
		clear_floor_button.pressed.connect(func() -> void:
			MapConstructorActions.clear_floor_material(ui, floor_target_cell)
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
			var target_label: Label = Label.new(); target_label.text = "%s / %s" % [str(wall_cell), wall_side]
			wall_section.add_child(ui._create_property_row("Target", target_label))
			wall_section.add_child(ui._create_property_row("Material", material_option))
			wall_section.add_child(description_label)
			var visual_test_note: Label = Label.new()
			visual_test_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			visual_test_note.text = "Production visual mode uses real floor/wall PNG assets; gray assets remain only as an optional debug fallback."
			wall_section.add_child(visual_test_note)
			var selected_wall_height: String = ""
			if ui.mission_manager_runtime != null and ui.mission_manager_runtime.has_method("get_map_constructor_wall_material"):
				var current_wall_override: Dictionary = ui._safe_ui_dictionary(ui.mission_manager_runtime.call("get_map_constructor_wall_material", wall_cell, wall_side))
				var current_wall_row: Dictionary = ui._safe_ui_dictionary(current_wall_override.get("override", {}))
				selected_wall_height = ui._safe_ui_string(current_wall_row.get("wall_height", current_wall_row.get("wall_visual_height", "")))
			var height_option: OptionButton = OptionButton.new()
			var height_rows: Array[Dictionary] = [
				{"id":"", "label":"Auto"},
				{"id":"tall", "label":"Tall"},
				{"id":"halfmid", "label":"Half Mid"},
				{"id":"mid", "label":"Mid"},
				{"id":"halflow", "label":"Half Low"},
				{"id":"low", "label":"Low"}
			]
			for height_row_variant in height_rows:
				var height_row: Dictionary = ui._safe_ui_dictionary(height_row_variant)
				height_option.add_item(ui._safe_ui_string(height_row.get("label", "Auto")))
				height_option.set_item_metadata(height_option.item_count - 1, ui._safe_ui_string(height_row.get("id", "")))
				if ui._safe_ui_string(height_row.get("id", "")) == selected_wall_height:
					height_option.select(height_option.item_count - 1)
			if height_option.selected < 0:
				height_option.select(0)
			wall_section.add_child(ui._create_property_row("Height", height_option))
			var apply_height: Button = Button.new(); apply_height.text = "Apply Wall Height"
			apply_height.pressed.connect(func() -> void:
				MapConstructorActions.apply_wall_height(ui, wall_cell, wall_side, ui._safe_ui_string(height_option.get_selected_metadata()))
			)
			wall_section.add_child(apply_height)
			var apply_material: Button = Button.new(); apply_material.text = "Apply Wall Material"
			apply_material.pressed.connect(func() -> void:
				var mat_id: String = ui._safe_ui_string(material_option.get_selected_metadata())
				MapConstructorActions.apply_wall_material(ui, wall_cell, wall_side, mat_id)
			)
			var clear_material: Button = Button.new(); clear_material.text = "Clear Wall Material"
			clear_material.pressed.connect(func() -> void:
				MapConstructorActions.clear_wall_material(ui, wall_cell, wall_side)
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
			MapConstructorActions.apply_wall_mounted_side(ui, entity_kind, entity_id, ui.selected_map_constructor_wall_side)
		)
		deferred_wall_section.add_child(apply_side)
	if deferred_wall_section != null:
		parent.add_child(deferred_wall_section)
