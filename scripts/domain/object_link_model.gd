extends RefCounted

# Target class: ObjectLinkModel
# Чистая модель связи между объектами. Backlinks строятся через LinkSystem.

static func make_link(source_id: String, link_type: String, target_id: String, metadata: Dictionary = {}) -> Dictionary:
	return {
		"source_id": source_id,
		"link_type": link_type,
		"target_id": target_id,
		"metadata": metadata.duplicate(true),
	}

static func is_valid_link(link: Dictionary) -> bool:
	return not str(link.get("source_id", "")).is_empty() and not str(link.get("link_type", "")).is_empty()
