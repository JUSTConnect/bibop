extends RefCounted

const V1ToV2Ref = preload("res://scripts/map_constructor/migrations/map_v1_to_v2.gd")
const V2ToV3Ref = preload("res://scripts/map_constructor/migrations/map_v2_to_v3.gd")
const TARGET_VERSION := 3

static func migrate(source: Dictionary) -> Dictionary:
	var document: Dictionary = source.duplicate(true)
	var version: int = int(document.get("version", 1))
	if version <= 1:
		document = V1ToV2Ref.migrate(document)
		version = 2
	if version == 2:
		document = V2ToV3Ref.migrate(document)
		version = 3
	if version != TARGET_VERSION:
		return {}
	return document
