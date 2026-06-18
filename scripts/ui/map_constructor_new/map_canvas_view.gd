extends Control

# MapCanvasView
# Responsive canvas for map cells.
# Важно: canvas не задаёт ширину layout через child-buttons. Он рисует клетки внутри доступного rect.

signal cell_pressed(cell: Vector2i)

const BG_COLOR := Color(0.075, 0.09, 0.12, 1.0)
const CELL_COLOR := Color(0.08, 0.095, 0.125, 1.0)
const CELL_HOVER_COLOR := Color(0.105, 0.14, 0.18, 1.0)
const CELL_SELECTED_COLOR := Color(0.12, 0.22, 0.28, 1.0)
const BORDER_COLOR := Color(0.25, 0.5, 0.62, 0.85)
const TEXT_COLOR := Color(0.88, 0.91, 0.94, 1.0)
const ACCENT_COLOR := Color(0.25, 0.78, 0.95, 1.0)

var columns: int = 1
var rows: int = 1
var cell_labels: Dictionary = {}
var selected_cell: Vector2i = Vector2i(-1, -1)
var hover_cell: Vector2i = Vector2i(-1, -1)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	resized.connect(func() -> void:
		queue_redraw()
	)


func set_cells(new_columns: int, new_rows: int, new_cell_labels: Dictionary, new_selected_cell: Vector2i) -> void:
	columns = max(1, new_columns)
	rows = max(1, new_rows)
	cell_labels = new_cell_labels.duplicate(true)
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
			var fill: Color = CELL_SELECTED_COLOR if cell == selected_cell else CELL_COLOR
			if cell == hover_cell and cell != selected_cell:
				fill = CELL_HOVER_COLOR
			draw_rect(rect, fill, true)
			draw_rect(rect, BORDER_COLOR, false, 1.0)
			_draw_cell_label(rect, str(cell_labels.get(_cell_key(cell), "%d,%d\n+" % [x, y])))


func _draw_cell_label(rect: Rect2, text: String) -> void:
	var font: Font = get_theme_default_font()
	var font_size: int = _get_font_size(rect)
	var lines: PackedStringArray = text.split("\n", false)
	var line_height: float = float(font_size + 4)
	var total_height: float = line_height * float(lines.size())
	var y: float = rect.position.y + max(0.0, (rect.size.y - total_height) * 0.5) + float(font_size)
	for raw_line in lines:
		var line: String = String(raw_line)
		var color: Color = ACCENT_COLOR if line == "+" else TEXT_COLOR
		draw_string(font, Vector2(rect.position.x + 5.0, y), line, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 10.0, font_size, color, TextServer.JUSTIFICATION_WORD_BOUND)
		y += line_height


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


func _cell_key(cell: Vector2i) -> String:
	return "%d:%d" % [cell.x, cell.y]
