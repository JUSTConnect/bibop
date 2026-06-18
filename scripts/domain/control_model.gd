extends RefCounted

# Target class: ControlModel
# Чистые правила control mode.

const CONTROL_NONE := "none"
const CONTROL_INTERNAL := "internal"
const CONTROL_EXTERNAL := "external"

static func normalize_control_mode(value: Variant) -> String:
	var text := str(value).strip_edges().to_lower()
	return text if text in [CONTROL_NONE, CONTROL_INTERNAL, CONTROL_EXTERNAL] else CONTROL_NONE
