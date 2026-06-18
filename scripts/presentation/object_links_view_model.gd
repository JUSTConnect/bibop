extends RefCounted

# Target class: ObjectLinksViewModel
# Link rows for inspector. Targets come from LinkSystem.

static func create(link_rows: Array) -> Dictionary:
	return {
		"section_id": "links",
		"title": "4. Links",
		"rows": link_rows,
	}
