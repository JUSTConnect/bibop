extends RefCounted

# Target class: AccessModel
# Чистые правила доступа: code, key_card, digital_key, terminal.

const ACCESS_NONE := "none"
const ACCESS_CODE := "access_code"
const ACCESS_KEY_CARD := "key_card"
const ACCESS_DIGITAL_KEY := "digital_key"
const ACCESS_TERMINAL := "terminal"

static func normalize_access_mode(value: Variant) -> String:
	var text := str(value).strip_edges().to_lower()
	match text:
		"code", "password": return ACCESS_CODE
		"keycard", "key_card": return ACCESS_KEY_CARD
		"digital", "digital_key": return ACCESS_DIGITAL_KEY
		"terminal", "terminal_access": return ACCESS_TERMINAL
		_: return ACCESS_NONE
