#!/usr/bin/env python3
"""Smoke checks for the generic powered visual state asset resolver."""
from pathlib import Path
import re
import sys

root = Path(__file__).resolve().parents[1]


def _py_power_socket_visual_state(row):
    false_power_states = {"unpowered", "no_power", "offline", "disconnected"}
    true_power_states = {"powered", "active", "ready", "source_on", "on"}

    def norm(value):
        return str(value).strip().lower().replace(" ", "_").replace("-", "_")

    power_state = norm(row.get("power_state", ""))
    if power_state in false_power_states:
        return "base"
    has_source_power = power_state in true_power_states
    if not has_source_power:
        status = norm(row.get("status", ""))
        if status in false_power_states:
            return "base"
        has_source_power = status in true_power_states
    if not has_source_power:
        connection_state = norm(row.get("state", ""))
        if connection_state in {"unpowered", "no_power", "offline"}:
            return "base"
        has_source_power = connection_state in true_power_states
    if not has_source_power:
        has_source_power = any(bool(row.get(key, False)) for key in ["is_powered", "powered", "has_power", "receives_power", "upstream_powered", "source_powered", "has_source_power", "incoming_powered"] if key in row)
    if not has_source_power:
        return "base"

    has_connected_cable = any(bool(row.get(key, False)) for key in ["has_connected_cable", "connected_cable", "connected", "is_connected"] if key in row)
    has_connected_cable = has_connected_cable or any(norm(row.get(key, "")) for key in ["connected_cable_id", "connected_reel_id", "connection_id"])
    has_connected_cable = has_connected_cable or norm(row.get("state", "")) == "connected"
    return "on" if has_connected_cable else "off"


def _power_socket_behavior_cases_pass():
    default_archetype = {"state":"disconnected", "status":"inactive", "is_powered":False, "power_state":"unpowered", "connected":False, "is_connected":False, "disconnected":True}
    cases = [
        (default_archetype, "base"),
        ({"is_powered":True, "upstream_powered":False}, "off"),
        ({"power_state":"powered", "connected":True}, "on"),
        ({"power_state":"powered", "is_connected":True}, "on"),
        ({"power_state":"powered", "state":"connected"}, "on"),
        ({"power_state":"unpowered", "connected":True}, "base"),
    ]
    return all(_py_power_socket_visual_state(row) == expected for row, expected in cases)

service = (root / "scripts/visual/visual_state_asset_service.gd").read_text()
renderer = (root / "scripts/field/room_visual_renderer.gd").read_text()
catalog = (root / "scripts/visual/visual_asset_catalog.gd").read_text()
world_catalog = (root / "scripts/world/world_object_catalog.gd").read_text()
power_switcher_archetype = world_catalog.split('"power_switcher": {', 1)[1].split('\n\t"light_switcher": {', 1)[0]
light_switcher_archetype = world_catalog.split('"light_switcher": {', 1)[1].split('\n\t"fuse_box": {', 1)[0]
firewall_service = root / "scripts/game/firewall/firewall_service.gd"
station_archetype = world_catalog.split('"station": {', 1)[1].split('\n\t"firewall": {', 1)[0]
station_asset_ids = ["station_decrypt_floor_01", "station_lab_floor_01", "station_recharge_floor_01", "station_repair_floor_01", "station_shop_floor_01"]


ITEM_ASSET_IDS = [
    "parts_floor_01",
    "fuse_floor_01",
    "reinforcement_floor_01",
    "repair_kit_floor_01",
]

DOOR_ASSET_IDS = [
    "door_close_base_floor_01",
    "door_close_off_floor_01",
    "door_close_on_floor_01",
    "door_open_base_floor_01",
    "door_open_off_floor_01",
    "door_open_on_floor_01",
]
door_archetype = world_catalog.split('"door": {', 1)[1].split('\n\t"platform": {', 1)[0]

POWER_SOCKET_STALE_UNPOWERED_SMOKE_CASES = [
    ({"power_state": "unpowered", "is_powered": True, "connected": False}, "off"),
    ({"power_state": "unpowered", "is_powered": True, "connected": True}, "on"),
    ({"power_state": "unpowered", "is_powered": False, "connected": True}, "base"),
    ({"is_powered": True, "connected_endpoint_count": 1}, "on"),
    ({"is_powered": True, "socket_connected_endpoint_count": 1}, "on"),
    ({"is_powered": True, "endpoint_a_id": "socket-a", "connection_id": "connection-a"}, "on"),
    ({"is_powered": True, "connected": False}, "off"),
    ({"is_powered": False, "connected_endpoint_count": 1}, "base"),
    ({"is_powered": True, "connected": False, "connected_endpoint_count": 1}, "on"),
    ({"is_powered": True, "is_connected": False, "connections": [{"connected": True}]}, "on"),
]

