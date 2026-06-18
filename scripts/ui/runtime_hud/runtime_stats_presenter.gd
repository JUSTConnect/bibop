extends RefCounted

# Target class: RuntimeStatsPresenter
# Refreshes energy/actions/health/turn labels.

static func refresh(stats_strip: Control, view_model: Dictionary) -> void:
	if stats_strip == null or not is_instance_valid(stats_strip):
		return
	stats_strip.set_meta("energy", view_model.get("energy", 0))
	stats_strip.set_meta("actions", view_model.get("actions", 0))
