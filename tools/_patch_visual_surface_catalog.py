from pathlib import Path
p=Path(__file__).resolve().parents[1] / 'scripts/visual/visual_asset_catalog.gd'
s=p.read_text()
insert='''

# Renderer-only presentation metadata for domain surface materials.
# Canonical material ids and compatibility rules live in SurfaceMaterialCatalog.
const FLOOR_MATERIAL_PRESENTATION: Dictionary = {
    "concrete": {"texture_asset_id":"floor_concrete", "fallback_color":Color(0.16, 0.16, 0.15, 0.97), "edge_color":Color(0.30, 0.30, 0.28, 0.95)},
    "steel": {"texture_asset_id":"floor_steel", "fallback_color":Color(0.13, 0.17, 0.2, 0.97), "edge_color":Color(0.22, 0.28, 0.33, 0.95)},
    "titan": {"texture_asset_id":"floor_titan", "fallback_color":Color(0.15, 0.18, 0.22, 0.97), "edge_color":Color(0.31, 0.36, 0.42, 0.95)}
}

const WALL_MATERIAL_PRESENTATION: Dictionary = {
    "concrete": {"texture_asset_id":"wall_concrete", "fallback_color":Color(0.66, 0.72, 0.76, 0.98), "edge_color":Color(0.86, 0.9, 0.94, 1.0)},
    "concrete_damage": {"texture_asset_id":"wall_concrete", "fallback_color":Color(0.48, 0.31, 0.16, 0.98), "edge_color":Color(0.96, 0.57, 0.21, 1.0)},
    "brick": {"texture_asset_id":"wall_brick", "fallback_color":Color(0.37, 0.21, 0.16, 0.98), "edge_color":Color(0.82, 0.72, 0.58, 1.0)},
    "breachable_concrete": {"texture_asset_id":"wall_concrete", "fallback_color":Color(0.62, 0.67, 0.7, 0.98), "edge_color":Color(1.0, 0.82, 0.32, 1.0)},
    "breachable_brick": {"texture_asset_id":"wall_brick", "fallback_color":Color(0.44, 0.23, 0.17, 0.98), "edge_color":Color(1.0, 0.76, 0.28, 1.0)},
    "brick_damage": {"texture_asset_id":"wall_brick", "fallback_color":Color(0.42, 0.19, 0.2, 0.98), "edge_color":Color(0.84, 0.34, 0.37, 1.0)},
    "grate": {"texture_asset_id":"wall_grate", "fallback_color":Color(0.18, 0.2, 0.24, 0.98), "edge_color":Color(0.32, 0.36, 0.41, 1.0)},
    "steel": {"texture_asset_id":"wall_steel", "fallback_color":Color(0.24, 0.27, 0.33, 0.98), "edge_color":Color(0.55, 0.61, 0.72, 1.0)},
    "reinforced_steel": {"texture_asset_id":"wall_reinforced_steel", "fallback_color":Color(0.28, 0.3, 0.21, 0.98), "edge_color":Color(0.71, 0.81, 0.34, 1.0)},
    "titan": {"texture_asset_id":"wall_titan", "fallback_color":Color(0.22, 0.24, 0.31, 0.98), "edge_color":Color(0.58, 0.65, 0.78, 1.0)},
    "outerwall": {"texture_asset_id":"wall_outer", "fallback_color":Color(0.19, 0.2, 0.22, 0.98), "edge_color":Color(0.62, 0.67, 0.75, 1.0)}
}

const LEGACY_MISSION_OBJECT_ASSET_ALIASES: Dictionary = {
    "door_state_generic":"object_door", "terminal_state_generic":"object_terminal", "item_generic_marker":"object_generic",
    "cable_reel":"cable_reel_01", "cable_reel_01":"cable_reel_01", "power_cable_reel":"cable_reel_01",
    "fuse_box":"fuse_box_out_01", "fuse_box_empty":"fuse_box_out_01", "fuse_box_installed":"fuse_box_in_01",
    "fuse_box_in_01":"fuse_box_in_01", "fuse_box_out_01":"fuse_box_out_01", "fuse_box_in_wall_01":"fuse_box_in_wall_01", "fuse_box_out_wall_01":"fuse_box_out_wall_01", "wall_fuse_box":"fuse_box_out_wall_01",
    "power_source":"power_source_01", "power_source_class_1":"power_source_01", "power_source_class_2":"power_source_01", "power_source_class_3":"power_source_01",
    "switcher":"power_switcher_off_01", "power_switcher":"power_switcher_off_01", "radiator":"radiator_floor_01", "external_radiator":"radiator_floor_01", "terminal":"terminal_01",
    "normal_barrel":"normal_barrel_floor_01", "barrel":"normal_barrel_floor_01", "fire_barrel":"fire_barrel_floor_01", "flammable_barrel":"fire_barrel_floor_01",
    "normal_crate":"normal_crate_floor_01", "crate":"normal_crate_floor_01", "heavy_crate":"heavy_crate_floor_01", "case":"case_01", "steel_box":"steel_box_01", "light":"light_off_wall_01"
}

const LEGACY_MISSION_VISUAL_TEXTURE_ALIASES: Dictionary = {
    "default_floor":"floor_concrete", "floor_default":"floor_concrete", "concrete_floor":"floor_concrete", "steel_floor":"floor_steel", "titan_floor":"floor_titan", "titanium_floor":"floor_titan",
    "clean_lab_floor":"floor_steel", "dark_service_floor":"floor_concrete", "hazard_floor":"floor_concrete", "power_floor":"floor_steel", "damaged_floor":"floor_concrete", "reinforced_floor":"floor_steel", "diagnostic_floor":"floor_steel",
    "default_wall":"wall_default", "wall_default_metal":"wall_concrete", "wall_clean_lab":"wall_concrete", "wall_dark_service":"wall_grate", "wall_orange_hazard":"wall_concrete_damaged", "wall_damaged_red":"wall_brick_damaged",
    "wall_reinforced":"wall_steel", "wall_power_room":"wall_reinforced_steel", "wall_diagnostic_blue":"wall_brick", "wall_concrete_default":"wall_concrete", "wall_industrial_panel":"wall_brick", "wall_service_vent":"wall_grate", "wall_boundary":"wall_outer",
    "door_state_generic":"object_door", "terminal_state_generic":"object_terminal", "item_generic_marker":"object_generic", "radiator":"radiator_floor_01", "external_radiator":"radiator_floor_01",
    "normal_barrel":"normal_barrel_floor_01", "barrel":"normal_barrel_floor_01", "fire_barrel":"fire_barrel_floor_01", "flammable_barrel":"fire_barrel_floor_01", "normal_crate":"normal_crate_floor_01", "crate":"normal_crate_floor_01", "heavy_crate":"heavy_crate_floor_01"
}
'''
marker='\n# Visual state families are the primary resolver contract for powered object art.'
assert marker in s
s=s.replace(marker,insert+marker,1)
method_marker='static func get_canonical_object_visual_ids() -> Array[String]:\n'
methods='''static func get_floor_material_presentation(canonical_material_id: String) -> Dictionary:
    return Dictionary(FLOOR_MATERIAL_PRESENTATION.get(canonical_material_id, FLOOR_MATERIAL_PRESENTATION.get("concrete", {}))).duplicate(true)

static func get_wall_material_presentation(canonical_material_id: String) -> Dictionary:
    return Dictionary(WALL_MATERIAL_PRESENTATION.get(canonical_material_id, WALL_MATERIAL_PRESENTATION.get("concrete", {}))).duplicate(true)

static func decorate_surface_material_catalog(catalog: Dictionary, context: String) -> Dictionary:
    var result := catalog.duplicate(true)
    var decorated: Array[Dictionary] = []
    for row_variant in Array(catalog.get("materials", [])):
        var row := Dictionary(row_variant).duplicate(true)
        var canonical_id := str(row.get("material", row.get("id", ""))) if context == "floor" else str(row.get("id", ""))
        var presentation := get_floor_material_presentation(canonical_id) if context == "floor" else get_wall_material_presentation(canonical_id)
        row.merge(presentation, true)
        decorated.append(row)
    result["materials"] = decorated
    return result

static func get_legacy_mission_visual_texture_aliases() -> Dictionary:
    return LEGACY_MISSION_VISUAL_TEXTURE_ALIASES.duplicate(true)

static func resolve_legacy_mission_asset_id(raw_id: String, context: String = "") -> String:
    var original := raw_id.strip_edges()
    if original.is_empty():
        return ""
    var normalized := normalize_asset_id(original)
    var normalized_context := context.strip_edges().to_lower()
    if normalized_context in ["object", "door", "terminal", "item"] and LEGACY_MISSION_OBJECT_ASSET_ALIASES.has(normalized):
        return str(LEGACY_MISSION_OBJECT_ASSET_ALIASES[normalized])
    if normalized_context == "floor":
        return resolve_floor_asset_id(normalized)
    if normalized_context == "wall":
        return resolve_wall_asset_id(normalized)
    if normalized_context in ["object", "door", "terminal", "item"]:
        return resolve_object_asset_id(normalized)
    if LEGACY_MISSION_VISUAL_TEXTURE_ALIASES.has(normalized):
        return str(LEGACY_MISSION_VISUAL_TEXTURE_ALIASES[normalized])
    if LEGACY_MISSION_OBJECT_ASSET_ALIASES.has(normalized):
        return str(LEGACY_MISSION_OBJECT_ASSET_ALIASES[normalized])
    if FLOOR_ASSET_ALIASES.has(normalized):
        return str(FLOOR_ASSET_ALIASES[normalized])
    if WALL_ASSET_ALIASES.has(normalized):
        return str(WALL_ASSET_ALIASES[normalized])
    if OBJECT_ASSET_ALIASES.has(normalized):
        return str(OBJECT_ASSET_ALIASES[normalized])
    if ASSET_PATHS.has(normalized):
        return normalized
    return original

static func resolve_wall_material_base_asset_key(material_or_asset_id: String) -> String:
    var normalized := normalize_asset_id(material_or_asset_id)
    match normalized:
        "", "wall", "default", "wall_default", "concrete", "concrete_wall", "wall_concrete", "breachable_concrete", "wall_breachable_concrete", "damaged", "damaged_wall", "wall_damaged", "concrete_damaged", "concrete_damage", "damaged_concrete", "concrete_damaged_wall", "wall_concrete_damaged":
            return "wall_concrete"
        "outer", "outerwall", "outer_wall", "wall_outer", "wall_outerwall":
            return "wall_outer"
        "brick", "brick_wall", "wall_brick", "breachable_brick", "wall_breachable_brick", "brick_damaged", "damaged_brick", "brick_damage", "brick_damaged_wall", "wall_brick_damaged":
            return "wall_brick"
        "grate", "grate_wall", "wall_grate":
            return "wall_grate"
        "steel", "steel_wall", "wall_steel":
            return "wall_steel"
        "reinforced", "reinforced_steel", "reinforce_steel", "reinforcesteel", "reinforced_steel_wall", "wall_reinforced", "wall_reinforced_steel", "wall_reinforce_steel", "wall_reinforcesteel":
            return "wall_reinforced_steel"
        "titan", "titanium", "titan_wall", "titanium_wall", "wall_titan", "wall_titanium":
            return "wall_titan"
        "energy", "energy_flow", "energy_wall", "wall_energy":
            return "wall_steel"
    return "wall_concrete"

static func normalize_wall_height_for_asset_base(base_key: String, height_level: String) -> String:
    var normalized := height_level
    if normalized.is_empty():
        normalized = "mid"
    if base_key == "wall_grate" and normalized not in ["mid", "halfmid", "tall"]:
        return "mid"
    return normalized

static func resolve_wall_asset_key_for_material_and_height(material_or_asset_id: String, height_level: String) -> String:
    var base_key := resolve_wall_material_base_asset_key(material_or_asset_id)
    var normalized_height := normalize_wall_height_for_asset_base(base_key, height_level)
    var candidate := "%s_%s" % [base_key, normalized_height]
    if ASSET_PATHS.has(candidate):
        return candidate
    if base_key == "wall_grate":
        return "wall_grate_mid"
    return "wall_concrete_mid"

'''
assert method_marker in s
s=s.replace(method_marker,methods+method_marker,1)
p.write_text(s)
print('patched visual',len(s.splitlines()))