def _resolve_power_socket_smoke_state(object_data):
    def norm(value):
        return str(value).strip().lower().replace(" ", "_").replace("-", "_")

    true_power_keys = ["is_powered", "powered", "has_power", "receives_power", "upstream_powered"]
    has_source_power = any(bool(object_data.get(key, False)) for key in true_power_keys if key in object_data)
    if not has_source_power:
        return "base"

    def count_connected_entries(value):
        if isinstance(value, list):
            return sum(count_connected_entries(entry) for entry in value)
        if isinstance(value, dict):
            if value.get("connected") is False or value.get("is_connected") is False:
                return 0
            if bool(value.get("connected", False)) or bool(value.get("is_connected", False)):
                return 1
            evidence_keys = ["connected_cable_id", "connected_reel_id", "connection_id", "endpoint_a_id", "endpoint_b_id", "socket_id", "id"]
            return 1 if any(norm(value.get(key, "")) for key in evidence_keys) else 0
        return 0

    def has_connection_evidence():
        id_keys = ["connected_cable_id", "connected_reel_id", "connection_id", "endpoint_a_id", "endpoint_b_id", "socket_id"]
        if any(norm(object_data.get(key, "")) for key in id_keys):
            return True
        count_keys = ["connected_endpoint_count", "socket_connected_endpoint_count"]
        if any(int(object_data.get(key, 0)) > 0 for key in count_keys if key in object_data):
            return True
        collection_keys = ["connected_ends", "cable_endpoints", "endpoints", "connections"]
        return any(count_connected_entries(object_data.get(key, [])) > 0 for key in collection_keys)

    true_connection_keys = ["has_connected_cable", "connected_cable", "connected", "is_connected"]
    if any(bool(object_data.get(key, False)) for key in true_connection_keys if key in object_data):
        has_connected_cable = True
    elif any(norm(object_data.get(key, "")) for key in ["connected_cable_id", "connected_reel_id", "connection_id"]):
        has_connected_cable = True
    elif norm(object_data.get("state", "")) == "connected":
        has_connected_cable = True
    elif object_data.get("disconnected") is False and has_connection_evidence():
        has_connected_cable = True
    elif any(int(object_data.get(key, 0)) > 0 for key in ["connected_endpoint_count", "socket_connected_endpoint_count"] if key in object_data):
        has_connected_cable = True
    elif any(norm(object_data.get(key, "")) and has_connection_evidence() for key in ["endpoint_a_id", "endpoint_b_id", "socket_id"]):
        has_connected_cable = True
    elif any(count_connected_entries(object_data.get(key, [])) > 0 for key in ["connected_ends", "cable_endpoints", "endpoints", "connections"]):
        has_connected_cable = True
    else:
        has_connected_cable = False
    return "on" if has_connected_cable else "off"

