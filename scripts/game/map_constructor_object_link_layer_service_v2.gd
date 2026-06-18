extends Node
class_name MapConstructorObjectLinkLayerV2

const LinkReadModelRef = preload("res://scripts/game/map_constructor_link_read_model_service.gd")
const KeyDoorLinkServiceRef = preload("res://scripts/game/map_constructor_key_door_link_service.gd")
const InformationTerminalServiceRef = preload("res://scripts/game/map_constructor_information_terminal_service.gd")
const TerminalLinkFilterServiceRef = preload("res://scripts/game/map_constructor_terminal_link_filter_service.gd")

const SECTION_NAME := "MapConstructorObjectLinksLayerSection"
const LEGACY_SECTION_TITLE := "6. Links"
const SECTION_TITLE := "6. Links Layer"
const SCAN_INTERVAL := 0.45

const LINK_POWER_SOURCE := "power_source"
const LINK_POWER_NETWORK := "power_network"
const LINK_CONTROL_TERMINAL := "control_terminal"
const LINK_ACCESS_TERMINAL := "access_terminal"
const LINK_REQUIRED_KEY := "required_key"
const LINK_ACCESS_CODE := "access_code"
const LINK_KEY_DOOR := "key_door"
const LINK_KEY_STORAGE := "key_storage_terminal"

var _scan_timer: float = 0.0

func _ready() -> void:
	_scan_scene_tree()
	if get_tree() != null and not get_tree().node_added.is_connected(_on_node_added):
		get_tree().node_added.connect(_on_node_added)


func _process(delta: float) -> void:
	_scan_timer -= delta
	if _scan_timer <= 0.0:
		_scan_timer = SCAN_INTERVAL
		_scan_scene_tree()


func _on_node_added(_node: Node) -> void:
	call_deferred("_scan_scene_tree")


func _scan_scene_tree() -> void:
	if get_tree() == null or get_tree().root == null:
		return
	_scan_node(get_tree().root)


func _scan_node(node: Node) -> void:
	if node == null:
		return
	_try_decorate_inspector(node)
	for child in node.get_children():
		_scan_node(child)


func _try_decorate_inspector(ui: Node) -> void:
	if ui == null or not _has_property(ui, "runtime_map_constructor_inspector_panel"):
		return
	var panel: Control = _get_property(ui, "runtime_map_constructor_inspector_panel") as Control
	if panel == null or not is_instance_valid(panel):
		return
	var content: VBoxContainer = _find_inspector_content(panel)
	if content == null:
		return
	_remove_legacy_and_stale_link_sections(content)
	var manager: Object = _get_property(ui, "mission_manager_runtime") as Object
	if manager == null or not is_instance_valid(manager) or not manager.has_method("get_map_constructor_entity_by_id"):
		return
	var entity_kind: String = str(_get_property(ui, "selected_map_constructor_entity_kind")).strip_edges()
	var entity_id: String = str(_get_property(ui, "selected_map_constructor_entity_id")).strip_edges()
	if entity_kind.is_empty() or entity_id.is_empty():
		return
	var model: Dictionary = build_links_model(manager, entity_kind, entity_id)
	if not bool(model.get("visible", false)):
		return
	var section: VBoxContainer = _build_section(ui, manager, model)
	content.add_child(section)
	content.move_child(section, _find_insert_index_before_warnings(content))


func build_links_model(manager: Object, entity_kind: String, entity_id: String) -> Dictionary:
	var entity: Dictionary = _as_dict(manager.call("get_map_constructor_entity_by_id", entity_kind, entity_id)) if manager != null and manager.has_method("get_map_constructor_entity_by_id") else {}
	var data: Dictionary = _as_dict(entity.get("data", {}))
	var resolved_kind: String = str(entity.get("entity_kind", entity_kind))
	var model: Dictionary = {
		"visible": false,
		"entity_kind": resolved_kind,
		"entity_id": entity_id,
		"data": data,
		"power": _build_power_model(manager, resolved_kind, entity_id, data),
		"control": _build_control_model(manager, resolved_kind, entity_id, data),
		"access": _build_access_model(manager, resolved_kind, entity_id, data),
		"key": _build_key_model(manager, resolved_kind, entity_id, data)
	}
	for block_name in ["power", "control", "access", "key"]:
		if bool(Dictionary(model.get(block_name, {})).get("visible", false)):
			model["visible"] = true
	return model


