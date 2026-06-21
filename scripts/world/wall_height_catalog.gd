extends RefCounted
class_name WallHeightCatalog

const WALL_HEIGHT_LEVELS: Array[String] = ["low", "halflow", "mid", "halfmid", "tall"]
const FLOOR_HEIGHT_LEVELS: Array[String] = ["default", "step_1", "step_2"]

const WALL_HEIGHT_ROWS: Array[Dictionary] = [
	{"id":"", "display_name":"Auto", "description":"Use production wall height defaults; outer walls keep the depth-based gradient."},
	{"id":"tall", "display_name":"Tall", "description":"Use the tall production wall asset."},
	{"id":"halfmid", "display_name":"Half Mid", "description":"Use the half-mid production wall asset."},
	{"id":"mid", "display_name":"Mid", "description":"Use the mid production wall asset."},
	{"id":"halflow", "display_name":"Half Low", "description":"Use the half-low production wall asset."},
	{"id":"low", "display_name":"Low", "description":"Use the low production wall asset; grate normalizes low heights to mid."}
]

const FLOOR_HEIGHT_ROWS: Array[Dictionary] = [
	{"id":"default", "display_name":"Default", "description":"Normal flat floor with no raised ground base."},
	{"id":"step_1", "display_name":"1 Step", "description":"Raised low ground visual base below the floor material."},
	{"id":"step_2", "display_name":"2 Step", "description":"Raised half-low ground visual base below the floor material."}
]

const WALL_HEIGHT_ALIASES: Dictionary = {
	"":"", "auto":"", "default":"",
	"highest":"tall", "tallest":"tall", "high":"tall", "tall":"tall",
	"half":"halfmid", "halfmedium":"halfmid", "halfmid":"halfmid", "uppermid":"halfmid",
	"medium":"mid", "middle":"mid", "mid":"mid",
	"halflow":"halflow", "halflowheight":"halflow", "halfshort":"halflow", "halflowest":"halflow",
	"short":"low", "lowest":"low", "low":"low"
}

const FLOOR_HEIGHT_ALIASES: Dictionary = {
	"":"default", "empty":"default", "default":"default", "flat":"default", "normal":"default",
	"1":"step_1", "step1":"step_1", "low":"step_1", "groundlow":"step_1",
	"2":"step_2", "step2":"step_2", "halflow":"step_2", "groundhalflow":"step_2"
}

static func _token(value: String) -> String:
	var result := value.strip_edges().to_lower()
	result = result.replace(" ", "")
	result = result.replace("-", "")
	result = result.replace("_", "")
	return result

static func normalize_wall_height(value: String, fallback: String = "") -> String:
	return str(WALL_HEIGHT_ALIASES.get(_token(value), fallback))

static func is_known_wall_height(value: String) -> bool:
	return WALL_HEIGHT_ALIASES.has(_token(value))

static func normalize_floor_height(value: String, fallback: String = "default") -> String:
	return str(FLOOR_HEIGHT_ALIASES.get(_token(value), fallback))

static func is_known_floor_height(value: String) -> bool:
	return FLOOR_HEIGHT_ALIASES.has(_token(value))

static func get_wall_catalog() -> Dictionary:
	var rows: Array[Dictionary] = []
	for row in WALL_HEIGHT_ROWS:
		rows.append(row.duplicate(true))
	return {"ok": true, "heights": rows, "message": "Wall height catalog ready."}

static func get_floor_catalog() -> Dictionary:
	var rows: Array[Dictionary] = []
	for row in FLOOR_HEIGHT_ROWS:
		rows.append(row.duplicate(true))
	return {"ok": true, "heights": rows, "message": "Floor height catalog ready."}

static func validate_catalog() -> Array[String]:
	var errors: Array[String] = []
	for height in WALL_HEIGHT_LEVELS:
		if not is_known_wall_height(height):
			errors.append("wall_height_missing_alias_%s" % height)
	for height in FLOOR_HEIGHT_LEVELS:
		if not is_known_floor_height(height):
			errors.append("floor_height_missing_alias_%s" % height)
	return errors