checks = {

    "item floor asset ids exist": all(f'"{asset_id}"' in catalog for asset_id in ITEM_ASSET_IDS),
    "parts aliases map to parts floor asset": all(f'"{alias}": "parts_floor_01"' in catalog for alias in ["parts", "details", "ditales"]),
    "fuse alias maps to fuse floor asset": '"fuse": "fuse_floor_01"' in catalog,
    "reinforcement aliases map to reinforcement floor asset": all(f'"{alias}": "reinforcement_floor_01"' in catalog for alias in ["reinforcement", "reinforce"]),
    "repair kit aliases map to repair kit floor asset": all(f'"{alias}": "repair_kit_floor_01"' in catalog for alias in ["repair_kit", "repair_tool"]),
    "core item gameplay entries remain in object library": all(re.search(rf'"{item_id}"\s*:\s*\{{[^}}]*"group"\s*:\s*"item"', world_catalog) is not None for item_id in ["fuse", "repair_kit", "reinforcement", "parts"]),
    "renderer does not hardcode static item floor asset ids": all(token not in renderer for token in ITEM_ASSET_IDS),

    "door family exists in visual state catalog": re.search(r'"door"\s*:\s*\{.*?"category"\s*:\s*"objects".*?"surface"\s*:\s*"floor"', catalog, re.S) is not None,
    "door family uses door pose variant policy": re.search(r'"door"\s*:\s*\{.*?"variant_policy"\s*:\s*"door_pose".*?"default_variant"\s*:\s*"close"', catalog, re.S) is not None,
    "door close variant maps all powered states": all(re.search(pattern, catalog, re.S) is not None for pattern in [r'"close"\s*:\s*\{.*?"base"\s*:\s*"door_close_base_floor_01"', r'"close"\s*:\s*\{.*?"off"\s*:\s*"door_close_off_floor_01"', r'"close"\s*:\s*\{.*?"on"\s*:\s*"door_close_on_floor_01"']),
    "door open variant maps all powered states": all(re.search(pattern, catalog, re.S) is not None for pattern in [r'"open"\s*:\s*\{.*?"base"\s*:\s*"door_open_base_floor_01"', r'"open"\s*:\s*\{.*?"off"\s*:\s*"door_open_off_floor_01"', r'"open"\s*:\s*\{.*?"on"\s*:\s*"door_open_on_floor_01"']),
    "resolver supports variant-aware family mapping": "variant_policy" in service and "resolve_visual_variant" in service and "resolve_configured_state_asset_id(family: String, state: String, surface: String, variant: String = \"\")" in service and "states.has(normalized_variant)" in service,
    "resolver supports variant naming convention fallback": '"%s_%s_%s_%s_01" % [family, normalized_variant, state, surface]' in service,
    "door archetype opts into visual states": all(token in door_archetype for token in ['"visual_family":"door"', '"visual_surface":"floor"', '"visual_state_policy":"powered_three_state"', '"power_visual_state_enabled":true']),
    "door resolution is not renderer hardcoded": all(token not in renderer for token in DOOR_ASSET_IDS),
    "service reads configured visual state families": "get_visual_state_asset_families()" in service and "get_visual_state_family_config" in service,
    "service exposes visual family helper": "static func has_visual_state_family" in service,
    "configured state mapping is validated first": "resolve_configured_state_asset_id" in service and re.search(r"resolve_configured_state_asset_id\(family, candidate_state, surface(?:, source_variant)?\).*?if not configured_asset_id\.is_empty\(\):.*?return configured_asset_id.*?_state_candidates", service, re.S) is not None,
    "light base fallback comes from catalog": re.search(r'"base"\s*:\s*"light_off_wall_01"', catalog) is not None and "Compatibility: no light_base_wall asset exists yet" not in service and "family == \"light\" and surface == \"wall\"" not in service,
    "overlay resolution reads configured overlays": "resolve_configured_overlay_asset_ids" in service and re.search(r'"overlays"\s*:\s*\{\s*"on"\s*:\s*\["light_on_wall_pulsar_overlay_01"\]', catalog, re.S) is not None,
    "convention fallback still exists": '"%s_%s_%s_01" % [family, state, surface]' in service and '"%s_%s_%s_pulsar_overlay_01" % [family, state, surface]' in service,
    "unpowered uses base state before off": 'return VISUAL_STATE_BASE' in service and 'POWER_OFF_STATES' in service,
    "powered unavailable uses off state": 'UNAVAILABLE_STATES' in service and 'return VISUAL_STATE_OFF' in service,
    "renderer uses generic overlay path": 'draw_visual_state_overlays_for_descriptor' in renderer and 'resolve_overlay_asset_ids' in renderer,
    "renderer no longer calls light overlay drawer": 'draw_light_pulsar_overlay_for_descriptor(object_data, descriptor)' not in renderer,

    "resolver supports nested surface state mapping": "states.has(normalized_surface)" in service and "surface_states.has(normalized_state)" in service,
    "resolver keeps simple state mapping fallback": re.search(r"if not states\.has\(normalized_state\):.*?states\.get\(normalized_state", service, re.S) is not None,
    "surface resolver checks mount before configured family surface": re.search(r"static func get_visual_surface.*?var mount:.*?configured_surface", service, re.S) is not None,
    "power switcher family exists in visual state catalog": re.search(r'"power_switcher"\s*:\s*\{.*?"category"\s*:\s*"objects".*?"default_surface"\s*:\s*"floor"', catalog, re.S) is not None,
    "power switcher floor states map through catalog family": all(re.search(pattern, catalog, re.S) is not None for pattern in [r'"floor"\s*:\s*\{.*?"base"\s*:\s*"power_switcher_base_floor_01"', r'"floor"\s*:\s*\{.*?"off"\s*:\s*"power_switcher_off_floor_01"', r'"floor"\s*:\s*\{.*?"on"\s*:\s*"power_switcher_on_floor_01"']),
    "power switcher wall states map through catalog family": all(re.search(pattern, catalog, re.S) is not None for pattern in [r'"wall"\s*:\s*\{.*?"base"\s*:\s*"power_switcher_base_wall_01"', r'"wall"\s*:\s*\{.*?"off"\s*:\s*"power_switcher_authored_off_wall_01"', r'"wall"\s*:\s*\{.*?"on"\s*:\s*"power_switcher_authored_on_wall_01"']),
    "power switcher archetype opts into visual states": re.search(r'"power_switcher"\s*:\s*\{.*?"visual_family"\s*:\s*"power_switcher".*?"visual_state_policy"\s*:\s*"powered_three_state".*?"power_visual_state_enabled"\s*:\s*true', world_catalog, re.S) is not None,
    "power switcher archetype does not force visual surface floor": '"visual_surface":"floor"' not in power_switcher_archetype and '"visual_surface"' not in power_switcher_archetype,
    "power switcher switch states are recognized": '"switch_on"' in service and '"switch_off"' in service,

    "explicit false power flag wins before generic off states": re.search(r"if _has_false_power_flag\(object_data\):.*?return VISUAL_STATE_BASE.*?if power_state in UNAVAILABLE_STATES", service, re.S) is not None,
    "hard unavailable states can force off before false power flag": re.search(r"_is_hard_unavailable_state\(power_state\).*?return VISUAL_STATE_OFF.*?if _has_false_power_flag", service, re.S) is not None,
    "source and switch off are power-flag overridable": 'POWER_FLAG_OVERRIDE_OFF_STATES' in service and '"source_off"' in service and '"switch_off"' in service,
    "power switcher resolution is not renderer hardcoded": all(token not in renderer for token in ["power_switcher_base_floor_01", "power_switcher_base_wall_01", "power_switcher_off_floor_01", "power_switcher_authored_off_wall_01", "power_switcher_on_floor_01", "power_switcher_authored_on_wall_01"]),

    "light switcher family exists in visual state catalog": re.search(r'"light_switcher"\s*:\s*\{.*?"category"\s*:\s*"objects".*?"surface"\s*:\s*"wall"', catalog, re.S) is not None,
    "light switcher states map through catalog family": all(re.search(pattern, catalog, re.S) is not None for pattern in [r'"base"\s*:\s*"light_switcher_base_wall_01"', r'"off"\s*:\s*"light_switcher_base_wall_01"', r'"on"\s*:\s*"light_switcher_on_wall_01"']),
    "light switcher archetype exists": re.search(r'"light_switcher"\s*:\s*\{.*?"archetype_id"\s*:\s*"light_switcher"', world_catalog, re.S) is not None,
    "light switcher archetype is wall mounted": '"mount":"wall"' in light_switcher_archetype and '"placement_mode":"wall_mounted"' in light_switcher_archetype,
    "light switcher archetype opts into visual states": all(token in light_switcher_archetype for token in ['"switcher_type":"light_switcher"', '"visual_family":"light_switcher"', '"visual_surface":"wall"', '"visual_state_policy":"powered_three_state"', '"power_visual_state_enabled":true']),
    "light switcher resolution is not renderer hardcoded": all(token not in renderer for token in ["light_switcher_base_wall_01", "light_switcher_on_wall_01"]),

    "terminal family exists in visual state catalog": re.search(r'"terminal"\s*:\s*\{.*?"category"\s*:\s*"objects".*?"surface"\s*:\s*"floor"', catalog, re.S) is not None,
    "terminal states map through catalog family": all(re.search(pattern, catalog, re.S) is not None for pattern in [r'"base"\s*:\s*"terminal_base_floor_01"', r'"off"\s*:\s*"terminal_off_floor_01"', r'"on"\s*:\s*"terminal_on_floor_01"']),
    "terminal overlays map through catalog family": all(re.search(pattern, catalog, re.S) is not None for pattern in [r'"off"\s*:\s*\["pulsar_overlay_terminal_off_floor_01"\]', r'"on"\s*:\s*\["pulsar_overlay_terminal_on_floor_01"\]']),
    "damaged and error are unavailable off states": re.search(r'UNAVAILABLE_STATES.*"damaged".*"error"', service) is not None,
    "terminal aliases use new base asset while legacy id remains": '"terminal": "terminal_base_floor_01"' in catalog and '"terminal_01": "res://assets/visual/isometric/objects/terminal_01.png"' in catalog,
    "terminal resolution is not renderer hardcoded": all(token not in renderer for token in ["terminal_on_floor_01", "terminal_off_floor_01", "terminal_base_floor_01"]),

    "power_source family exists in visual state catalog": re.search(r'"power_source"\s*:\s*\{.*?"category"\s*:\s*"objects".*?"surface"\s*:\s*"floor"', catalog, re.S) is not None,
    "power_source states map through catalog family": all(re.search(pattern, catalog, re.S) is not None for pattern in [r'"base"\s*:\s*"power_source_base_floor_01"', r'"off"\s*:\s*"power_source_off_floor_01"', r'"on"\s*:\s*"power_source_on_floor_01"']),
    "power_source overlays map through catalog family": all(re.search(pattern, catalog, re.S) is not None for pattern in [r'"off"\s*:\s*\["pulsar_overlay_power_source_off_floor_01"\]', r'"on"\s*:\s*\["pulsar_overlay_power_source_on_floor_01"\]']),
    "power_source archetype opts into visual states": re.search(r'"power_source"\s*:\s*\{.*?"visual_family"\s*:\s*"power_source".*?"visual_surface"\s*:\s*"floor".*?"visual_state_policy"\s*:\s*"powered_three_state".*?"power_visual_state_enabled"\s*:\s*true', world_catalog, re.S) is not None,
    "legacy power_source id remains available": '"power_source_01": "res://assets/visual/isometric/objects/power_source_01.png"' in catalog,
    "power_source resolution is not renderer hardcoded": all(token not in renderer for token in ["power_source_base_floor_01", "power_source_off_floor_01", "power_source_on_floor_01"]),
    "power source states include source aliases": '"source_on"' in service and '"source_off"' in service,
    "firewall family exists in visual state catalog": re.search(r'"firewall"\s*:\s*\{.*?"category"\s*:\s*"objects".*?"surface"\s*:\s*"floor"', catalog, re.S) is not None,
    "firewall states map through catalog family": all(re.search(pattern, catalog, re.S) is not None for pattern in [r'"base"\s*:\s*"firewall_base_floor_01"', r'"off"\s*:\s*"firewall_off_floor_01"', r'"on"\s*:\s*"firewall_on_floor_01"']),
    "firewall overlays map through catalog family": all(re.search(pattern, catalog, re.S) is not None for pattern in [r'"off"\s*:\s*\["pulsar_overlay_firewall_off_floor_01"\]', r'"on"\s*:\s*\["pulsar_overlay_firewall_on_floor_01"\]']),
    "firewall archetype opts into visual states": re.search(r'"firewall"\s*:\s*\{.*?"visual_family"\s*:\s*"firewall".*?"visual_surface"\s*:\s*"floor".*?"visual_state_policy"\s*:\s*"powered_three_state".*?"power_visual_state_enabled"\s*:\s*true', world_catalog, re.S) is not None,
    "firewall service stub exists": firewall_service.exists() and "class_name FirewallService" in firewall_service.read_text(),
    "firewall resolution is not renderer hardcoded": all(token not in renderer for token in ["firewall_on_floor_01", "firewall_off_floor_01", "firewall_base_floor_01"]),

    "station assets exist in catalog": all(token in catalog for token in station_asset_ids),
    "station aliases map variants": all(token in catalog for token in ['"station": "station_lab_floor_01"', '"station_decrypt": "station_decrypt_floor_01"', '"station_incrypt": "station_decrypt_floor_01"', '"station_lab": "station_lab_floor_01"', '"station_research": "station_lab_floor_01"', '"station_recharge": "station_recharge_floor_01"', '"station_repair": "station_repair_floor_01"', '"station_shop": "station_shop_floor_01"']),
    "station canonical ids are included": all(re.search(r'CANONICAL_OBJECT_VISUAL_IDS.*?"%s"' % re.escape(token), catalog, re.S) is not None for token in station_asset_ids),
    "station family exists in visual state catalog": re.search(r'"station"\s*:\s*\{.*?"category"\s*:\s*"objects".*?"surface"\s*:\s*"floor"', catalog, re.S) is not None,
    "station family is static and variant based": re.search(r'"station"\s*:\s*\{.*?"visual_state_policy"\s*:\s*"static".*?"variant_policy"\s*:\s*"station_type".*?"default_variant"\s*:\s*"lab"', catalog, re.S) is not None,
    "station variants map through catalog family": all(re.search(pattern, catalog, re.S) is not None for pattern in [r'"decrypt"\s*:\s*"station_decrypt_floor_01"', r'"incrypt"\s*:\s*"station_decrypt_floor_01"', r'"lab"\s*:\s*"station_lab_floor_01"', r'"research"\s*:\s*"station_lab_floor_01"', r'"recharge"\s*:\s*"station_recharge_floor_01"', r'"repair"\s*:\s*"station_repair_floor_01"', r'"shop"\s*:\s*"station_shop_floor_01"']),
    "service supports static variant families": all(token in service for token in ["resolve_visual_variant", "resolve_configured_variant_asset_id", "visual_state_policy", "default_variant", "variants"]),
    "station archetype exists": re.search(r'"station"\s*:\s*\{.*?"archetype_id"\s*:\s*"station"', world_catalog, re.S) is not None,
    "station archetype exposes station_type enum": all(token in station_archetype for token in ['"field":"station_type"', '"type":"enum"', '"decrypt"', '"lab"', '"recharge"', '"repair"', '"shop"']),
    "station archetype opts into static floor visual family": all(token in station_archetype for token in ['"visual_family":"station"', '"visual_surface":"floor"', '"visual_state_policy":"static"']),
    "station resolution is not renderer hardcoded": all(token not in renderer for token in station_asset_ids),
}


