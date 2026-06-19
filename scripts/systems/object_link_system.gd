extends RefCounted

# ObjectLinkSystem
# Фильтрует и валидирует links по links_schema.

const LINK_TARGET_TYPES := {
	"power_source": ["power_source"],
	"controlled_targets": ["door"],
	"access_terminal": ["terminal"],
	"required_key": ["key", "item"]
}

static func get_allowed_target_ids(link_id: String, link_type: String, current_id: String, targets: Array[Dictionary]) -> Array[String]:
	if link_type != "object_ref" and link_type != "object_ref_array":
		return []
	var allowed_types: Array = Array(LINK_TARGET_TYPES.get(link_id, []))
	var result: Array[String] = []
	for target in targets:
		var target_id: String = str(target.get("id", ""))
		if target_id.is_empty() or target_id == current_id:
			continue
		var target_type: String = str(target.get("object_type", ""))
		if allowed_types.is_empty() or target_type in allowed_types:
			result.append(target_id)
	return result

static func validate_links(links: Dictionary, links_schema: Array, current_id: String, targets: Array[Dictionary]) -> Array[String]:
	var warnings: Array[String] = []
	for link_variant in links_schema:
		var link: Dictionary = Dictionary(link_variant)
		var link_id: String = str(link.get("id", ""))
		var link_type: String = str(link.get("type", ""))
		if link_id.is_empty():
			continue
		var allowed: Array[String] = get_allowed_target_ids(link_id, link_type, current_id, targets)
		var value: Variant = links.get(link_id, [] if link_type == "object_ref_array" else "")
		if link_type == "object_ref" and not str(value).is_empty() and not str(value) in allowed:
			warnings.append("Invalid link %s -> %s" % [link_id, str(value)])
		if link_type == "object_ref_array":
			for item in Array(value):
				if not str(item) in allowed:
					warnings.append("Invalid link %s -> %s" % [link_id, str(item)])
	return warnings
