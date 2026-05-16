extends Resource
class_name DiagnosticResult

const STATUS_READY := "READY"
const STATUS_RISKY := "RISKY"
const STATUS_BLOCKED := "BLOCKED"

@export var status: String = STATUS_BLOCKED
@export var device_type: String = ""
@export var device_name: String = ""
@export var supported_action: String = ""
@export var reason: String = ""
@export var recommendation: String = ""
@export var estimated_risk: String = "low"

static func make_ready(device: DeviceDefinition) -> DiagnosticResult:
	var result := DiagnosticResult.new()
	result.status = STATUS_READY
	if device != null:
		result.device_type = device.device_type
		result.device_name = device.display_name
		result.supported_action = device.required_command
	result.reason = "Device is operable."
	result.recommendation = "Proceed with caution."
	result.estimated_risk = "low"
	return result

static func make_risky(device: DeviceDefinition, diagnostic_reason: String, diagnostic_recommendation: String) -> DiagnosticResult:
	var result := DiagnosticResult.new()
	result.status = STATUS_RISKY
	if device != null:
		result.device_type = device.device_type
		result.device_name = device.display_name
		result.supported_action = device.required_command
	result.reason = diagnostic_reason
	result.recommendation = diagnostic_recommendation
	result.estimated_risk = "medium"
	return result

static func make_blocked(device: DeviceDefinition, diagnostic_reason: String, diagnostic_recommendation: String) -> DiagnosticResult:
	var result := DiagnosticResult.new()
	result.status = STATUS_BLOCKED
	if device != null:
		result.device_type = device.device_type
		result.device_name = device.display_name
		result.supported_action = device.required_command
	result.reason = diagnostic_reason
	result.recommendation = diagnostic_recommendation
	result.estimated_risk = "high"
	return result

func is_action_allowed() -> bool:
	return status == STATUS_READY or status == STATUS_RISKY

func get_status_text() -> String:
	match status:
		STATUS_READY:
			return "READY"
		STATUS_RISKY:
			return "RISKY"
		STATUS_BLOCKED:
			return "BLOCKED"
		_:
			return "UNKNOWN"