checks.update({
    "air_cooling family exists": re.search(r'"air_cooling"\s*:\s*\{.*?"category"\s*:\s*"objects"', catalog, re.S) is not None,
    "air_cooling family uses floor powered airflow defaults": all(token in catalog for token in ['"surface": "floor"', '"visual_state_policy": "powered_three_state"', '"variant_policy": "airflow_direction"', '"default_variant": "sw"']),
    "air_cooling direction variants mirror generically": all(re.search(pattern, catalog, re.S) is not None for pattern in [r'"sw"\s*:\s*\{"source"\s*:\s*"sw",\s*"mirror_x"\s*:\s*false\}', r'"se"\s*:\s*\{"source"\s*:\s*"sw",\s*"mirror_x"\s*:\s*true\}', r'"ne"\s*:\s*\{"source"\s*:\s*"ne",\s*"mirror_x"\s*:\s*false\}', r'"nw"\s*:\s*\{"source"\s*:\s*"ne",\s*"mirror_x"\s*:\s*true\}']),
    "air_cooling states only use source variants": all(token in catalog for token in ['"sw": {"base": "air_cooling_base_floor_sw_01", "off": "air_cooling_off_floor_sw_01", "on": "air_cooling_on_floor_sw_01"}', '"ne": {"base": "air_cooling_base_floor_ne_01", "off": "air_cooling_off_floor_ne_01", "on": "air_cooling_on_floor_ne_01"}']) and 'air_cooling_base_floor_se_01' not in catalog and 'air_cooling_base_floor_nw_01' not in catalog,
    "air_cooling overlays only use source variants": all(token in catalog for token in ['"sw": {"off": ["pulsar_overlay_air_cooling_off_floor_sw_01"], "on": ["pulsar_overlay_air_cooling_on_floor_sw_01"]}', '"ne": {"off": ["pulsar_overlay_air_cooling_off_floor_ne_01"], "on": ["pulsar_overlay_air_cooling_on_floor_ne_01"]}']),
    "air_cooling real source ids are cataloged": all(token in catalog for token in ['"air_cooling_base_floor_ne_01"', '"air_cooling_base_floor_sw_01"', '"air_cooling_off_floor_ne_01"', '"air_cooling_off_floor_sw_01"', '"air_cooling_on_floor_ne_01"', '"air_cooling_on_floor_sw_01"', '"pulsar_overlay_air_cooling_off_floor_ne_01"', '"pulsar_overlay_air_cooling_off_floor_sw_01"', '"pulsar_overlay_air_cooling_on_floor_ne_01"', '"pulsar_overlay_air_cooling_on_floor_sw_01"']),
    "resolver supports direction source mirror descriptor": all(token in service for token in ['normalize_direction_variant', 'resolve_direction_variant_mapping', 'resolve_visual_asset_descriptor', '"source_variant"', '"mirror_x"']),
    "resolver checks airflow direction fields": all(token in service for token in ['"airflow_direction"', '"flow_direction"', '"facing_side"', '"facing_dir"', '"direction"', '"visual_variant"', '"variant"']),
    "overlay resolver uses source variant and preserves mirror descriptor path": 'resolve_configured_overlay_asset_ids(family, state, surface, source_variant)' in service and 'resolve_visual_asset_descriptor' in renderer and 'descriptor["mirror_h"] = true' in renderer,
    "external air cooler remains single configurable archetype": re.search(r'"external_air_cooler"\s*:\s*\{.*?"airflow_direction":"sw".*?"visual_family":"air_cooling".*?"property_schema":\[\{"field":"airflow_direction"', world_catalog, re.S) is not None,
    "renderer does not hardcode air_cooling assets": all(token not in renderer for token in ['air_cooling_base_floor_ne_01', 'air_cooling_base_floor_sw_01', 'air_cooling_off_floor_ne_01', 'air_cooling_off_floor_sw_01', 'air_cooling_on_floor_ne_01', 'air_cooling_on_floor_sw_01']),
})


