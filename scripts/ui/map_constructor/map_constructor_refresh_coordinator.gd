extends RefCounted
class_name MapConstructorRefreshCoordinator

# Shared post-mutation refresh sequences for Map Constructor UI callbacks.
# Callers keep deciding which sequence is needed; this coordinator only routes
# the existing GameUI refresh calls in their established order.

static func refresh_panels(ui: Variant) -> void:
	ui._refresh_map_constructor_panels()


static func refresh_browser(ui: Variant) -> void:
	ui._refresh_map_constructor_browser()


static func request_overlay_refresh(ui: Variant) -> void:
	ui._request_map_constructor_overlay_refresh()


static func request_field_visual_refresh(ui: Variant) -> void:
	if ui.field_runtime != null and ui.field_runtime.has_method("request_visual_refresh"):
		ui.field_runtime.call("request_visual_refresh")


static func reopen_selected_inspector(ui: Variant) -> void:
	ui._show_map_constructor_inspector(
		ui.map_constructor_state.selected_map_constructor_entity_cell,
		ui.map_constructor_state.selected_map_constructor_entity_kind,
		ui.map_constructor_state.selected_map_constructor_entity_id
	)


static func refresh_panels_and_overlay(ui: Variant) -> void:
	refresh_panels(ui)
	request_overlay_refresh(ui)


static func refresh_panels_then_field(ui: Variant) -> void:
	refresh_panels(ui)
	request_field_visual_refresh(ui)


static func refresh_field_then_panels(ui: Variant) -> void:
	request_field_visual_refresh(ui)
	refresh_panels(ui)


static func refresh_panels_overlay_then_field(ui: Variant) -> void:
	refresh_panels(ui)
	request_overlay_refresh(ui)
	request_field_visual_refresh(ui)


static func refresh_panels_browser_then_field(ui: Variant) -> void:
	refresh_panels(ui)
	refresh_browser(ui)
	request_field_visual_refresh(ui)


static func refresh_selected_entity_mutation(ui: Variant) -> void:
	refresh_panels_then_field(ui)
	reopen_selected_inspector(ui)