func _build_power_model(manager: Object, entity_kind: String, entity_id: String, data: Dictionary) -> Dictionary:
	var power_type: String = _normalize_power_type(data)
	var current_source_id: String = _first_string(data, ["power_source_id", "source_object_id", "linked_power_source_id", "external_power_source_id"])
	var current_network_id: String = _first_string(data, ["power_network_id", "power_circuit_id", "network_id", "circuit_id"])
	var source_targets: Array[Dictionary] = _targets_for_field(manager, entity_kind, entity_id, "power_source_id")
	var network_targets: Array[Dictionary] = _targets_for_field(manager, entity_kind, entity_id, "power_network_id")
	return {
		"visible": power_type == "external",
		"type": power_type,
		"source_id": current_source_id,
		"network_id": current_network_id,
		"sources": source_targets,
		"networks": _filter_power_networks_for_source(manager, network_targets, current_source_id, current_network_id)
	}


func _build_control_model(manager: Object, entity_kind: String, entity_id: String, data: Dictionary) -> Dictionary:
	var control_type: String = _normalize_control_type(data)
	var current_terminal_id: String = _first_string(data, ["control_terminal_id", "linked_terminal_id", "required_terminal_id", "control_source_id"])
	return {
		"visible": control_type == "external",
		"type": control_type,
		"terminal_id": current_terminal_id,
		"terminals": _filter_terminals(manager, _targets_for_field(manager, entity_kind, entity_id, "control_terminal_id"), "control")
	}


func _build_access_model(manager: Object, entity_kind: String, entity_id: String, data: Dictionary) -> Dictionary:
	var access_type: String = _normalize_access_type(data)
	var current_key_id: String = _first_string(data, ["required_key_id", "linked_key_id"])
	var current_terminal_id: String = _first_string(data, ["access_terminal_id", "information_terminal_id", "storage_terminal_id"])
	var code: String = _first_string(data, ["access_code_value", "access_code", "stored_access_code", "password"])
	var keys: Array[Dictionary] = []
	var terminals: Array[Dictionary] = []
	if access_type in ["key_card", "digital_key", "access_code"]:
		keys = _filter_keys(manager, _targets_for_field(manager, entity_kind, entity_id, "required_key_id"), access_type)
	if access_type in ["access_code", "digital_key", "terminal"]:
		terminals = _filter_terminals(manager, _targets_for_field(manager, entity_kind, entity_id, "access_terminal_id"), "information" if access_type in ["access_code", "digital_key"] else "any")
	return {
		"visible": access_type != "none",
		"type": access_type,
		"key_id": current_key_id,
		"terminal_id": current_terminal_id,
		"code": code,
		"keys": keys,
		"terminals": terminals
	}


func _build_key_model(manager: Object, entity_kind: String, entity_id: String, data: Dictionary) -> Dictionary:
	if not _is_key_data(data):
		return {"visible": false}
	var linked_door_id: String = _first_string(data, ["linked_door_id", "unlocks_object_id", "linked_access_object_id"])
	var storage_terminal_id: String = _first_string(data, ["storage_terminal_id", "stored_in_terminal_id", "terminal_id"])
	var doors: Array[Dictionary] = []
	if manager != null and manager.has_method("get_map_constructor_key_door_link_candidates"):
		var candidates: Dictionary = _as_dict(manager.call("get_map_constructor_key_door_link_candidates", entity_kind, entity_id))
		for door_variant in Array(candidates.get("doors", [])):
			var door: Dictionary = _as_dict(door_variant)
			if not door.is_empty():
				doors.append(_normalize_target_row(manager, door, "world_object"))
	return {
		"visible": true,
		"key_type": _normalize_key_type(data),
		"door_id": linked_door_id,
		"storage_terminal_id": storage_terminal_id,
		"doors": doors,
		"terminals": _filter_terminals(manager, _targets_for_field(manager, entity_kind, entity_id, "access_terminal_id"), "information")
	}


