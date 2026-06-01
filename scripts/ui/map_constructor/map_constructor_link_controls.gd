extends RefCounted
class_name MapConstructorLinkControls

static func add_link_picker(ui: Variant, section: VBoxContainer, entity_kind: String, entity_id: String, link_type: String, title: String) -> void:
	if ui.mission_manager_runtime == null or not ui.mission_manager_runtime.has_method("get_map_constructor_entity_by_id"):
		return
	var entity_info: Dictionary = ui.mission_manager_runtime.call("get_map_constructor_entity_by_id", entity_kind, entity_id)
	if not bool(entity_info.get("ok", false)):
		return
	var data: Dictionary = {}
	var data_variant: Variant = entity_info.get("data", {})
	if data_variant is Dictionary:
		data = data_variant.duplicate(true)
	var field_map: Dictionary = {"linked_terminal":"linked_terminal_id","linked_door":"target_door_id","power_network":"power_network_id","control_source":"control_source_id","terminal_target":"target_door_id","platform_target":"target_platform_id","power_source":"power_source_id","control_terminal":"control_terminal_id","access_terminal":"access_terminal_id"}
	if not field_map.has(link_type):
		return
	var field_name: String = ui._safe_ui_string(field_map[link_type])
	var current_target: String = ui._safe_ui_string(data.get(field_name, "")).strip_edges()
	var title_label: Label = Label.new(); title_label.text = title
	section.add_child(title_label)
	var current_label: Label = Label.new(); current_label.text = "Current: %s" % (current_target if not current_target.is_empty() else "(none)")
	section.add_child(current_label)
	if ui.mission_manager_runtime.has_method("get_map_constructor_link_candidates"):
		for candidate in ui._safe_ui_array(ui.mission_manager_runtime.call("get_map_constructor_link_candidates", entity_kind, entity_id, link_type)):
			var c: Dictionary = ui._safe_ui_dictionary(candidate)
			var cid: String = ui._safe_ui_string(c.get("id", ""))
			var prefix: String = "✓ " if bool(c.get("current", false)) or cid == current_target else ""
			var label_text: String = "%s%s [%s] %s" % [prefix, cid, ui._safe_ui_string(c.get("object_type", "obj")), ui._safe_ui_string(c.get("cell", ""))]
			var button: Button = Button.new(); button.text = label_text
			button.pressed.connect(func() -> void:
				var result: Dictionary = ui.mission_manager_runtime.call("set_map_constructor_entity_link", entity_kind, entity_id, link_type, cid)
				ui.show_hint(ui._safe_ui_string(result.get("message", "Link updated."), "Link updated."))
				var target_cell: Vector2i = ui._safe_ui_vector2i(result.get("target_cell", Vector2i(-1, -1)))
				if target_cell.x >= 0 and target_cell.y >= 0:
					ui._set_map_constructor_link_target(target_cell, ui._safe_ui_string(result.get("target_id", cid), cid))
				ui._refresh_map_constructor_panels()
				if ui.field_runtime != null and ui.field_runtime.has_method("request_visual_refresh"):
					ui.field_runtime.call("request_visual_refresh")
				ui._show_map_constructor_inspector(ui.selected_map_constructor_entity_cell, ui.selected_map_constructor_entity_kind, ui.selected_map_constructor_entity_id)
			)
			section.add_child(button)
	var actions: HFlowContainer = HFlowContainer.new()
	var show_button: Button = Button.new(); show_button.text = "Show Target"
	show_button.pressed.connect(func() -> void:
		if current_target.is_empty():
			ui.show_hint("No linked target.")
			return
		if link_type == "power_network" and ui.mission_manager_runtime.has_method("get_map_constructor_link_candidates"):
			var candidates: Array = ui._safe_ui_array(ui.mission_manager_runtime.call("get_map_constructor_link_candidates", entity_kind, entity_id, link_type))
			for candidate_variant in candidates:
				var candidate: Dictionary = ui._safe_ui_dictionary(candidate_variant)
				if ui._safe_ui_string(candidate.get("id", "")) != current_target:
					continue
				var candidate_cell: Vector2i = ui._safe_ui_vector2i(candidate.get("cell", Vector2i(-1, -1)))
				if candidate_cell.x < 0 or candidate_cell.y < 0:
					ui.show_hint("Power network has no single map target.")
					return
				break
		if ui.mission_manager_runtime.has_method("get_map_constructor_entity_by_id"):
			var target_entity: Dictionary = ui.mission_manager_runtime.call("get_map_constructor_entity_by_id", "world_object", current_target)
			if bool(target_entity.get("ok", false)):
				ui._set_map_constructor_link_target(ui._safe_ui_vector2i(target_entity.get("cell", Vector2i(-1, -1))), current_target)
			elif link_type == "power_network":
				ui.show_hint("Power network has no single map target.")
	)
	actions.add_child(show_button)
	var clear_button: Button = Button.new(); clear_button.text = "Clear Link"
	clear_button.pressed.connect(func() -> void:
		var result: Dictionary = ui.mission_manager_runtime.call("set_map_constructor_entity_link", entity_kind, entity_id, link_type, "")
		ui.show_hint(ui._safe_ui_string(result.get("message", "Link cleared."), "Link cleared."))
		ui._clear_map_constructor_link_target()
		ui._refresh_map_constructor_panels()
		ui._show_map_constructor_inspector(ui.selected_map_constructor_entity_cell, ui.selected_map_constructor_entity_kind, ui.selected_map_constructor_entity_id)
	)
	actions.add_child(clear_button)
	var jump_button: Button = Button.new(); jump_button.text = "Jump/Select Target"
	jump_button.pressed.connect(func() -> void:
		if current_target.is_empty() or ui.mission_manager_runtime == null:
			return
		var target_entity: Dictionary = ui.mission_manager_runtime.call("get_map_constructor_entity_by_id", "world_object", current_target)
		if bool(target_entity.get("ok", false)):
			var target_cell: Vector2i = ui._safe_ui_vector2i(target_entity.get("cell", Vector2i(-1, -1)))
			ui._focus_map_constructor_cell(target_cell)
			ui._show_map_constructor_inspector(target_cell, "world_object", current_target)
	)
	actions.add_child(jump_button)
	section.add_child(actions)

