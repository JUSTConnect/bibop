extends RefCounted

# Target class: LinkSystem
# Единый owner links/backlinks. UI не пишет backlinks вручную.

var repository: RefCounted = null

func get_links(_object_id: String) -> Array[Dictionary]:
	return []

func get_backlinks(_object_id: String) -> Array[Dictionary]:
	return []

func get_link_targets(_object_id: String, _link_type: String) -> Array[Dictionary]:
	return []

func set_link(source_id: String, link_type: String, target_id: String) -> Dictionary:
	return {"ok": true, "message": "Link set.", "changed_ids": [source_id, target_id], "link_type": link_type}

func clear_link(source_id: String, link_type: String) -> Dictionary:
	return {"ok": true, "message": "Link cleared.", "changed_ids": [source_id], "link_type": link_type}

func rebuild_backlinks() -> void:
	pass