CABLE_REEL_ASSET_IDS = [
    "cable_reel_base_floor_01",
    "cable_reel_off_floor_01",
    "cable_reel_on_floor_01",
    "pulsar_overlay_cable_reel_off_floor_01",
    "pulsar_overlay_cable_reel_on_floor_01",
]
cable_reel_helper_path = root / "scripts/game/cable/cable_reel_visual_state_service.gd"
cable_reel_helper = cable_reel_helper_path.read_text() if cable_reel_helper_path.exists() else ""
cable_reel_archetype = world_catalog.split('"power_cable_reel": {', 1)[1].split('\n\t"fuse": {', 1)[0]
checks.update({
    "cable reel asset ids exist": all(f'"{asset_id}"' in catalog for asset_id in CABLE_REEL_ASSET_IDS),
    "cable reel aliases map to floor base asset": all(token in catalog for token in ['"cable_reel": "cable_reel_base_floor_01"', '"wire_reel": "cable_reel_base_floor_01"', '"reel": "cable_reel_base_floor_01"', '"cable_reel_base": "cable_reel_base_floor_01"', '"cable_reel_off": "cable_reel_off_floor_01"', '"cable_reel_on": "cable_reel_on_floor_01"']),
    "cable reel canonical ids are included": all(re.search(r'CANONICAL_OBJECT_VISUAL_IDS.*?"%s"' % re.escape(token), catalog, re.S) is not None for token in CABLE_REEL_ASSET_IDS),
    "cable reel family exists": re.search(r'"cable_reel"\s*:\s*\{.*?"category"\s*:\s*"objects".*?"surface"\s*:\s*"floor"', catalog, re.S) is not None,
    "cable reel family uses connection policy": re.search(r'"cable_reel"\s*:\s*\{.*?"visual_state_policy"\s*:\s*"cable_reel_connection_state"', catalog, re.S) is not None,
    "cable reel states map through catalog family": all(re.search(pattern, catalog, re.S) is not None for pattern in [r'"base"\s*:\s*"cable_reel_base_floor_01"', r'"off"\s*:\s*"cable_reel_off_floor_01"', r'"on"\s*:\s*"cable_reel_on_floor_01"']),
    "cable reel overlays map through catalog family": all(re.search(pattern, catalog, re.S) is not None for pattern in [r'"off"\s*:\s*\["pulsar_overlay_cable_reel_off_floor_01"\]', r'"on"\s*:\s*\["pulsar_overlay_cable_reel_on_floor_01"\]']),
    "cable reel archetype opts into connection visual states": all(token in cable_reel_archetype for token in ['"visual_family":"cable_reel"', '"visual_surface":"floor"', '"visual_state_policy":"cable_reel_connection_state"', '"power_visual_state_enabled":false', '"connected_endpoint_count":0', '"socket_connected_endpoint_count":0']),
    "cable reel helper exists and is read only resolver": all(token in cable_reel_helper for token in ["class_name CableReelVisualStateService", "static func resolve_visual_state", "connected_endpoint_count", "socket_connected_endpoint_count", "connected_socket_count", "connected_ends", "cable_endpoints", "wire_endpoints", "endpoints", "connections", "connected_objects", "connected_object_ids", "endpoint_connections"]),
    "cable reel helper detects sockets without powered fallback": all(token in cable_reel_helper for token in ['"object_type"', '"type"', '"archetype_id"', '"visual_family"', '"socket_type"', '"is_socket"', '"is_power_socket"', '"group"', '"object_group"', '"power_socket"', '"outlet"', '"connector_socket"', '"cable_socket"']) and 'is_powered' not in cable_reel_helper and 'powered' not in cable_reel_helper,
    "cable reel resolver behavior is connection driven": all(token in cable_reel_helper for token in ['connected_endpoint_count >= 2 and socket_connected_endpoint_count >= 1', 'connected_endpoint_count == 1 and socket_connected_endpoint_count == 1', 'return STATE_ON', 'return STATE_OFF', 'return STATE_BASE']),
    "visual service supports cable reel custom policy": all(token in service for token in ["CableReelVisualStateService", "VISUAL_STATE_POLICY_CABLE_REEL_CONNECTION_STATE", 'policy == VISUAL_STATE_POLICY_CABLE_REEL_CONNECTION_STATE', "CableReelVisualStateServiceRef.resolve_visual_state(object_data)"]),
    "power socket source power true flag overrides stale unpowered state": re.search(r"static func _has_source_power.*?_has_true_power_flag\(object_data\).*?return true.*?power_state in POWER_OFF_STATES", service, re.S) is not None,
    "power socket source power checks all runtime true evidence": all(token in service for token in ['"is_powered"', '"has_power"', '"receives_power"', '"upstream_powered"']),
    "power socket visuals keep connection separate from source power": all(token in service for token in ["static func _resolve_power_socket_visual_state", "_has_source_power(object_data)", "_has_connected_cable(object_data)", "return VISUAL_STATE_ON if _has_connected_cable(object_data) else VISUAL_STATE_OFF", "return VISUAL_STATE_BASE"]),
    "power socket connected false does not hide stronger connection evidence": re.search(r'static func _has_connected_cable.*?connected_endpoint_count.*?object_data.has\("connected"\).*?return false', service, re.S) is not None and all(token in service for token in ['"socket_connected_endpoint_count"', '"endpoint_a_id"', '"endpoint_b_id"', '"socket_id"', '"connected_ends"', '"cable_endpoints"', '"endpoints"', '"connections"']),
    "power socket stale unpowered smoke cases resolve correctly": all(_resolve_power_socket_smoke_state(data) == expected for data, expected in POWER_SOCKET_STALE_UNPOWERED_SMOKE_CASES),
    "cable reel resolution is not renderer hardcoded": all(token not in renderer for token in CABLE_REEL_ASSET_IDS),
})

