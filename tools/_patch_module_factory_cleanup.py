#!/usr/bin/env python3
from pathlib import Path

path = Path("scripts/bipob/bipob_module_factory.gd")
source = path.read_text(encoding="utf-8")
old = '''static func create_debug_found_module() -> BipobModule:
	var module: BipobModule = BipobModuleRef.new()
	module.id = "battery_v1"
	module.display_name = "Battery V1"
	module.description = "Increases max energy by 10."
	module.energy_bonus = 10
	module.granted_commands = []
	return module

static func create_debug_field_component() -> BipobModule:
	var module: BipobModule = BipobModuleRef.new()
	module.id = "cooling_v1"
	module.module_id = "cooling_v1"
	module.display_name = "Cooling V1"
	module.description = "Basic cooling component for future internal builds."
	module.energy_bonus = 0
	module.actions_bonus = 0
	module.vision_bonus = 0
	module.granted_commands = []
	return module

static func create_legacy_gpu_v1_module() -> BipobModule:
	var module: BipobModule = BipobModuleRef.new()
	module.id = "gpu_v1"
	module.display_name = "GPU V1"
	module.description = "Internal processing module. Increases vision range and supports hidden node detection."
	module.granted_commands = ["hidden_detection_support"]
	module.vision_bonus = 0
	return module

static func create_legacy_legs_v1_module() -> BipobModule:
	var module: BipobModule = BipobModuleRef.new()
	module.id = "legs_v1"
	module.display_name = "Legs V1"
	module.placement_type = "external"
	module.category = "locomotion"
	module.internal_role = "none"
	module.description = "Bottom locomotion module for stepped terrain."
	module.granted_commands = ["move_forward", "move_backward", "turn_left", "turn_right", "cross_stepped_floor"]
	apply_thermal_metadata(module)
	apply_damage_metadata(module)
	return module
'''
new = '''static func create_debug_found_module() -> BipobModule:
	var module := create_internal_module("battery_v1")
	if module == null:
		return null
	module.description = "Increases max energy by 10."
	module.energy_bonus = 10
	module.granted_commands = []
	return module

static func create_debug_field_component() -> BipobModule:
	var module := create_internal_module("cooler_v1")
	if module == null:
		return null
	module.id = "cooling_v1"
	module.module_id = "cooling_v1"
	module.display_name = "Cooling V1"
	module.description = "Basic cooling component for future internal builds."
	module.energy_bonus = 0
	module.actions_bonus = 0
	module.vision_bonus = 0
	module.granted_commands = []
	return module

static func create_legacy_gpu_v1_module() -> BipobModule:
	var module := create_internal_module("gpu_v1")
	if module == null:
		return null
	module.description = "Internal processing module. Increases vision range and supports hidden node detection."
	module.granted_commands = ["hidden_detection_support"]
	module.vision_bonus = 0
	return module

static func create_legacy_legs_v1_module() -> BipobModule:
	var module := create_external_module("legs_v1")
	if module == null:
		return null
	module.category = "locomotion"
	module.description = "Bottom locomotion module for stepped terrain."
	module.granted_commands = ["move_forward", "move_backward", "turn_left", "turn_right", "cross_stepped_floor"]
	return module
'''
if source.count(old) != 1:
    raise SystemExit("expected legacy constructor block exactly once")
updated = source.replace(old, new)
if updated.count("BipobModuleRef.new()") != 2:
    raise SystemExit("factory must construct modules only in canonical external/internal paths")
path.write_text(updated, encoding="utf-8")
print("Patched BipobModuleFactory compatibility constructors")
