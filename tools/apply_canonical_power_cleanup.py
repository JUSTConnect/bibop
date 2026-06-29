#!/usr/bin/env python3
from pathlib import Path

power_path = Path("scripts/world/power_system.gd")
power = power_path.read_text()
old_reset = '''		if not normalized_filter.is_empty() and str(object_data.get("power_network_id", "")) != normalized_filter and str(object_data.get("power_source_id", "")) != normalized_filter and str(object_data.get("physical_connection_source_id", "")) != normalized_filter:
			continue
		object_data["is_powered"] = false
		object_data["power_source_id"] = ""
		object_data["physical_connection_source_id"] = ""
'''
new_reset = '''		if not normalized_filter.is_empty() and str(object_data.get("power_network_id", "")) != normalized_filter and str(object_data.get("resolved_source_id", "")) != normalized_filter:
			continue
		object_data["is_powered"] = false
		object_data["power_state"] = "unpowered"
		object_data["resolved_source_id"] = ""
		object_data["resolved_circuit_id"] = ""
'''
if power.count(old_reset) != 1:
    raise SystemExit("power reset marker missing")
power = power.replace(old_reset, new_reset, 1)
old_virtual = '''		if not is_power_component(object_data):
			# Compatibility: objects previously assigned to the legacy virtual main net
			# stay available until they are explicitly rewired into physical topology.
			if normalized_filter == "main_power_net" and str(object_data.get("power_network_id", "")) == normalized_filter:
				object_data["is_powered"] = bool(object_data.get("power_enabled", object_data.get("state", "on") != "off"))
			continue
'''
new_virtual = '''		if not is_power_component(object_data):
			continue
'''
if power.count(old_virtual) != 1:
    raise SystemExit("main_power_net compatibility marker missing")
power = power.replace(old_virtual, new_virtual, 1)
old_supply = '''		current_obj["is_powered"] = true
		current_obj["power_source_id"] = source_id
		current_obj["physical_connection_source_id"] = source_id
'''
new_supply = '''		current_obj["is_powered"] = true
		current_obj["power_state"] = "powered"
		current_obj["resolved_source_id"] = source_id
		current_obj["resolved_circuit_id"] = "main"
'''
if power.count(old_supply) != 1:
    raise SystemExit("power traversal supply marker missing")
power = power.replace(old_supply, new_supply, 1)
power_path.write_text(power)

cable_path = Path("scripts/game/bipob_cable_runtime_service.gd")
cable = cable_path.read_text()
old_target = '''			target["is_powered"] = power_available
			target["power_source_id"] = resolved_source_id if power_available else ""
			target["physical_connection_source_id"] = resolved_source_id if power_available else ""
			target["power_state"] = "powered" if power_available else "unpowered"
'''
new_target = '''			target["is_powered"] = power_available
			target["power_state"] = "powered" if power_available else "unpowered"
			target["resolved_source_id"] = resolved_source_id if power_available else ""
			target["resolved_circuit_id"] = "main" if power_available else ""
'''
if cable.count(old_target) != 1:
    raise SystemExit("runtime cable target supply marker missing")
cable = cable.replace(old_target, new_target, 1)
cable_path.write_text(cable)
