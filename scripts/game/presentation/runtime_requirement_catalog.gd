extends RefCounted
class_name RuntimeRequirementCatalog

static func deduplicate(requirements: Array) -> Array[Dictionary]:
	var by_key: Dictionary = {}
	for value in requirements:
		if value is Dictionary:
			var item: Dictionary = Dictionary(value).duplicate(true)
			by_key[JSON.stringify(item)] = item
	var keys: Array = by_key.keys()
	keys.sort()
	var result: Array[Dictionary] = []
	for key in keys:
		result.append(Dictionary(by_key[key]).duplicate(true))
	return result
