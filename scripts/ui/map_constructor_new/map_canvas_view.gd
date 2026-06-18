extends Control

# MapCanvasView
# Responsive canvas for map cells.
# Важно: canvas не задаёт ширину layout через child-buttons. Он рисует клетки внутри доступного rect.
# Текущий object-card режим — временный DEBUG visual, чтобы явно проверить visual pipeline.

signal cell_pressed(cell: Vector2i)

const BG_COLOR := Color(0.075, 0.09, 0.12, 1.0)
const CELL_COLOR := Color(0.08, 0.095, 0.125, 1.0)
const CELL_HOVER_COLOR := Color(0.105, 0.14, 0.18, 1.0)
const CELL_SELECTED_COLOR := Color(0.12, 0.22, 0.28, 1.0)
const BORDER_COLOR := Color(0.25, 0.5, 0.62, 0.85)
const TEXT_COLOR := Color(0.88, 0.91, 0.94, 1.0)
const DARK_TEXT_COLOR := Color(0.04, 0.05, 0.07, 1.0)
const MUTED_TEXT_COLOR := Color(0.68, 0.74, 0.78, 1.0)
const ACCENT_COLOR := Color(0.25, 0.78, 0.95, 1.0)
const CARD_BG := Color(0.04, 0.05, 0.07, 0.95)
const DEBUG_BAND_COLOR := Color(1.0, 1.0, 1.0, 0.18)

var columns: int = 1
var rows: int = 1
var cell_visuals: Dictionary = {}
var selected_cell: Vector2i = Vector2i(-1, -1)
var hover_cell: Vector2i = Vector2i(-1, -1)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	resized.connect(func() -> void:
		queue_redraw()
	)


func set_cells(new_columns: int, new_rows: int, new_cell_labels: Dictionary, new_selected_cell: Vector2i) -> void:
	set_cell_visuals(new_columns, new_rows, _labels_to_visuals(new_cell_labels), new_selected_cell)


func set_cell_visuals(new_columns: int, new_rows: int, new_cell_visuals: Dictionary, new_selected_cell: Vector2i) -> void:
	columns = max(1, new_columns)
	rows = max(1, new_rows)
	cell_visuals = new_cell_visuals.duplicate(true)
	selected_cell = new_selected_cell
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		var next_hover: Vector2i = _cell_from_position(motion.position)
		if next_hover != hover_cell:
			hover_cell = next_hover
			queue_redraw()
		return
	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_LEFT and mouse_button.pressed:
			var cell: Vector2i = _cell_from_position(mouse_button.position)
			if cell.x >= 0 and cell.y >= 0:
				cell_pressed.emit(cell)
				accept_event()


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		hover_cell = Vector2i(-1, -1)
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG_COLOR, true)
	var gap: float = _get_gap()
	var cell_size: Vector2 = _get_cell_size(gap)
	for y in range(rows):
		for x in range(columns):
			var cell := Vector2i(x, y)
			var rect: Rect2 = _get_cell_rect(cell, cell_size, gap)
			var visual: Dictionary = Dictionary(cell_visuals.get(_cell_key(cell), {}))
			_draw_cell_background(cell, rect)
			if visual.is_empty() or bool(visual.get("is_empty", false)):
				_draw_empty_cell(rect, cell)
			else:
				_draw_debug_object_card(rect, visual)


func _draw_cell_background(cell: Vector2i, rect: Rect2) -> void:
	var fill: Color = CELL_SELECTED_COLOR if cell == selected_cell else CELL_COLOR
	if cell == hover_cell and cell != selected_cell:
		fill = CELL_HOVER_COLOR
	draw_rect(rect, fill, true)
	draw_rect(rect, BORDER_COLOR, false, 1.0)


func _draw_empty_cell(rect: Rect2, cell: Vector2i) -> void:
	var font: Font = get_theme_default_font()
	var font_size: int = _get_font_size(rect)
	var center_y: float = rect.position.y + rect.size.y * 0.52
	draw_string(font, Vector2(rect.position.x + 4.0, center_y), "%d,%d" % [cell.x, cell.y], HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 8.0, font_size, TEXT_COLOR)
	draw_string(font, Vector2(rect.position.x + 4.0, center_y + float(font_size + 6)), "+", HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 8.0, font_size + 2, ACCENT_COLOR)


