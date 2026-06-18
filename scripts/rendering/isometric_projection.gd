extends RefCounted

# Target class: IsometricProjection
# Единая изометрическая проекция для renderer/editor previews.

const TILE_WIDTH := 512.0
const TILE_HEIGHT := 256.0

static func cell_to_screen(cell: Vector2i) -> Vector2:
	return Vector2((cell.x - cell.y) * TILE_WIDTH * 0.5, (cell.x + cell.y) * TILE_HEIGHT * 0.5)

static func screen_to_cell(_screen_pos: Vector2) -> Vector2i:
	return Vector2i.ZERO