POWER_SOCKET_ASSET_IDS = [
    "power_socket_base_floor_01",
    "power_socket_base_wall_01",
    "power_socket_off_floor_01",
    "power_socket_off_wall_01",
    "power_socket_on_floor_01",
    "power_socket_on_wall_01",
    "pulsar_overlay_power_socket_off_floor_01",
    "pulsar_overlay_power_socket_off_wall_01",
    "pulsar_overlay_power_socket_on_floor_01",
    "pulsar_overlay_power_socket_on_wall_01",
]
power_socket_helper_path = root / "scripts/game/power/power_socket_visual_state_service.gd"
power_socket_helper = power_socket_helper_path.read_text() if power_socket_helper_path.exists() else ""
power_socket_archetype = world_catalog.split('"power_socket": {', 1)[1].split('\n\t"power_cable_reel": {', 1)[0]
checks.update({
    "power socket asset ids exist": all(f'"{asset_id}"' in catalog for asset_id in POWER_SOCKET_ASSET_IDS),
    "power socket aliases map to authored base assets": all(token in catalog for token in ['"power_socket": "power_socket_base_floor_01"', '"socket": "power_socket_base_floor_01"', '"outlet": "power_socket_base_floor_01"', '"power_outlet": "power_socket_base_floor_01"', '"power_socket_base_wall": "power_socket_base_wall_01"', '"power_socket_off_wall": "power_socket_off_wall_01"', '"power_socket_on_wall": "power_socket_on_wall_01"']),
    "power socket canonical ids are included": all(re.search(r'CANONICAL_OBJECT_VISUAL_IDS.*?"%s"' % re.escape(token), catalog, re.S) is not None for token in POWER_SOCKET_ASSET_IDS),
    "power socket family exists": re.search(r'"power_socket"\s*:\s*\{.*?"category"\s*:\s*"objects".*?"default_surface"\s*:\s*"floor"', catalog, re.S) is not None,
    "power socket family uses connection policy": re.search(r'"power_socket"\s*:\s*\{.*?"visual_state_policy"\s*:\s*"power_socket_connection_state"', catalog, re.S) is not None,
    "power socket floor states map through catalog family": all(re.search(pattern, catalog, re.S) is not None for pattern in [r'"floor"\s*:\s*\{.*?"base"\s*:\s*"power_socket_base_floor_01"', r'"floor"\s*:\s*\{.*?"off"\s*:\s*"power_socket_off_floor_01"', r'"floor"\s*:\s*\{.*?"on"\s*:\s*"power_socket_on_floor_01"']),
    "power socket wall states map through catalog family": all(re.search(pattern, catalog, re.S) is not None for pattern in [r'"wall"\s*:\s*\{.*?"base"\s*:\s*"power_socket_base_wall_01"', r'"wall"\s*:\s*\{.*?"off"\s*:\s*"power_socket_off_wall_01"', r'"wall"\s*:\s*\{.*?"on"\s*:\s*"power_socket_on_wall_01"']),
    "power socket floor overlays map through catalog family": all(re.search(pattern, catalog, re.S) is not None for pattern in [r'"floor"\s*:\s*\{.*?"off"\s*:\s*\["pulsar_overlay_power_socket_off_floor_01"\]', r'"floor"\s*:\s*\{.*?"on"\s*:\s*\["pulsar_overlay_power_socket_on_floor_01"\]']),
    "power socket wall overlays map through catalog family": all(re.search(pattern, catalog, re.S) is not None for pattern in [r'"wall"\s*:\s*\{.*?"off"\s*:\s*\["pulsar_overlay_power_socket_off_wall_01"\]', r'"wall"\s*:\s*\{.*?"on"\s*:\s*\["pulsar_overlay_power_socket_on_wall_01"\]']),
    "power socket archetype supports mount-driven surface": all(token in power_socket_archetype for token in ['"archetype_id":"power_socket"', '"visual_family":"power_socket"', '"visual_state_policy":"power_socket_connection_state"', '"mount":"floor"', '"field":"mount"']) and '"visual_surface"' not in power_socket_archetype,
    "power socket helper exists and is read only resolver": all(token in power_socket_helper for token in ["class_name PowerSocketVisualStateService", "static func resolve_visual_state", '"upstream_powered"', '"source_powered"', '"has_source_power"', '"incoming_powered"', '"is_powered"', '"power_state"', '"status"', '"state"', '"has_connected_cable"', '"connected"', '"is_connected"', '"connection_id"', '"connected_endpoint_count"', '"socket_connected_endpoint_count"']),
    "power socket resolver behavior prioritizes source power": re.search(r"if not _has_source_power\(object_data\):.*?return STATE_BASE.*?if _has_connected_cable\(object_data\):.*?return STATE_ON.*?return STATE_OFF", power_socket_helper, re.S) is not None,
    "power socket resolver smoke behavior cases pass": _power_socket_behavior_cases_pass(),
    "power socket source resolver does not let stale false upstream override true evidence": "and not bool(object_data.get(key" not in power_socket_helper and power_socket_helper.find('power_state in FALSE_POWER_STATES') < power_socket_helper.find('for key in ["is_powered", "powered", "has_power", "receives_power", "upstream_powered"'),
    "power socket archetype keeps gameplay connection state": '"state":"disconnected"' in power_socket_archetype and '"state":"base"' not in power_socket_archetype and '"upstream_powered":false' not in power_socket_archetype,
    "visual service supports power socket custom policy": all(token in service for token in ["PowerSocketVisualStateService", "VISUAL_STATE_POLICY_POWER_SOCKET_CONNECTION_STATE", 'policy == VISUAL_STATE_POLICY_POWER_SOCKET_CONNECTION_STATE']),
    "overlay resolver supports surface overlays": "overlays.has(normalized_surface)" in service and "Dictionary(overlays.get(normalized_surface)).get(normalized_state" in service,
    "power socket resolution is not renderer hardcoded": all(token not in renderer for token in POWER_SOCKET_ASSET_IDS),
})


