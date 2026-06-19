extends RefCounted

const VisualCatalogRef = preload("res://scripts/rendering/object_visual_catalog.gd")

static func run() -> Array[String]:
	var errors: Array[String] = []
	var catalog: RefCounted = VisualCatalogRef.new()
	catalog.call("load_from_path")
	for visual_id: String in ["power_source_01", "terminal_01", "object_door", "power_cable_01"]:
		var entry: Dictionary = Dictionary(catalog.call("get_entry", visual_id))
		if entry.is_empty():
			errors.append("Missing visual catalog entry: %s" % visual_id)
		elif str(entry.get("fallback_marker", "")).is_empty():
			errors.append("Missing fallback marker: %s" % visual_id)
	return errors