static func get_map_constructor_key_entity_by_id(ui: Variant, key_id: String) -> Dictionary:
	var normalized_key_id: String = key_id.strip_edges()
	if normalized_key_id.is_empty() or ui.mission_manager_runtime == null:
		return {}
	if ui.mission_manager_runtime.has_method("find_map_constructor_key_item_by_id"):
		return ui._safe_ui_dictionary(ui.mission_manager_runtime.call("find_map_constructor_key_item_by_id", normalized_key_id))
	if ui.mission_manager_runtime.has_method("get_map_constructor_entity_by_id"):
		return ui._safe_ui_dictionary(ui.mission_manager_runtime.call("get_map_constructor_entity_by_id", "item", normalized_key_id))
	return {}

static func is_map_constructor_key_item(ui: Variant, data: Dictionary, type_group: String) -> bool:
	if type_group != "item":
		return false
	if ui._safe_ui_string(data.get("item_type", "")).strip_edges().to_lower() == "key":
		return true
	if not ui._safe_ui_string(data.get("key_type", "")).strip_edges().is_empty() or not ui._safe_ui_string(data.get("key_kind", "")).strip_edges().is_empty():
		return true
	for field_name in ["prefab", "prefab_id", "category", "item_category", "metadata_category", "object_group", "item_group", "kind", "role"]:
		var token: String = ui._safe_ui_string(data.get(field_name, "")).strip_edges().to_lower()
		if token == "key" or token.begins_with("key_") or token.ends_with("_key") or token.contains("_key_"):
			return true
	var id_token: String = ui._safe_ui_string(data.get("id", "")).strip_edges().to_lower()
	return id_token == "key" or id_token.begins_with("key_") or id_token.ends_with("_key") or id_token.contains("_key_")

