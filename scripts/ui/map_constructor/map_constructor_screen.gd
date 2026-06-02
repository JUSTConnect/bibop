extends RefCounted
class_name MapConstructorScreen

const MapConstructorPanelRef = preload("res://scripts/ui/map_constructor/map_constructor_panel.gd")
const MapConstructorTabsRef = preload("res://scripts/ui/map_constructor/map_constructor_tabs.gd")


static func build(ui: Variant) -> Control:
	var panel: PanelContainer = MapConstructorPanelRef.build_panel(ui)
	MapConstructorPanelRef.mount_panel(ui, panel)
	return panel


static func refresh(ui: Variant) -> void:
	if ui.app_screen_mode != ui.AppScreenMode.GAMEPLAY:
		return
	if ui.runtime_hud_root == null or not is_instance_valid(ui.runtime_hud_root):
		return
	MapConstructorTabsRef.remember_palette_scroll(ui)
	MapConstructorPanelRef.clear_existing_panel(ui)
	if not ui.map_constructor_mode_active:
		set_visible(ui, false)
		return
	set_visible(ui, true)
	if not ["map_settings", "objects", "warnings"].has(ui.map_constructor_active_tab):
		ui.map_constructor_active_tab = "map_settings"
	build(ui)


static func set_visible(ui: Variant, visible_state: bool) -> void:
	ui._set_runtime_bottom_hud_visible(not visible_state)


static func clear(ui: Variant) -> void:
	MapConstructorPanelRef.clear_existing_panel(ui)
	ui.runtime_map_constructor_palette_panel = null
	if ui.runtime_map_constructor_inspector_panel != null and is_instance_valid(ui.runtime_map_constructor_inspector_panel):
		ui.runtime_map_constructor_inspector_panel.queue_free()
	ui.runtime_map_constructor_inspector_panel = null
	ui.runtime_map_constructor_inspector_scroll = null
	if ui.runtime_map_constructor_validation_overlay_control != null and is_instance_valid(ui.runtime_map_constructor_validation_overlay_control):
		ui.runtime_map_constructor_validation_overlay_control.queue_free()
	ui.runtime_map_constructor_validation_overlay_control = null