func _build_section(ui: Node, manager: Object, model: Dictionary) -> VBoxContainer:
	var section := VBoxContainer.new()
	section.name = SECTION_NAME
	section.add_theme_constant_override("separation", 6)
	var header := Label.new()
	header.text = SECTION_TITLE
	header.add_theme_color_override("font_color", _ui_color(ui, "UI_COLOR_ACCENT", Color(0.2, 0.76, 0.95, 1.0)))
	section.add_child(header)
	var note := Label.new()
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.text = "Centralized power/control/access bindings. Blocks appear only when type is External or access is required."
	section.add_child(note)
	var entity_kind: String = str(model.get("entity_kind", ""))
	var entity_id: String = str(model.get("entity_id", ""))
	var power_model: Dictionary = Dictionary(model.get("power", {}))
	if bool(power_model.get("visible", false)):
		var power_box := _subsection("Links Power")
		_add_picker(ui, power_box, manager, entity_kind, entity_id, "Power source", LINK_POWER_SOURCE, str(power_model.get("source_id", "")), Array(power_model.get("sources", [])), {})
		if not str(power_model.get("source_id", "")).strip_edges().is_empty():
			_add_picker(ui, power_box, manager, entity_kind, entity_id, "Power circuit", LINK_POWER_NETWORK, str(power_model.get("network_id", "")), Array(power_model.get("networks", [])), {})
		else:
			power_box.add_child(_hint("Select a power source first, then choose source circuit or main."))
		section.add_child(power_box)
	var control_model: Dictionary = Dictionary(model.get("control", {}))
	if bool(control_model.get("visible", false)):
		var control_box := _subsection("Links Control")
		_add_picker(ui, control_box, manager, entity_kind, entity_id, "Control terminal", LINK_CONTROL_TERMINAL, str(control_model.get("terminal_id", "")), Array(control_model.get("terminals", [])), {})
		section.add_child(control_box)
	var access_model: Dictionary = Dictionary(model.get("access", {}))
	if bool(access_model.get("visible", false)):
		section.add_child(_build_access_ui(ui, manager, entity_kind, entity_id, access_model))
	var key_model: Dictionary = Dictionary(model.get("key", {}))
	if bool(key_model.get("visible", false)):
		section.add_child(_build_key_ui(ui, manager, entity_kind, entity_id, key_model))
	return section


func _build_access_ui(ui: Node, manager: Object, entity_kind: String, entity_id: String, model: Dictionary) -> VBoxContainer:
	var access_type: String = str(model.get("type", "none"))
	var box := _subsection("Links Accesses: %s" % access_type.replace("_", " ").capitalize())
	if access_type == "access_code":
		_add_code_row(ui, box, manager, entity_kind, entity_id, str(model.get("code", "")))
		_add_picker(ui, box, manager, entity_kind, entity_id, "Code storage terminal", LINK_ACCESS_TERMINAL, str(model.get("terminal_id", "")), Array(model.get("terminals", [])), {"access_type":"access_code", "code":str(model.get("code", ""))})
	elif access_type == "digital_key":
		_add_picker(ui, box, manager, entity_kind, entity_id, "Digital key", LINK_REQUIRED_KEY, str(model.get("key_id", "")), Array(model.get("keys", [])), {"access_type":"digital_key"})
		_add_picker(ui, box, manager, entity_kind, entity_id, "Key storage terminal", LINK_ACCESS_TERMINAL, str(model.get("terminal_id", "")), Array(model.get("terminals", [])), {"access_type":"digital_key", "key_id":str(model.get("key_id", ""))})
	elif access_type == "key_card":
		_add_picker(ui, box, manager, entity_kind, entity_id, "Key-card", LINK_REQUIRED_KEY, str(model.get("key_id", "")), Array(model.get("keys", [])), {"access_type":"key_card"})
	elif access_type == "terminal":
		_add_picker(ui, box, manager, entity_kind, entity_id, "Access terminal", LINK_ACCESS_TERMINAL, str(model.get("terminal_id", "")), Array(model.get("terminals", [])), {"access_type":"terminal"})
	return box


func _build_key_ui(ui: Node, manager: Object, entity_kind: String, entity_id: String, model: Dictionary) -> VBoxContainer:
	var box := _subsection("Links Accesses: Key Backlinks")
	_add_picker(ui, box, manager, entity_kind, entity_id, "Unlocks object", LINK_KEY_DOOR, str(model.get("door_id", "")), Array(model.get("doors", [])), {})
	if str(model.get("key_type", "")) == "digital_key":
		_add_picker(ui, box, manager, entity_kind, entity_id, "Stored in terminal", LINK_KEY_STORAGE, str(model.get("storage_terminal_id", "")), Array(model.get("terminals", [])), {"key_id": entity_id})
	return box


