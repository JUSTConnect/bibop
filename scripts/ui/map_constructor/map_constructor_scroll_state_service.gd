extends RefCounted
class_name MapConstructorScrollStateService

# Shared Map Constructor scroll preservation helper.
# Rule: menu/tab/dropdown/property selection must not reset scroll after UI rebuild.

static func capture_snapshot(ui: Variant) -> Dictionary:
	var snapshot: Dictionary = {}
	if ui == null:
		return snapshot

	_capture_palette_scroll(ui, snapshot)
	_capture_inspector_scroll(ui, snapshot)
	_capture_overview_scroll(ui, snapshot)

	return snapshot


static func restore_snapshot_deferred(ui: Variant, snapshot: Dictionary) -> void:
	if ui == null or snapshot.is_empty():
		return

	if ui is Node:
		var node: Node = ui as Node
		if node.get_tree() != null:
			node.get_tree().process_frame.connect(func() -> void:
				restore_snapshot(ui, snapshot)
			, CONNECT_ONE_SHOT)
			return

	restore_snapshot(ui, snapshot)


static func restore_snapshot(ui: Variant, snapshot: Dictionary) -> void:
	if ui == null or snapshot.is_empty():
		return

	_restore_palette_scroll(ui, snapshot)
	_restore_inspector_scroll(ui, snapshot)
	_restore_overview_scroll(ui, snapshot)


static func palette_key(tab_id: String) -> String:
	return "palette:%s" % tab_id


static func inspector_key(ui: Variant) -> String:
	if ui == null or ui.map_constructor_state == null:
		return "inspector:none"

	var cell: Vector2i = ui.map_constructor_state.selected_map_constructor_entity_cell
	var entity_kind: String = str(ui.map_constructor_state.selected_map_constructor_entity_kind)
	var entity_id: String = str(ui.map_constructor_state.selected_map_constructor_entity_id)
	var inspector_tab: String = str(ui.map_constructor_state.map_constructor_active_inspector_tab_id)

	return "inspector:%d,%d:%s:%s:%s" % [
		cell.x,
		cell.y,
		entity_kind,
		entity_id,
		inspector_tab
	]


static func overview_key() -> String:
	return "overview_hud"


static func find_first_scroll(root: Node) -> ScrollContainer:
	if root == null:
		return null

	if root is ScrollContainer:
		return root as ScrollContainer

	for child in root.get_children():
		var found: ScrollContainer = find_first_scroll(child)
		if found != null:
			return found

	return null


static func remember_scroll(ui: Variant, key: String, scroll: ScrollContainer) -> void:
	if ui == null:
		return
	if ui.map_constructor_state == null:
		return
	if key.is_empty():
		return
	if scroll == null or not is_instance_valid(scroll):
		return

	ui.map_constructor_state.map_constructor_tab_scroll_positions[key] = scroll.scroll_vertical


static func restore_scroll_deferred(ui: Variant, key: String, scroll: ScrollContainer) -> void:
	if ui == null:
		return
	if ui.map_constructor_state == null:
		return
	if key.is_empty():
		return
	if scroll == null or not is_instance_valid(scroll):
		return

	var snapshot: Dictionary = {}
	snapshot[key] = int(ui.map_constructor_state.map_constructor_tab_scroll_positions.get(key, 0))
	restore_snapshot_deferred(ui, snapshot)


static func _capture_palette_scroll(ui: Variant, snapshot: Dictionary) -> void:
	if ui.map_constructor_state == null:
		return
	if ui.runtime_map_constructor_palette_panel == null:
		return
	if not is_instance_valid(ui.runtime_map_constructor_palette_panel):
		return

	var scroll: ScrollContainer = find_first_scroll(ui.runtime_map_constructor_palette_panel)
	if scroll == null:
		return

	var tab_id: String = str(ui.map_constructor_state.map_constructor_active_tab)
	var key: String = palette_key(tab_id)

	snapshot[key] = scroll.scroll_vertical

	ui.map_constructor_state.map_constructor_tab_scroll_positions[key] = scroll.scroll_vertical
	ui.map_constructor_state.map_constructor_tab_scroll_positions[tab_id] = scroll.scroll_vertical


static func _restore_palette_scroll(ui: Variant, snapshot: Dictionary) -> void:
	if ui.map_constructor_state == null:
		return
	if ui.runtime_map_constructor_palette_panel == null:
		return
	if not is_instance_valid(ui.runtime_map_constructor_palette_panel):
		return

	var scroll: ScrollContainer = find_first_scroll(ui.runtime_map_constructor_palette_panel)
	if scroll == null:
		return

	var tab_id: String = str(ui.map_constructor_state.map_constructor_active_tab)
	var key: String = palette_key(tab_id)
	var fallback_value: Variant = ui.map_constructor_state.map_constructor_tab_scroll_positions.get(
		key,
		ui.map_constructor_state.map_constructor_tab_scroll_positions.get(tab_id, scroll.scroll_vertical)
	)

	scroll.scroll_vertical = int(snapshot.get(key, fallback_value))


static func _capture_inspector_scroll(ui: Variant, snapshot: Dictionary) -> void:
	if ui.map_constructor_state == null:
		return
	if ui.runtime_map_constructor_inspector_scroll == null:
		return
	if not is_instance_valid(ui.runtime_map_constructor_inspector_scroll):
		return

	var key: String = inspector_key(ui)
	var scroll_value: int = ui.runtime_map_constructor_inspector_scroll.scroll_vertical

	snapshot[key] = scroll_value
	ui.map_constructor_state.map_constructor_tab_scroll_positions[key] = scroll_value


static func _restore_inspector_scroll(ui: Variant, snapshot: Dictionary) -> void:
	if ui.map_constructor_state == null:
		return
	if ui.runtime_map_constructor_inspector_scroll == null:
		return
	if not is_instance_valid(ui.runtime_map_constructor_inspector_scroll):
		return

	var key: String = inspector_key(ui)

	if snapshot.has(key):
		ui.runtime_map_constructor_inspector_scroll.scroll_vertical = int(snapshot.get(key, 0))
	elif ui.map_constructor_state.map_constructor_tab_scroll_positions.has(key):
		ui.runtime_map_constructor_inspector_scroll.scroll_vertical = int(
			ui.map_constructor_state.map_constructor_tab_scroll_positions.get(key, 0)
		)


static func _capture_overview_scroll(ui: Variant, snapshot: Dictionary) -> void:
	if ui.map_constructor_state == null:
		return
	if ui.runtime_map_constructor_overview_hud_scroll == null:
		return
	if not is_instance_valid(ui.runtime_map_constructor_overview_hud_scroll):
		return

	var key: String = overview_key()
	var scroll_value: int = ui.runtime_map_constructor_overview_hud_scroll.scroll_vertical

	snapshot[key] = scroll_value
	ui.map_constructor_state.map_constructor_tab_scroll_positions[key] = scroll_value


static func _restore_overview_scroll(ui: Variant, snapshot: Dictionary) -> void:
	if ui.map_constructor_state == null:
		return
	if ui.runtime_map_constructor_overview_hud_scroll == null:
		return
	if not is_instance_valid(ui.runtime_map_constructor_overview_hud_scroll):
		return

	var key: String = overview_key()
	var fallback_value: Variant = ui.map_constructor_state.map_constructor_tab_scroll_positions.get(
		key,
		ui.runtime_map_constructor_overview_hud_scroll.scroll_vertical
	)

	ui.runtime_map_constructor_overview_hud_scroll.scroll_vertical = int(snapshot.get(key, fallback_value))
