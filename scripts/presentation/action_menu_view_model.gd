extends RefCounted

# Target class: ActionMenuViewModel
# View data for world/action menu.

static func create(target: Dictionary, actions: Array) -> Dictionary:
	return {
		"target": target,
		"primary_actions": actions.filter(func(a): return bool(Dictionary(a).get("enabled", true))),
		"disabled_actions": actions.filter(func(a): return not bool(Dictionary(a).get("enabled", true))),
	}