static func add_key_door_link_section(ui: Variant, parent: VBoxContainer, entity_kind: String, entity_id: String, data: Dictionary) -> void:
	if ui.mission_manager_runtime == null or not ui.mission_manager_runtime.has_method("get_map_constructor_key_door_link_candidates"):
		return
	var section: VBoxContainer = ui._create_inspector_section("Door Link")
	var current_id: String = ui._safe_ui_string(data.get("linked_door_id", "")).strip_edges()
	var current_label: Label = Label.new()
	current_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	current_label.text = "Unlocks Door: %s" % (current_id if not current_id.is_empty() else "(none)")
	section.add_child(current_label)
	var candidates: Dictionary = ui._safe_ui_dictionary(ui.mission_manager_runtime.call("get_map_constructor_key_door_link_candidates", entity_kind, entity_id))
	var doors: Array = ui._safe_ui_array(candidates.get("doors", []))
	if doors.is_empty():
		var none_label: Label = Label.new()
		none_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		none_label.text = ui._safe_ui_string(candidates.get("message", "No compatible doors placed on the map."))
		section.add_child(none_label)
	else:
		var option: OptionButton = OptionButton.new()
		for door_variant in doors:
			var door: Dictionary = ui._safe_ui_dictionary(door_variant)
			option.add_item(ui._safe_ui_string(door.get("label", door.get("id", "Door"))))
			var option_index: int = option.item_count - 1
			var door_id: String = ui._safe_ui_string(door.get("id", ""))
			option.set_item_metadata(option_index, door_id)
			if door_id == current_id:
				option.select(option_index)
		if option.selected < 0 and option.item_count > 0:
			option.select(0)
		section.add_child(ui._create_property_row("Door", option))
		var link_button: Button = Button.new()
		link_button.text = "Link Selected Door"
		link_button.pressed.connect(func() -> void:
			var door_id: String = ui._safe_ui_string(option.get_selected_metadata())
			var result: Dictionary = ui.mission_manager_runtime.call("set_map_constructor_entity_link", entity_kind, entity_id, "key_door", door_id)
			ui.show_hint(ui._safe_ui_string(result.get("message", "Door linked."), "Door linked."))
			ui._refresh_map_constructor_panels()
			if ui.field_runtime != null and ui.field_runtime.has_method("request_visual_refresh"):
				ui.field_runtime.call("request_visual_refresh")
			ui._show_map_constructor_inspector(ui.selected_map_constructor_entity_cell, ui.selected_map_constructor_entity_kind, ui.selected_map_constructor_entity_id)
		)
		section.add_child(link_button)
	if not current_id.is_empty():
		var unlink_button: Button = Button.new()
		unlink_button.text = "Unlink Door"
		unlink_button.pressed.connect(func() -> void:
			var result: Dictionary = ui.mission_manager_runtime.call("set_map_constructor_entity_link", entity_kind, entity_id, "key_door", "")
			ui.show_hint(ui._safe_ui_string(result.get("message", "Door unlinked."), "Door unlinked."))
			ui._clear_map_constructor_link_target()
			ui._refresh_map_constructor_panels()
			if ui.field_runtime != null and ui.field_runtime.has_method("request_visual_refresh"):
				ui.field_runtime.call("request_visual_refresh")
			ui._show_map_constructor_inspector(ui.selected_map_constructor_entity_cell, ui.selected_map_constructor_entity_kind, ui.selected_map_constructor_entity_id)
		)
		section.add_child(unlink_button)
	parent.add_child(section)

