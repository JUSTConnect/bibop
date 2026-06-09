extends RefCounted
class_name MapConstructorRefreshCoordinator

const MapConstructorScrollStateServiceRef = preload("res://scripts/ui/map_constructor/map_constructor_scroll_state_service.gd")
# Shared post-mutation refresh sequences for Map Constructor UI callbacks.
# All refresh paths preserve Map Constructor scroll by default.

static func _capture(ui: Variant) -> Dictionary:
	return MapConstructorScrollStateServiceRef.capture_snapshot(ui)


static func _restore(ui: Variant, snapshot: Dictionary) -> void:
	MapConstructorScrollStateServiceRef.restore_snapshot_deferred(ui, snapshot)


static func refresh_panels(ui: Variant) -> void:
	var snapshot: Dictionary = _capture(ui)
	ui._refresh_map_constructor_panels()
	_restore(ui, snapshot)


static func refresh_browser(ui: Variant) -> void:
	var snapshot: Dictionary = _capture(ui)
	ui._refresh_map_constructor_browser()
	_restore(ui, snapshot)


static func request_overlay_refresh(ui: Variant) -> void:
	ui._request_map_constructor_overlay_refresh()


static func request_field_visual_refresh(ui: Variant) -> void:
	if ui.field_runtime != null and ui.field_runtime.has_method("request_visual_refresh"):
		ui.field_runtime.call("request_visual_refresh")


static func reopen_selected_inspector(ui: Variant) -> void:
	var snapshot: Dictionary = _capture(ui)
	ui._show_map_constructor_inspector(
		ui.map_constructor_state.selected_map_constructor_entity_cell,
		ui.map_constructor_state.selected_map_constructor_entity_kind,
		ui.map_constructor_state.selected_map_constructor_entity_id
	)
	_restore(ui, snapshot)


static func refresh_panels_and_overlay(ui: Variant) -> void:
	var snapshot: Dictionary = _capture(ui)
	ui._refresh_map_constructor_panels()
	request_overlay_refresh(ui)
	_restore(ui, snapshot)


static func refresh_panels_then_field(ui: Variant) -> void:
	var snapshot: Dictionary = _capture(ui)
	ui._refresh_map_constructor_panels()
	request_field_visual_refresh(ui)
	_restore(ui, snapshot)


static func refresh_field_then_panels(ui: Variant) -> void:
	var snapshot: Dictionary = _capture(ui)
	request_field_visual_refresh(ui)
	ui._refresh_map_constructor_panels()
	_restore(ui, snapshot)


static func refresh_panels_overlay_then_field(ui: Variant) -> void:
	var snapshot: Dictionary = _capture(ui)
	ui._refresh_map_constructor_panels()
	request_overlay_refresh(ui)
	request_field_visual_refresh(ui)
	_restore(ui, snapshot)


static func refresh_panels_browser_then_field(ui: Variant) -> void:
	var snapshot: Dictionary = _capture(ui)
	ui._refresh_map_constructor_panels()
	ui._refresh_map_constructor_browser()
	request_field_visual_refresh(ui)
	_restore(ui, snapshot)


static func refresh_selected_entity_mutation(ui: Variant) -> void:
	var snapshot: Dictionary = _capture(ui)
	ui._refresh_map_constructor_panels()
	request_field_visual_refresh(ui)
	ui._show_map_constructor_inspector(
		ui.map_constructor_state.selected_map_constructor_entity_cell,
		ui.map_constructor_state.selected_map_constructor_entity_kind,
		ui.map_constructor_state.selected_map_constructor_entity_id
	)
	_restore(ui, snapshot)