func _add_picker(ui: Node, parent: VBoxContainer, manager: Object, entity_kind: String, entity_id: String, label_text: String, link_type: String, current_id: String, targets: Array, extra: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(150, 0)
	row.add_child(label)
	var select := OptionButton.new()
	select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	select.add_item("(none)")
	select.set_item_metadata(0, {"id":""})
	var selected_index: int = 0
	var current_found: bool = current_id.strip_edges().is_empty()
	for target_variant in targets:
		var target: Dictionary = _as_dict(target_variant)
		var target_id: String = str(target.get("id", "")).strip_edges()
		if target_id.is_empty() or target_id == "__none__":
			continue
		select.add_item(str(target.get("label", target_id)))
		var idx: int = select.item_count - 1
		select.set_item_metadata(idx, target)
		select.set_item_tooltip(idx, target_id)
		if bool(target.get("disabled", false)):
			select.set_item_disabled(idx, true)
		if target_id == current_id:
			selected_index = idx
			current_found = true
	if not current_found:
		select.add_item(current_id)
		selected_index = select.item_count - 1
		select.set_item_metadata(selected_index, {"id": current_id})
	select.select(selected_index)
	select.item_selected.connect(func(index: int) -> void:
		var target: Dictionary = _as_dict(select.get_item_metadata(index))
		var target_id: String = str(target.get("id", "")).strip_edges()
		var payload: Dictionary = extra.duplicate(true)
		payload["target_id"] = target_id
		var result: Dictionary = apply_link(manager, entity_kind, entity_id, link_type, payload)
		_refresh_after_apply(ui, result)
	)
	row.add_child(select)
	var jump := Button.new()
	jump.text = "Jump"
	jump.disabled = current_id.strip_edges().is_empty()
	jump.pressed.connect(func() -> void:
		_jump_to_target(ui, manager, current_id)
	)
	row.add_child(jump)
	parent.add_child(row)


func _add_code_row(ui: Node, parent: VBoxContainer, manager: Object, entity_kind: String, entity_id: String, current_code: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var label := Label.new()
	label.text = "Access code"
	label.custom_minimum_size = Vector2(150, 0)
	row.add_child(label)
	var edit := LineEdit.new()
	edit.placeholder_text = "4 digits"
	edit.max_length = 4
	edit.text = current_code
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var apply_code := func() -> void:
		var result: Dictionary = apply_link(manager, entity_kind, entity_id, LINK_ACCESS_CODE, {"code": edit.text})
		_refresh_after_apply(ui, result)
	edit.text_submitted.connect(func(_value: String) -> void:
		apply_code.call()
	)
	edit.focus_exited.connect(func() -> void:
		if edit.text.strip_edges() != current_code.strip_edges():
			apply_code.call()
	)
	row.add_child(edit)
	parent.add_child(row)


func apply_link(manager: Object, entity_kind: String, entity_id: String, link_type: String, payload: Dictionary) -> Dictionary:
	if manager == null or not is_instance_valid(manager):
		return {"ok": false, "message": "Mission manager unavailable."}
	var target_id: String = str(payload.get("target_id", "")).strip_edges()
	if target_id == "__none__":
		target_id = ""
	match link_type:
		LINK_POWER_SOURCE:
			return _apply_manager_link(manager, entity_kind, entity_id, "power_source", target_id)
		LINK_POWER_NETWORK:
			return _apply_manager_link(manager, entity_kind, entity_id, "power_network", target_id)
		LINK_CONTROL_TERMINAL:
			var control_result: Dictionary = _apply_manager_link(manager, entity_kind, entity_id, "control_terminal", target_id)
			if bool(control_result.get("ok", false)):
				_sync_terminal_backlink(manager, target_id, entity_id, "control")
			return control_result
		LINK_ACCESS_TERMINAL:
			var access_result: Dictionary = _apply_manager_link(manager, entity_kind, entity_id, "access_terminal", target_id)
			if bool(access_result.get("ok", false)):
				_sync_access_terminal_payload(manager, target_id, entity_kind, entity_id, payload)
			return access_result
		LINK_REQUIRED_KEY:
			var key_result: Dictionary = _apply_manager_field(manager, entity_kind, entity_id, "required_key_id", target_id)
			if bool(key_result.get("ok", false)) and not target_id.is_empty():
				_sync_key_backlink(manager, target_id, entity_id, str(payload.get("access_type", "")))
			return key_result
		LINK_KEY_DOOR:
			return _apply_manager_link(manager, entity_kind, entity_id, "key_door", target_id)
		LINK_KEY_STORAGE:
			var storage_result: Dictionary = _apply_manager_field(manager, entity_kind, entity_id, "storage_terminal_id", target_id)
			if bool(storage_result.get("ok", false)):
				_sync_access_terminal_payload(manager, target_id, entity_kind, entity_id, {"access_type":"digital_key", "key_id":entity_id})
			return storage_result
		LINK_ACCESS_CODE:
			return _apply_access_code(manager, entity_kind, entity_id, str(payload.get("code", "")).strip_edges())
		_:
			return {"ok": false, "message": "Unsupported link type."}


func _apply_manager_link(manager: Object, entity_kind: String, entity_id: String, link_type: String, target_id: String) -> Dictionary:
	if manager.has_method("set_map_constructor_entity_link"):
		return _as_dict(manager.call("set_map_constructor_entity_link", entity_kind, entity_id, link_type, target_id))
	return {"ok": false, "message": "Link mutation unavailable."}


func _apply_manager_field(manager: Object, entity_kind: String, entity_id: String, field_name: String, value: Variant) -> Dictionary:
	if manager.has_method("apply_map_constructor_link_target"):
		return _as_dict(manager.call("apply_map_constructor_link_target", entity_kind, entity_id, field_name, value))
	if manager.has_method("update_map_constructor_entity_properties"):
		return _as_dict(manager.call("update_map_constructor_entity_properties", entity_kind, entity_id, {field_name: value}))
	return {"ok": false, "message": "Property mutation unavailable."}


func _apply_access_code(manager: Object, entity_kind: String, entity_id: String, code: String) -> Dictionary:
	if not InformationTerminalServiceRef.is_four_digit_code(code):
		return {"ok": false, "message": "Access code must be exactly 4 digits."}
	if manager.has_method("update_map_constructor_entity_properties"):
		return _as_dict(manager.call("update_map_constructor_entity_properties", entity_kind, entity_id, {"access_code_value": code, "access_code": code, "stored_access_code": code}))
	return {"ok": false, "message": "Property mutation unavailable."}


func _sync_terminal_backlink(manager: Object, terminal_id: String, entity_id: String, channel: String) -> void:
	if terminal_id.is_empty() or not manager.has_method("get_map_constructor_entity_by_id") or not manager.has_method("update_world_object_by_id"):
		return
	var terminal: Dictionary = _as_dict(manager.call("get_map_constructor_entity_by_id", "world_object", terminal_id))
	if not bool(terminal.get("ok", false)):
		return
	var data: Dictionary = _as_dict(terminal.get("data", {})).duplicate(true)
	var field_name: String = "linked_control_object_ids" if channel == "control" else "linked_access_object_ids"
	var links: Array = Array(data.get(field_name, [])).duplicate()
	if not links.has(entity_id):
		links.append(entity_id)
	data[field_name] = links
	data["controlled_target_id" if channel == "control" else "access_target_id"] = entity_id
	manager.call("update_world_object_by_id", terminal_id, data)


func _sync_access_terminal_payload(manager: Object, terminal_id: String, entity_kind: String, entity_id: String, payload: Dictionary) -> void:
	if terminal_id.is_empty() or not manager.has_method("get_map_constructor_entity_by_id") or not manager.has_method("update_world_object_by_id"):
		return
	var terminal: Dictionary = _as_dict(manager.call("get_map_constructor_entity_by_id", "world_object", terminal_id))
	if not bool(terminal.get("ok", false)):
		return
	var data: Dictionary = _as_dict(terminal.get("data", {})).duplicate(true)
	var access_type: String = _normalize_access_type(payload)
	if access_type in ["access_code", "digital_key"]:
		data["terminal_type"] = "information"
	if access_type == "access_code":
		var code: String = str(payload.get("code", "")).strip_edges()
		if code.is_empty() and manager.has_method("get_map_constructor_entity_by_id"):
			var entity: Dictionary = _as_dict(manager.call("get_map_constructor_entity_by_id", entity_kind, entity_id))
			code = _first_string(_as_dict(entity.get("data", {})), ["access_code_value", "access_code", "stored_access_code"])
		data["stored_data_type"] = "access_code"
		data["digital_payload_type"] = "access_code"
		data["access_code_value"] = code
		data["stored_access_code"] = code
		data["access_code"] = code
	elif access_type == "digital_key":
		var key_id: String = str(payload.get("key_id", "")).strip_edges()
		if key_id.is_empty():
			key_id = entity_id if _looks_like_key_id(entity_id) else ""
		data["stored_data_type"] = "digital_key"
		data["digital_payload_type"] = "digital_key"
		data["stored_digital_key_id"] = key_id
		data["stored_key_id"] = key_id
		data["stored_item_id"] = key_id
	data["access_target_id"] = entity_id
	var links: Array = Array(data.get("linked_access_object_ids", [])).duplicate()
	if not links.has(entity_id):
		links.append(entity_id)
	data["linked_access_object_ids"] = links
	manager.call("update_world_object_by_id", terminal_id, data)


func _sync_key_backlink(manager: Object, key_id: String, entity_id: String, access_type: String) -> void:
	if key_id.is_empty() or not manager.has_method("update_map_constructor_entity_properties"):
		return
	var resolved_kind: String = "item"
	if manager.has_method("get_map_constructor_entity_by_id"):
		var item_entity: Dictionary = _as_dict(manager.call("get_map_constructor_entity_by_id", "item", key_id))
		if not bool(item_entity.get("ok", false)):
			resolved_kind = "world_object"
	var updates: Dictionary = {"linked_door_id": entity_id, "unlocks_object_id": entity_id, "linked_access_object_id": entity_id}
	if access_type == "digital_key":
		updates["key_type"] = "digital_key"
		updates["key_kind"] = "digital"
	elif access_type == "key_card":
		updates["key_type"] = "key_card"
		updates["key_kind"] = "key_card"
	manager.call("update_map_constructor_entity_properties", resolved_kind, key_id, updates)


func _targets_for_field(manager: Object, entity_kind: String, entity_id: String, field_name: String) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	if manager == null or not manager.has_method("get_map_constructor_link_targets_for_field"):
		return rows
	var result: Dictionary = _as_dict(manager.call("get_map_constructor_link_targets_for_field", entity_kind, entity_id, field_name))
	for target_variant in Array(result.get("targets", [])):
		var row: Dictionary = _normalize_target_row(manager, _as_dict(target_variant), str(_as_dict(target_variant).get("entity_kind", "world_object")))
		if not row.is_empty():
			rows.append(row)
	return rows


func _normalize_target_row(manager: Object, target: Dictionary, fallback_kind: String) -> Dictionary:
	var target_id: String = str(target.get("id", "")).strip_edges()
	if target_id.is_empty():
		return {}
	var row: Dictionary = target.duplicate(true)
	row["id"] = target_id
	row["entity_kind"] = str(row.get("entity_kind", fallback_kind))
	row["label"] = _target_label(manager, row)
	return row


func _target_label(manager: Object, target: Dictionary) -> String:
	var target_id: String = str(target.get("id", "")).strip_edges()
	var label: String = str(target.get("label", "")).strip_edges()
	if not label.is_empty() and label != target_id:
		return label
	var data: Dictionary = _lookup_data(manager, target_id, str(target.get("entity_kind", "world_object")))
	for field in ["display_name", "name", "palette_label"]:
		var text: String = str(data.get(field, "")).strip_edges()
		if not text.is_empty():
			return text
	return target_id


func _filter_power_networks_for_source(manager: Object, targets: Array[Dictionary], source_id: String, current_network_id: String) -> Array[Dictionary]:
	if source_id.is_empty():
		return targets
	var source_data: Dictionary = _lookup_data(manager, source_id, "world_object")
	var source_network_id: String = _first_string(source_data, ["power_network_id", "power_circuit_id", "network_id", "circuit_id"])
	if source_network_id.is_empty() and not source_id.is_empty():
		source_network_id = "%s_net" % source_id
	var filtered: Array[Dictionary] = []
	for row in targets:
		var target_id: String = str(row.get("id", "")).strip_edges()
		if target_id in ["main", "main_power_net", source_network_id, current_network_id]:
			filtered.append(row)
	return filtered if not filtered.is_empty() else targets


func _filter_terminals(manager: Object, targets: Array[Dictionary], mode: String) -> Array[Dictionary]:
	var filtered: Array[Dictionary] = []
	for row in targets:
		var target_id: String = str(row.get("id", "")).strip_edges()
		if target_id.is_empty() or target_id == "__none__":
			continue
		var data: Dictionary = _lookup_data(manager, target_id, "world_object")
		if mode == "control" and TerminalLinkFilterServiceRef.is_control_terminal(data):
			filtered.append(row)
		elif mode == "information" and TerminalLinkFilterServiceRef.is_information_terminal(data):
			filtered.append(row)
		elif mode == "any" and TerminalLinkFilterServiceRef.is_terminal_data(data):
			filtered.append(row)
	return filtered if not filtered.is_empty() else targets


func _filter_keys(manager: Object, targets: Array[Dictionary], access_type: String) -> Array[Dictionary]:
	var filtered: Array[Dictionary] = []
	for row in targets:
		var target_id: String = str(row.get("id", "")).strip_edges()
		if target_id.is_empty() or target_id == "__none__":
			continue
		var data: Dictionary = _lookup_data(manager, target_id, str(row.get("entity_kind", "item")))
		var key_type: String = _normalize_key_type(data)
		if access_type == "digital_key" and key_type == "digital_key":
			filtered.append(row)
		elif access_type == "key_card" and key_type == "key_card":
			filtered.append(row)
		elif access_type == "access_code" and key_type == "access_code":
			filtered.append(row)
	return filtered if not filtered.is_empty() else targets


func _normalize_power_type(data: Dictionary) -> String:
	var value: String = str(data.get("power_type", data.get("power_mode", data.get("object_power_state", "")))).strip_edges().to_lower().replace(" ", "_").replace("-", "_").trim_suffix("_power")
	if value.is_empty():
		value = "external" if bool(data.get("requires_external_power", false)) else "internal"
	if value in ["external", "internal", "none"]:
		return value
	if value == "no" or value == "non":
		return "none"
	return "external" if value.contains("external") else "internal"


func _normalize_control_type(data: Dictionary) -> String:
	var value: String = str(data.get("control_type", data.get("control_mode", data.get("object_control_state", "")))).strip_edges().to_lower().replace(" ", "_").replace("-", "_").trim_suffix("_control")
	if value.is_empty():
		value = "external" if bool(data.get("requires_external_control", false)) else "internal"
	if value == "terminal":
		return "external"
	if value in ["external", "internal", "none"]:
		return value
	if value == "no" or value == "non":
		return "none"
	return "external" if value.contains("external") else "internal"


func _normalize_access_type(value: Variant) -> String:
	var raw: String = ""
	if value is Dictionary:
		var data: Dictionary = Dictionary(value)
		raw = str(data.get("object_access_state", data.get("access_type", data.get("lock_type", ""))))
	else:
		raw = str(value)
	var normalized: String = raw.strip_edges().to_lower().replace(" ", "_").replace("-", "_")
	match normalized:
		"", "none", "no_key", "open": return "none"
		"access_code", "code", "pin", "pin_code": return "access_code"
		"digital", "digital_key", "digital_access": return "digital_key"
		"key", "key_card", "keycard", "mechanical", "mechanical_key", "physical_key": return "key_card"
		"terminal", "terminal_access", "access_terminal": return "terminal"
	return normalized


func _normalize_key_type(data: Dictionary) -> String:
	var text: String = "%s %s %s %s %s" % [str(data.get("id", "")), str(data.get("item_type", data.get("object_type", ""))), str(data.get("key_type", "")), str(data.get("key_kind", "")), str(data.get("digital_item_type", ""))]
	text = text.to_lower().replace(" ", "_").replace("-", "_")
	if text.contains("digital"):
		return "digital_key"
	if text.contains("access_code") or text.contains("pin") or text.contains("code"):
		return "access_code"
	if text.contains("key_card") or text.contains("keycard") or text.contains("mechanical") or text.contains("_key"):
		return "key_card"
	return "key_card"


func _is_key_data(data: Dictionary) -> bool:
	if data.is_empty():
		return false
	var text: String = "%s %s %s %s %s %s" % [str(data.get("id", "")), str(data.get("item_type", data.get("object_type", ""))), str(data.get("item_class", "")), str(data.get("key_type", "")), str(data.get("key_kind", "")), str(data.get("archetype_id", ""))]
	text = text.to_lower().replace(" ", "_").replace("-", "_")
	return text.contains("key") or text.contains("access_code")


func _lookup_data(manager: Object, target_id: String, preferred_kind: String) -> Dictionary:
	if manager == null or not manager.has_method("get_map_constructor_entity_by_id") or target_id.is_empty():
		return {}
	for kind in [preferred_kind, "world_object", "item"]:
		var entity: Dictionary = _as_dict(manager.call("get_map_constructor_entity_by_id", kind, target_id))
		if bool(entity.get("ok", false)):
			return _as_dict(entity.get("data", {}))
	if manager.has_method("find_map_constructor_key_item_by_id"):
		var key_entity: Dictionary = _as_dict(manager.call("find_map_constructor_key_item_by_id", target_id))
		if bool(key_entity.get("ok", false)):
			return _as_dict(key_entity.get("data", key_entity.get("item_data", {})))
	return {}


func _remove_legacy_and_stale_link_sections(content: VBoxContainer) -> void:
	for child in content.get_children():
		if child == null:
			continue
		if child.name == SECTION_NAME:
			child.queue_free()
			continue
		var label: Label = _find_first_label(child)
		if label != null and str(label.text).strip_edges() == LEGACY_SECTION_TITLE:
			child.queue_free()


func _find_insert_index_before_warnings(content: VBoxContainer) -> int:
	for i in range(content.get_child_count()):
		var label: Label = _find_first_label(content.get_child(i))
		if label != null and str(label.text).contains("Warnings"):
			return i
	return maxi(0, content.get_child_count() - 1)


func _find_inspector_content(panel: Control) -> VBoxContainer:
	var scroll: ScrollContainer = _find_first_scroll(panel)
	if scroll == null:
		return null
	for child in scroll.get_children():
		if child is VBoxContainer:
			return child as VBoxContainer
	return null


func _find_first_scroll(node: Node) -> ScrollContainer:
	if node is ScrollContainer:
		return node as ScrollContainer
	for child in node.get_children():
		var result: ScrollContainer = _find_first_scroll(child)
		if result != null:
			return result
	return null


func _find_first_label(node: Node) -> Label:
	if node is Label:
		return node as Label
	for child in node.get_children():
		var result: Label = _find_first_label(child)
		if result != null:
			return result
	return null


func _subsection(title: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var label := Label.new()
	label.text = title
	box.add_child(label)
	return box


func _hint(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _jump_to_target(ui: Node, manager: Object, target_id: String) -> void:
	if ui == null or manager == null or target_id.strip_edges().is_empty() or not manager.has_method("get_map_constructor_entity_by_id"):
		return
	for kind in ["world_object", "item"]:
		var entity: Dictionary = _as_dict(manager.call("get_map_constructor_entity_by_id", kind, target_id))
		if bool(entity.get("ok", false)):
			var cell: Vector2i = _as_vector2i(entity.get("cell", Vector2i(-1, -1)))
			if cell.x >= 0 and cell.y >= 0 and ui.has_method("_focus_map_constructor_cell"):
				ui.call("_focus_map_constructor_cell", cell)
			if ui.has_method("_show_map_constructor_inspector"):
				ui.call("_show_map_constructor_inspector", cell, kind, target_id)
			return


func _refresh_after_apply(ui: Node, result: Dictionary) -> void:
	if ui == null or not is_instance_valid(ui):
		return
	if ui.has_method("show_hint"):
		ui.call("show_hint", str(result.get("message", "Link updated.")))
	if ui.has_method("_refresh_map_constructor_panels"):
		ui.call_deferred("_refresh_map_constructor_panels")
	if ui.has_method("_show_map_constructor_inspector"):
		ui.call_deferred("_show_map_constructor_inspector", _as_vector2i(_get_property(ui, "selected_map_constructor_entity_cell")), str(_get_property(ui, "selected_map_constructor_entity_kind")), str(_get_property(ui, "selected_map_constructor_entity_id")))
	var field_runtime: Object = _get_property(ui, "field_runtime") as Object
	if field_runtime != null and is_instance_valid(field_runtime) and field_runtime.has_method("request_visual_refresh"):
		field_runtime.call_deferred("request_visual_refresh")


func _first_string(data: Dictionary, fields: Array) -> String:
	for field in fields:
		var value: String = str(data.get(str(field), "")).strip_edges()
		if not value.is_empty():
			return value
	return ""


func _looks_like_key_id(value: String) -> bool:
	var text: String = value.to_lower()
	return text.contains("key") or text.contains("access_code")


func _as_dict(value: Variant) -> Dictionary:
	return value if value is Dictionary else {}


func _as_vector2i(value: Variant) -> Vector2i:
	if value is Vector2i:
		return value
	if value is Vector2:
		return Vector2i(value)
	return Vector2i(-1, -1)


func _get_property(target: Object, property_name: String) -> Variant:
	return null if target == null else target.get(property_name)


func _has_property(target: Object, property_name: String) -> bool:
	if target == null:
		return false
	for property_data in target.get_property_list():
		if str(property_data.get("name", "")) == property_name:
			return true
	return false


func _ui_color(ui: Object, property_name: String, fallback: Color) -> Color:
	var value: Variant = _get_property(ui, property_name)
	return value if value is Color else fallback