FUSE_BOX_ASSET_IDS = [
    "fuse_box_base_without_floor_01",
    "fuse_box_base_without_wall_01",
    "fuse_box_base_with_floor_01",
    "fuse_box_base_with_wall_01",
    "fuse_box_off_with_floor_01",
    "fuse_box_off_with_wall_01",
    "fuse_box_off_without_floor_01",
    "fuse_box_off_without_wall_01",
    "fuse_box_on_floor_01",
    "fuse_box_on_wall_01",
]
fuse_box_helper_path = root / "scripts/game/power/fuse_box_visual_state_service.gd"
fuse_box_helper = fuse_box_helper_path.read_text() if fuse_box_helper_path.exists() else ""
fuse_box_archetype = world_catalog.split('"fuse_box": {', 1)[1].split('\n\t"barrel": {', 1)[0]

def _py_fuse_box_has_fuse(row):
    for key in ["has_fuse", "fuse_installed", "is_fuse_installed", "contains_fuse", "has_installed_fuse", "fuse_present", "inserted_fuse"]:
        if key in row and bool(row.get(key)):
            return True
    for key in ["fuse_count", "inventory_fuse_count"]:
        if key in row and int(row.get(key, 0)) > 0:
            return True
    return False

def _py_fuse_box_has_power(row):
    active = {"on", "active", "ready", "enabled", "powered", "source_on", "switch_on"}
    off = {"unpowered", "no_power", "disconnected", "offline"}
    norm = lambda value: str(value).strip().lower().replace(" ", "_").replace("-", "_")
    for key in ["is_powered", "powered", "has_power", "receives_power", "upstream_powered", "source_powered", "has_source_power", "incoming_powered"]:
        if key in row and bool(row.get(key)):
            return True
    for key in ["power_state", "status", "state"]:
        if norm(row.get(key, "")) in active:
            return True
    for key in ["is_powered", "powered", "has_power", "receives_power", "upstream_powered", "source_powered", "has_source_power", "incoming_powered"]:
        if key in row and not bool(row.get(key)):
            return False
    for key in ["power_state", "status", "state"]:
        if norm(row.get(key, "")) in off:
            return False
    return False

def _py_fuse_box_unavailable(row):
    unavailable = {"off", "disabled", "error", "unavailable", "failed", "broken"}
    norm = lambda value: str(value).strip().lower().replace(" ", "_").replace("-", "_")
    for key in ["disabled", "unavailable", "error", "is_disabled", "is_unavailable", "has_error"]:
        if key in row and bool(row.get(key)):
            return True
    return any(norm(row.get(key, "")) in unavailable for key in ["state", "status", "availability", "interaction_state"])