static func add_door_linked_key_section(ui: Variant, parent: VBoxContainer, _entity_id: String, data: Dictionary) -> void:
	var section: VBoxContainer = ui._create_inspector_section("Linked Key")
	var key_id: String = ui._safe_ui_string(data.get("required_key_id", "")).strip_edges()
	var label: Label = Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if key_id.is_empty():
		label.text = "No key linked."
	else:
		var key_entity: Dictionary = get_map_constructor_key_entity_by_id(ui, key_id)
		var key_data: Dictionary = ui._safe_ui_dictionary(key_entity.get("data", {}))
		if bool(key_entity.get("ok", false)):
			label.text = "%s — %s at %s" % [ui._safe_ui_string(key_data.get("display_name", key_id), key_id), key_id, str(ui._safe_ui_vector2i(key_entity.get("cell", Vector2i(-1, -1))))]
		else:
			label.text = "Linked key missing: %s" % key_id
	section.add_child(label)
	if not key_id.is_empty():
		var jump_button: Button = Button.new()
		jump_button.text = "Jump/Select Key"
		jump_button.pressed.connect(func() -> void:
			var key_entity: Dictionary = get_map_constructor_key_entity_by_id(ui, key_id)
			if bool(key_entity.get("ok", false)):
				var key_cell: Vector2i = ui._safe_ui_vector2i(key_entity.get("cell", Vector2i(-1, -1)))
				ui._focus_map_constructor_cell(key_cell)
				ui._show_map_constructor_inspector(key_cell, ui._safe_ui_string(key_entity.get("entity_kind", "item"), "item"), key_id)
		)
		section.add_child(jump_button)
	parent.add_child(section)

static func add_door_required_key_picker(ui: Variant, parent: VBoxContainer, entity_kind: String, entity_id: String, data: Dictionary) -> void:
	if ui.mission_manager_runtime == null or not ui.mission_manager_runtime.has_method("get_map_constructor_link_targets_for_field"):
		return
	var section: VBoxContainer = ui._create_inspector_section("Key Binding")
	var current_key_id: String = ui._safe_ui_string(data.get("required_key_id", "")).strip_edges()
	var option: OptionButton = OptionButton.new()
	option.add_item("(no key)")
	option.set_item_metadata(0, {"id":"", "entity_kind":"item"})
	if current_key_id.is_empty():
		option.select(0)
	var current_key_found: bool = current_key_id.is_empty()
	var raw_candidates: Dictionary = ui._safe_ui_dictionary(ui.mission_manager_runtime.call("get_map_constructor_link_targets_for_field", entity_kind, entity_id, "required_key_id"))
	for candidate_variant in ui._safe_ui_array(raw_candidates.get("targets", [])):
		var candidate: Dictionary = ui._safe_ui_dictionary(candidate_variant)
		var candidate_id: String = ui._safe_ui_string(candidate.get("id", "")).strip_edges()
		if candidate_id.is_empty() or candidate_id == "__none__":
			continue
		var candidate_kind: String = ui._safe_ui_string(candidate.get("kind", "item"), "item")
		option.add_item(ui._safe_ui_string(candidate.get("label", candidate_id), candidate_id))
		var option_index: int = option.item_count - 1
		option.set_item_metadata(option_index, {"id": candidate_id, "entity_kind": candidate_kind})
		if candidate_id == current_key_id:
			current_key_found = true
			option.select(option_index)
	if not current_key_found:
		var current_key_entity: Dictionary = get_map_constructor_key_entity_by_id(ui, current_key_id)
		var current_key_label: String = ui._safe_ui_string(current_key_entity.get("label", current_key_id), current_key_id)
		option.add_item(current_key_label)
		var current_option_index: int = option.item_count - 1
		option.set_item_metadata(current_option_index, {"id": current_key_id, "entity_kind": ui._safe_ui_string(current_key_entity.get("entity_kind", "item"), "item")})
		option.select(current_option_index)
	section.add_child(ui._create_property_row("Required key", option))
	var actions: HFlowContainer = HFlowContainer.new()
	var apply_button: Button = Button.new()
	apply_button.text = "Bind Selected Key"
	apply_button.pressed.connect(func() -> void:
		var selected: Dictionary = ui._safe_ui_dictionary(option.get_selected_metadata())
		var selected_key_id: String = ui._safe_ui_string(selected.get("id", "")).strip_edges()
		if not current_key_id.is_empty() and current_key_id != selected_key_id and ui.mission_manager_runtime.has_method("set_map_constructor_entity_link"):
			ui.mission_manager_runtime.call("set_map_constructor_entity_link", "item", current_key_id, "key_door", "")
		if selected_key_id.is_empty():
			if ui.mission_manager_runtime.has_method("set_map_constructor_entity_link") and not current_key_id.is_empty():
				var clear_result: Dictionary = ui.mission_manager_runtime.call("set_map_constructor_entity_link", "item", current_key_id, "key_door", "")
				ui.show_hint(ui._safe_ui_string(clear_result.get("message", "Key binding cleared."), "Key binding cleared."))
			else:
				ui.show_hint("No key selected.")
		else:
			var selected_kind: String = ui._safe_ui_string(selected.get("entity_kind", "item"), "item")
			var result: Dictionary = ui.mission_manager_runtime.call("set_map_constructor_entity_link", selected_kind, selected_key_id, "key_door", entity_id)
			ui.show_hint(ui._safe_ui_string(result.get("message", "Key binding updated."), "Key binding updated."))
		ui._refresh_map_constructor_panels()
		if ui.field_runtime != null and ui.field_runtime.has_method("request_visual_refresh"):
			ui.field_runtime.call("request_visual_refresh")
		ui._show_map_constructor_inspector(ui.selected_map_constructor_entity_cell, ui.selected_map_constructor_entity_kind, ui.selected_map_constructor_entity_id)
	)
	actions.add_child(apply_button)
	if not current_key_id.is_empty():
		var clear_button: Button = Button.new()
		clear_button.text = "Clear Key Binding"
		clear_button.pressed.connect(func() -> void:
			var clear_result: Dictionary = ui.mission_manager_runtime.call("set_map_constructor_entity_link", "item", current_key_id, "key_door", "")
			ui.show_hint(ui._safe_ui_string(clear_result.get("message", "Key binding cleared."), "Key binding cleared."))
			ui._clear_map_constructor_link_target()
			ui._refresh_map_constructor_panels()
			if ui.field_runtime != null and ui.field_runtime.has_method("request_visual_refresh"):
				ui.field_runtime.call("request_visual_refresh")
			ui._show_map_constructor_inspector(ui.selected_map_constructor_entity_cell, ui.selected_map_constructor_entity_kind, ui.selected_map_constructor_entity_id)
		)
		actions.add_child(clear_button)
	section.add_child(actions)
	parent.add_child(section)

