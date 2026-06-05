extends RefCounted
class_name InteractionActionCostService


const DEFAULT_ACTION_COST: int = 1
const DEFAULT_ENERGY_COST: int = 1


static func can_commit_gameplay_action(controller: Variant, action_cost: int = DEFAULT_ACTION_COST, energy_cost: int = DEFAULT_ENERGY_COST) -> bool:
	return controller != null and controller.has_method("can_spend_action") and bool(controller.call("can_spend_action", action_cost, energy_cost))


static func commit_gameplay_action(controller: Variant, execution_result: Dictionary, action_cost: int = DEFAULT_ACTION_COST, energy_cost: int = DEFAULT_ENERGY_COST, register_paid_action: bool = true) -> bool:
	if controller == null or bool(execution_result.get("spent_action", false)):
		return false
	if not can_commit_gameplay_action(controller, action_cost, energy_cost):
		execution_result["reason"] = "insufficient_resources"
		if not execution_result.has("message") or str(execution_result.get("message", "")).is_empty():
			execution_result["message"] = "Not enough action/energy."
		return false
	controller.call("spend_action", action_cost, energy_cost)
	if register_paid_action and controller.has_method("_register_successful_paid_player_action"):
		controller.call("_register_successful_paid_player_action", true)
	execution_result["spent_action"] = true
	execution_result["pending_paid_action"] = false
	return true