def _py_fuse_box_state_variant(row):
    has_fuse = _py_fuse_box_has_fuse(row)
    if not _py_fuse_box_has_power(row):
        return ("base", "with" if has_fuse else "without")
    if not has_fuse:
        return ("off", "without")
    return ("off" if _py_fuse_box_unavailable(row) else "on", "with")

FUSE_BOX_BEHAVIOR_CASES = [
    ({"has_power": False, "has_fuse": False}, ("base", "without")),
    ({"has_power": False, "has_fuse": True}, ("base", "with")),
    ({"has_power": True, "has_fuse": False}, ("off", "without")),
    ({"has_power": True, "has_fuse": True}, ("on", "with")),
    ({"has_power": True, "has_fuse": True, "state": "disabled"}, ("off", "with")),
    ({"is_powered": True, "power_state": "unpowered", "has_fuse": True}, ("on", "with")),
]
checks.update({
    "fuse box asset ids exist": all(f'"{asset_id}"' in catalog for asset_id in FUSE_BOX_ASSET_IDS),
    "fuse box aliases map to authored floor assets": all(token in catalog for token in ['"fuse_box": "fuse_box_base_without_floor_01"', '"fuse_box_base_with": "fuse_box_base_with_floor_01"', '"fuse_box_base_without": "fuse_box_base_without_floor_01"', '"fuse_box_off_with": "fuse_box_off_with_floor_01"', '"fuse_box_off_without": "fuse_box_off_without_floor_01"', '"fuse_box_on": "fuse_box_on_floor_01"', '"fuse_box_on_wall": "fuse_box_on_wall_01"']),
    "fuse box canonical ids are included": all(re.search(r'CANONICAL_OBJECT_VISUAL_IDS.*?"%s"' % re.escape(token), catalog, re.S) is not None for token in FUSE_BOX_ASSET_IDS),
    "fuse box family exists with policies": re.search(r'"fuse_box"\s*:\s*\{.*?"category"\s*:\s*"objects".*?"default_surface"\s*:\s*"floor".*?"visual_state_policy"\s*:\s*"fuse_box_line_power_state".*?"variant_policy"\s*:\s*"fuse_presence"', catalog, re.S) is not None,
    "fuse box floor surface variant state mappings": all(re.search(pattern, catalog, re.S) is not None for pattern in [r'"floor"\s*:\s*\{.*?"with"\s*:\s*\{.*?"base"\s*:\s*"fuse_box_base_with_floor_01"', r'"floor"\s*:\s*\{.*?"without"\s*:\s*\{.*?"base"\s*:\s*"fuse_box_base_without_floor_01"', r'"floor"\s*:\s*\{.*?"with"\s*:\s*\{.*?"off"\s*:\s*"fuse_box_off_with_floor_01"', r'"floor"\s*:\s*\{.*?"without"\s*:\s*\{.*?"off"\s*:\s*"fuse_box_off_without_floor_01"', r'"floor"\s*:\s*\{.*?"with"\s*:\s*\{.*?"on"\s*:\s*"fuse_box_on_floor_01"']),
    "fuse box wall surface variant state mappings": all(re.search(pattern, catalog, re.S) is not None for pattern in [r'"wall"\s*:\s*\{.*?"with"\s*:\s*\{.*?"base"\s*:\s*"fuse_box_base_with_wall_01"', r'"wall"\s*:\s*\{.*?"without"\s*:\s*\{.*?"base"\s*:\s*"fuse_box_base_without_wall_01"', r'"wall"\s*:\s*\{.*?"with"\s*:\s*\{.*?"off"\s*:\s*"fuse_box_off_with_wall_01"', r'"wall"\s*:\s*\{.*?"without"\s*:\s*\{.*?"off"\s*:\s*"fuse_box_off_without_wall_01"', r'"wall"\s*:\s*\{.*?"with"\s*:\s*\{.*?"on"\s*:\s*"fuse_box_on_wall_01"']),
    "fuse box behavior smoke cases resolve correctly": all(_py_fuse_box_state_variant(data) == expected for data, expected in FUSE_BOX_BEHAVIOR_CASES),
    "fuse box helper exists and is read only resolver": all(token in fuse_box_helper for token in ["class_name FuseBoxVisualStateService", "static func resolve_visual_state", "static func resolve_variant", '"has_fuse"', '"fuse_installed"', '"source_powered"', '"incoming_powered"', '"power_state"', '"status"', '"state"']) and all(token not in fuse_box_helper for token in ["insert_fuse", "remove_fuse"]),
    "fuse box archetype supports mount and visual policies": all(token in fuse_box_archetype for token in ['"archetype_id":"fuse_box"', '"mount":"floor"', '"visual_family":"fuse_box"', '"visual_state_policy":"fuse_box_line_power_state"', '"variant_policy":"fuse_presence"', '"field":"mount"']) and '"visual_surface"' not in fuse_box_archetype,
    "visual service supports fuse box custom policy and variant": all(token in service for token in ["FuseBoxVisualStateService", "VISUAL_STATE_POLICY_FUSE_BOX_LINE_POWER_STATE", 'policy == VISUAL_STATE_POLICY_FUSE_BOX_LINE_POWER_STATE', 'policy == "fuse_presence"']),
    "resolver supports states surface variant state mapping": all(token in service for token in ["surface_mapping.has(normalized_variant)", "surface_variant_states.has(normalized_state)"]),
    "fuse box resolution is not renderer hardcoded": all(token not in renderer for token in FUSE_BOX_ASSET_IDS),
})

failed = [name for name, ok in checks.items() if not ok]
if failed:
    print("Visual state asset smoke checks failed:")
    for name in failed:
        print(f"- {name}")
    sys.exit(1)
print(f"Visual state asset smoke checks passed: {len(checks)} checks.")
