extends Node

# Target class: AppRoot
# Главный composition root новой архитектуры.
# Не содержит gameplay/UI rules, только собирает зависимости и запускает AppStateMachine.

var app_state_machine: Node = null
var scene_router: Node = null
var input_router: Node = null
var save_load_service: Node = null

func boot() -> void:
	pass

func shutdown() -> void:
	pass
