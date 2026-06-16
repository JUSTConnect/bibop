#!/usr/bin/env python3
"""Smoke checks for the generic powered visual state asset resolver."""
from pathlib import Path
import re
import sys

root = Path(__file__).resolve().parents[1]
service = (root / "scripts/visual/visual_state_asset_service.gd").read_text()
renderer = (root / "scripts/field/room_visual_renderer.gd").read_text()
catalog = (root / "scripts/visual/visual_asset_catalog.gd").read_text()
world_catalog = (root / "scripts/world/world_object_catalog.gd").read_text()
power_switcher_archetype = world_catalog.split('"power_switcher": {', 1)[1].split('\n\t"light_switcher": {', 1)[0]
light_switcher_archetype = world_catalog.split('"light_switcher": {', 1)[1].split('\n\t"fuse_box": {', 1)[0]
firewall_service = root / "scripts/game/firewall/firewall_service.gd"
station_archetype = world_catalog.split('"station": {', 1)[1].split('\n\t"firewall": {', 1)[0]
station_asset_ids = ["station_decrypt_floor_01", "station_lab_floor_01", "station_recharge_floor_01", "station_repair_floor_01", "station_shop_floor_01"]

DOOR_ASSET_IDS = [
    "door_close_base_floor_01",
    "door_close_off_floor_01",
    "door_close_on_floor_01",
    "door_open_base_floor_01",
    "door_open_off_floor_01",
    "door_open_on_floor_01",
]
door_archetype = world_catalog.split('"door": {', 1)[1].split('\n\t"platform": {', 1)[0]

checks = {

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

failed = [name for name, ok in checks.items() if not ok]
if failed:
    print("Visual state asset smoke checks failed:")
    for name in failed:
        print(f"- {name}")
    sys.exit(1)
print(f"Visual state asset smoke checks passed: {len(checks)} checks.")
