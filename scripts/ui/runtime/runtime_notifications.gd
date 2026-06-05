extends RefCounted
class_name RuntimeNotifications


static func show_hint(ui, message: String) -> void:
	if ui.hint_label != null:
		ui.hint_label.text = message
	show_runtime_notification(ui, message)


static func process_runtime_notification_timer(ui, delta: float) -> void:
	if ui.runtime_notification_timer > 0.0:
		ui.runtime_notification_timer = maxf(0.0, ui.runtime_notification_timer - delta)
		if ui.runtime_notification_label != null:
			var pulse: float = 0.70 + 0.30 * abs(sin(float(Time.get_ticks_msec()) / 180.0))
			ui.runtime_notification_label.modulate = Color(1, 1, 1, pulse)
	elif ui.runtime_notification_label != null:
		refresh_runtime_notification_fallback(ui)


static func refresh_runtime_notification_fallback(ui) -> void:
	if ui.runtime_notification_label == null:
		return
	ui.runtime_notification_timer = 0.0
	ui.runtime_notification_role = "neutral"
	ui.runtime_notification_label.modulate = Color.WHITE
	var secondary_text: String = ui._get_runtime_secondary_objective_text()
	ui.runtime_notification_label.text = secondary_text
	ui.runtime_notification_label.add_theme_color_override("font_color", ui.UI_COLOR_TEXT_DIM)
	if ui.runtime_notification_panel != null:
		ui.runtime_notification_panel.add_theme_stylebox_override("panel", ui._make_panel_style(ui.UI_COLOR_PANEL_DARK, ui.UI_COLOR_BORDER_DIM, 1, 8))


static func get_runtime_notification_role(message: String) -> String:
	var lower: String = message.to_lower()
	for token in ["collected", "unlocked", "opened", "closed", "complete", "success", "stored", "picked up"]:
		if lower.find(token) != -1:
			return "ok"
	for token in ["too heavy", "required", "locked", "no ", "cannot", "failed", "missing", "not enough", "blocked", "rejected", "occupied"]:
		if lower.find(token) != -1:
			return "danger"
	return "info"


static func show_runtime_notification(ui, message: String) -> void:
	if ui.runtime_notification_label == null:
		return
	ui.runtime_notification_role = get_runtime_notification_role(message)
	ui.runtime_notification_timer = 7.0
	ui.runtime_notification_label.text = message
	var color: Color = ui.UI_COLOR_ACCENT
	if ui.runtime_notification_role == "ok":
		color = ui.UI_COLOR_OK
	elif ui.runtime_notification_role == "danger":
		color = ui.UI_COLOR_DANGER
	ui.runtime_notification_label.add_theme_color_override("font_color", color)
	if ui.runtime_notification_panel != null:
		ui.runtime_notification_panel.add_theme_stylebox_override("panel", ui._make_panel_style(ui.UI_COLOR_PANEL_DARK, color, 1, 8))