func _draw_debug_object_card(rect: Rect2, visual: Dictionary) -> void:
	var fill_color: Color = _read_color(visual.get("fill_color", ACCENT_COLOR), ACCENT_COLOR)
	var outline_color: Color = _read_color(visual.get("outline_color", fill_color), fill_color)
	var is_selected: bool = bool(visual.get("is_selected", false))
	var card_margin: float = clamp(min(rect.size.x, rect.size.y) * 0.08, 5.0, 9.0)
	var card_rect := Rect2(rect.position + Vector2(card_margin, card_margin), rect.size - Vector2(card_margin * 2.0, card_margin * 2.0))
	var band_height: float = clamp(card_rect.size.y * 0.34, 22.0, 42.0)
	var band_rect := Rect2(card_rect.position, Vector2(card_rect.size.x, band_height))

	draw_rect(card_rect, CARD_BG, true)
	draw_rect(card_rect, outline_color, false, 5.0 if is_selected else 3.0)
	draw_rect(band_rect, fill_color, true)
	draw_rect(Rect2(card_rect.position + Vector2(0.0, band_height), Vector2(card_rect.size.x, 2.0)), DEBUG_BAND_COLOR, true)

	var font: Font = get_theme_default_font()
	var marker: String = str(visual.get("marker", "O"))
	var marker_size: int = int(clamp(card_rect.size.y * 0.46, 24.0, 44.0))
	draw_string(font, Vector2(card_rect.position.x + 4.0, card_rect.position.y + band_height - 6.0), marker, HORIZONTAL_ALIGNMENT_CENTER, card_rect.size.x - 8.0, marker_size, DARK_TEXT_COLOR)

	var label: String = str(visual.get("label", "Object"))
	var sub_label: String = str(visual.get("sub_label", ""))
	var label_size: int = int(clamp(card_rect.size.y * 0.16, 10.0, 16.0))
	var label_y: float = card_rect.position.y + band_height + float(label_size + 8)
	draw_string(font, Vector2(card_rect.position.x + 5.0, label_y), label, HORIZONTAL_ALIGNMENT_CENTER, card_rect.size.x - 10.0, label_size, TEXT_COLOR, TextServer.JUSTIFICATION_WORD_BOUND)
	if not sub_label.is_empty():
		draw_string(font, Vector2(card_rect.position.x + 5.0, label_y + float(label_size + 6)), sub_label, HORIZONTAL_ALIGNMENT_CENTER, card_rect.size.x - 10.0, max(9, label_size - 2), MUTED_TEXT_COLOR, TextServer.JUSTIFICATION_WORD_BOUND)


func _cell_from_position(position: Vector2) -> Vector2i:
	var gap: float = _get_gap()
	var cell_size: Vector2 = _get_cell_size(gap)
	if cell_size.x <= 0.0 or cell_size.y <= 0.0:
		return Vector2i(-1, -1)
	for y in range(rows):
		for x in range(columns):
			var cell := Vector2i(x, y)
			if _get_cell_rect(cell, cell_size, gap).has_point(position):
				return cell
	return Vector2i(-1, -1)


func _get_cell_size(gap: float) -> Vector2:
	var total_gap_x: float = gap * float(max(0, columns - 1))
	var total_gap_y: float = gap * float(max(0, rows - 1))
	var available_width: float = max(1.0, size.x - total_gap_x)
	var available_height: float = max(1.0, size.y - total_gap_y)
	return Vector2(available_width / float(columns), available_height / float(rows))


func _get_cell_rect(cell: Vector2i, cell_size: Vector2, gap: float) -> Rect2:
	var x: float = float(cell.x) * (cell_size.x + gap)
	var y: float = float(cell.y) * (cell_size.y + gap)
	return Rect2(Vector2(x, y), cell_size)


func _get_gap() -> float:
	return clamp(size.x * 0.008, 4.0, 8.0)


func _get_font_size(rect: Rect2) -> int:
	return int(clamp(min(rect.size.x, rect.size.y) * 0.18, 10.0, 16.0))


func _labels_to_visuals(labels: Dictionary) -> Dictionary:
	var visuals: Dictionary = {}
	for key in labels.keys():
		visuals[key] = {"label": str(labels[key]), "is_empty": false, "marker": "?"}
	return visuals


func _read_color(value: Variant, fallback: Color) -> Color:
	if value is Color:
		return value
	return fallback


func _cell_key(cell: Vector2i) -> String:
	return "%d:%d" % [cell.x, cell.y]