static func add_map_constructor_object_link_sections(ui: Variant, link_section: VBoxContainer, entity_kind: String, entity_id: String, data: Dictionary, type_group: String) -> void:
	if is_map_constructor_key_item(ui, data, type_group):
		add_key_door_link_section(ui, link_section, entity_kind, entity_id, data)
	if type_group == "door":
		add_door_linked_key_section(ui, link_section, entity_id, data)
		var door_control_type: String = ui._safe_ui_string(data.get("control_type", data.get("control_mode", "internal"))).strip_edges().to_lower()
		if door_control_type in ["external", "terminal", "external_control", "external control"]:
			add_link_picker(ui, link_section, entity_kind, entity_id, "linked_terminal", "Linked Terminal")
	if type_group == "terminal":
		var controlled_target_type: String = ui._safe_ui_string(data.get("controlled_target_type", "none")).to_lower()
		if controlled_target_type == "door":
			add_link_picker(ui, link_section, entity_kind, entity_id, "linked_door", "Linked Door")
		elif controlled_target_type == "platform":
			add_link_picker(ui, link_section, entity_kind, entity_id, "platform_target", "Platform Target")
	var object_type: String = ui._safe_ui_string(data.get("object_type", "")).strip_edges().to_lower()
	var power_type: String = ui._safe_ui_string(data.get("power_type", data.get("power_mode", "internal"))).strip_edges().to_lower().trim_suffix("_power")
	var is_power_source: bool = object_type.begins_with("power_source")
	if power_type == "external" and not is_power_source:
		add_link_picker(ui, link_section, entity_kind, entity_id, "power_network", "Power Network")
		add_link_picker(ui, link_section, entity_kind, entity_id, "power_source", "Power Source Binding")
	var control_visible: bool = type_group == "control"
	if control_visible:
		add_link_picker(ui, link_section, entity_kind, entity_id, "control_source", "Control Source")
		add_link_picker(ui, link_section, entity_kind, entity_id, "linked_door", "Linked Door")
		add_link_picker(ui, link_section, entity_kind, entity_id, "terminal_target", "Terminal Target")
		add_link_picker(ui, link_section, entity_kind, entity_id, "platform_target", "Platform Target")
