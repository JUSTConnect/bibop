extends Node2D
class_name RoomVisualRenderer

const BreachableWallServiceRef = preload("res://scripts/game/wall/breachable_wall_service.gd")
const BreachableWallRulesServiceRef = preload("res://scripts/game/wall/breachable_wall_rules_service.gd")
const WallMountedPlacementRulesServiceRef = preload("res://scripts/game/wall/wall_mounted_placement_rules_service.gd")
const WallRoutingValidationServiceRef = preload("res://scripts/game/routing/wall_routing_validation_service.gd")

const CableTopologyServiceRef = preload("res://scripts/game/cable_topology_service.gd")
const PlatformTypesRef = preload("res://scripts/game/platform/platform_types.gd")
const PlatformVisualServiceRef = preload("res://scripts/game/platform/platform_visual_service.gd")
const ObjectFacingServiceRef = preload("res://scripts/game/object/object_facing_service.gd")
const VisualAssetCatalogScript = preload("res://scripts/visual/visual_asset_catalog.gd")
const IsoProjectionServiceRef = preload("res://scripts/visual/renderer/iso_projection_service.gd")
const IsoDrawEntryContractRef = preload("res://scripts/visual/renderer/iso_draw_entry_contract.gd")
const FloorRendererRef = preload("res://scripts/visual/renderer/floor_renderer.gd")
const WallRendererRef = preload("res://scripts/visual/renderer/wall_renderer.gd")
const ObjectRendererRef = preload("res://scripts/visual/renderer/object_renderer.gd")
const RouteRendererRef = preload("res://scripts/visual/renderer/route_renderer.gd")
const OverlayRendererRef = preload("res://scripts/visual/renderer/overlay_renderer.gd")
const MapConstructorOverlayRendererRef = preload("res://scripts/visual/renderer/map_constructor_overlay_renderer.gd")
const RuntimeDebugOverlayRendererRef = preload("res://scripts/visual/renderer/runtime_debug_overlay_renderer.gd")
const FogRendererRef = preload("res://scripts/visual/renderer/fog_renderer.gd")
const SurfaceMaterialCatalogRef = preload("res://scripts/world/surface_material_catalog.gd")
const WallHeightCatalogRef = preload("res://scripts/world/wall_height_catalog.gd")
const LightVisualServiceRef = preload("res://scripts/visual/light_visual_service.gd")
const VisualStateAssetServiceRef = preload("res://scripts/visual/visual_state_asset_service.gd")
const VisualAssetRenderContractServiceRef = preload("res://scripts/visual/visual_asset_render_contract_service.gd")
const WorldObjectCatalogRef = preload("res://scripts/world/world_object_catalog.gd")

# GridManager remains the gameplay grid source.
# RoomVisualRenderer is a future visual projection layer.
# Gameplay cells remain Vector2i in GridManager logic.
# The helpers in this script are visual projection helpers only.
# Future PRs will use them for floor, wall, object, fog, and overlay rendering.
@export var authored_wall_canvas_source_width: float = 512.0
@export var authored_wall_canvas_anchor_ratio: Vector2 = Vector2(0.5, 0.70)
@export var authored_floor_canvas_source_width: float = 512.0
@export var authored_floor_canvas_anchor_ratio: Vector2 = Vector2(0.5, 0.80)
@export var debug_draw_marker: bool = false
@export var debug_draw_iso_helper_preview: bool = false
@export var render_iso_floor_prototype: bool = false
@export var render_iso_wall_prototype: bool = false
@export var render_iso_object_prototype: bool = false
@export var render_iso_fog_overlay: bool = false
@export var iso_wall_cutaway_enabled: bool = true
@export var show_wall_topology_overlay: bool = false
@export var show_wall_mount_zones_overlay: bool = false
@export var show_object_grounding_overlay: bool = false
@export var show_asset_alignment_overlay: bool = false
@export var show_door_opening_overlay: bool = false
@export var show_wall_run_overlay: bool = false
@export var show_floor_join_overlay: bool = false
@export var use_procedural_floor_debug_tiles: bool = false
@export var debug_floor_tile_bounds: bool = false
@export var use_iso_floor_atlas_textures: bool = false
@export var allow_legacy_floor_texture_assets: bool = false
@export var use_gray_room_visual_test_assets: bool = false
@export var use_iso_visual_preview_preset: bool = false
@export var iso_visual_preview_includes_fog: bool = false
@export var iso_fog_draw_cell_shapes: bool = false
@export var iso_visual_preview_includes_asset_hooks: bool = false
@export var iso_visual_preview_drives_bipob_visual_position: bool = true
@export var debug_draw_iso_fog_outlines: bool = false
@export var iso_fog_unexplored_alpha: float = 0.42
@export var iso_fog_explored_alpha: float = 0.18
@export var iso_fog_visible_alpha: float = 0.0
@export var debug_draw_iso_cell_outlines: bool = false
@export var debug_draw_iso_wall_outlines: bool = false
@export var debug_draw_iso_object_outlines: bool = false
@export var debug_log_iso_object_asset_resolution: bool = false
@export var debug_log_wall_mounted_positioning: bool = false
@export var debug_log_cable_object_bridges: bool = false
@export var use_iso_tile_asset_hooks: bool = false
@export var use_iso_placeholder_asset_preset: bool = false
@export var iso_placeholder_asset_preset_requires_preview: bool = true
@export var iso_floor_atlas_texture: Texture2D = null
@export var iso_floor_default_texture: Texture2D = null
@export var iso_floor_stepped_texture: Texture2D = null
@export var iso_floor_clean_lab_texture: Texture2D = null
@export var iso_floor_dark_service_texture: Texture2D = null
@export var iso_floor_hazard_texture: Texture2D = null
@export var iso_floor_power_texture: Texture2D = null
@export var iso_floor_damaged_texture: Texture2D = null
@export var iso_floor_reinforced_texture: Texture2D = null
@export var iso_floor_diagnostic_texture: Texture2D = null
@export var iso_floor_door_underlay_texture: Texture2D = null
@export var iso_wall_default_texture: Texture2D = null
@export var iso_wall_outer_texture: Texture2D = null
@export var iso_wall_brick_texture: Texture2D = null
@export var iso_wall_concrete_texture: Texture2D = null
@export var iso_wall_grate_texture: Texture2D = null
@export var iso_wall_damaged_texture: Texture2D = null
@export var iso_wall_steel_texture: Texture2D = null
@export var iso_wall_energy_texture: Texture2D = null
@export var iso_object_door_texture: Texture2D = null
@export var iso_object_terminal_texture: Texture2D = null
@export var iso_object_key_texture: Texture2D = null
@export var iso_object_component_texture: Texture2D = null
@export var iso_object_socket_texture: Texture2D = null
@export var iso_object_cable_texture: Texture2D = null
@export var iso_object_generic_texture: Texture2D = null
@export var iso_object_fuse_texture: Texture2D = null
@export var iso_object_repair_kit_texture: Texture2D = null
@export var iso_object_keycard_texture: Texture2D = null
@export var iso_object_access_code_texture: Texture2D = null
@export var iso_object_cable_reel_texture: Texture2D = null
@export var iso_object_button_texture: Texture2D = null
@export var iso_object_switch_texture: Texture2D = null
@export_enum("standard_128x71", "classic_128x64", "preview_128x71", "custom_export_values") var iso_projection_mode: String = "standard_128x71"
@export var iso_tile_width: float = 128.0
@export var iso_tile_height: float = 71.0
@export var iso_wall_height: float = 56.0
@export var iso_floor_projection_pitch_correction_degrees: float = 0.0
@export var iso_floor_visual_inset: float = 1.0
@export var iso_wall_visual_inset: float = 8.0
@export var iso_object_marker_height: float = 18.0
@export var iso_origin: Vector2 = Vector2.ZERO

const ISO_PROJECTION_STANDARD: String = IsoProjectionServiceRef.PROJECTION_STANDARD
const ISO_PROJECTION_CLASSIC: String = IsoProjectionServiceRef.PROJECTION_CLASSIC # Legacy visual option only.
const ISO_PROJECTION_PREVIEW_181: String = IsoProjectionServiceRef.PROJECTION_PREVIEW_181 # Legacy serialized alias for standard_128x71.
const ISO_PROJECTION_CUSTOM: String = IsoProjectionServiceRef.PROJECTION_CUSTOM
const ISO_STANDARD_TILE_SIZE: Vector2 = IsoProjectionServiceRef.STANDARD_TILE_SIZE
const ISO_CLASSIC_TILE_SIZE: Vector2 = IsoProjectionServiceRef.CLASSIC_TILE_SIZE
const WALL_CABLE_RAIL_Y_RATIO: float = 0.44
const WALL_CABLE_RAIL_HALF_WIDTH_RATIO: float = 0.30


# Authored cooling-canvas and outer utility layout policy stays in the
# coordinator. RouteRenderer owns route geometry, not asset canvas regions.
const OUTER_UTILITY_WIDTH_SCALE := 5.0
const OUTER_UTILITY_HEIGHT_SCALE := 2.0
const OUTER_UTILITY_VERTICAL_OFFSET_SCALE := 2.0
const ISO_COOLING_WALL_CANVAS_FACE_REGIONS: Dictionary = {
	"sw": Rect2(0.0, 0.0, 0.5, 1.0),
	"se": Rect2(0.5, 0.0, 0.5, 1.0)
}

const ISO_OBJECT_CANONICAL_VISUAL_IDS: Array[String] = [
	"power_source_01", "terminal_01", "radiator_01", "radiator_floor_01", "light_01",
	"light_off_wall_01", "light_on_wall_01", "light_on_wall_pulsar_overlay_01",
	"cable_reel_01", "cable_reel_02",
	"fuse_box_in_01", "fuse_box_out_01", "fuse_box_in_wall_01", "fuse_box_out_wall_01",
	"barrel_01", "fire_barrel_01", "normal_barrel_floor_01", "fire_barrel_floor_01",
	"normal_crate_floor_01", "radiator_floor_01"
]

const ISO_WALL_ASSET_PACK_DIR: String       = WallRendererRef.ISO_WALL_ASSET_PACK_DIR
const ISO_WALL_BREACH_OVERLAY_PACK_DIR: String       = WallRendererRef.ISO_WALL_BREACH_OVERLAY_PACK_DIR
const ISO_COOLING_SYSTEM_ASSET_PACK_DIR: String = "res://assets/visual/isometric/cooling system/"
const ISO_WALL_BREACH_OVERLAY_CATALOG: Dictionary       = WallRendererRef.ISO_WALL_BREACH_OVERLAY_CATALOG
const ISO_TEST_ASSET_PACK_DIR: String = "res://assets/visual/isometric/test/"
const ISO_WALL_ASSET_EXPECTED_SIZE: Vector2       = WallRendererRef.ISO_WALL_ASSET_EXPECTED_SIZE
const ISO_WALL_HEIGHT_LEVELS: Array[String]       = WallRendererRef.ISO_WALL_HEIGHT_LEVELS
const ISO_OUTER_WALL_HEIGHT_ORDER: Array[String]       = WallRendererRef.ISO_OUTER_WALL_HEIGHT_ORDER
const ISO_GRATE_WALL_HEIGHT_LEVELS: Array[String]       = WallRendererRef.ISO_GRATE_WALL_HEIGHT_LEVELS
const ISO_TEST_WALL_HEIGHT_ORDER: Array[String]       = WallRendererRef.ISO_TEST_WALL_HEIGHT_ORDER
const ISO_TEST_WALL_HEIGHT_ASSET_KEYS: Dictionary       = WallRendererRef.ISO_TEST_WALL_HEIGHT_ASSET_KEYS
const ISO_GRAY_TEST_REQUIRED_ASSET_KEYS: Array[String] = [
	"floor_gray_test",
	"wall_gray_tallest",
	"wall_gray_tall",
	"wall_gray_mid",
	"wall_gray_halfmid",
	"wall_gray_low"
]
const ISO_WALL_ASSET_CATALOG: Dictionary       = WallRendererRef.ISO_WALL_ASSET_CATALOG

const ISO_FLOOR_ASSET_PACK_DIR: String = FloorRendererRef.FLOOR_ASSET_PACK_DIR
const ISO_FLOOR_TEST_ASSET_KEY: String = FloorRendererRef.FLOOR_TEST_ASSET_KEY
const ISO_FLOOR_ASSET_CATALOG: Dictionary = FloorRendererRef.FLOOR_ASSET_CATALOG
const ISO_GROUND_ASSET_PACK_DIR: String = FloorRendererRef.GROUND_ASSET_PACK_DIR
const ISO_GROUND_ASSET_CATALOG: Dictionary = FloorRendererRef.GROUND_ASSET_CATALOG
const ISO_FLOOR_ASSET_TARGET_FOOTPRINT: Vector2 = FloorRendererRef.FLOOR_ASSET_TARGET_FOOTPRINT
const ISO_FLOOR_ASSET_NORMALIZED_OVERLAP: Vector2 = FloorRendererRef.FLOOR_ASSET_NORMALIZED_OVERLAP
const ISO_FLOOR_ASSET_PLACEMENT: Dictionary = FloorRendererRef.FLOOR_ASSET_PLACEMENT
const ISO_GROUND_ASSET_PLACEMENT: Dictionary = FloorRendererRef.GROUND_ASSET_PLACEMENT

# Wall PNGs contain intentionally large transparent margins.  These bounds are
# measured from the checked-in wall atlas files and used only by the renderer so
# the visible wall base, not the full transparent canvas, is anchored to the
# active 128x71 isometric wall footprint.
const ISO_WALL_BASELINE_VISIBLE_BOUNDS: Rect2       = WallRendererRef.ISO_WALL_BASELINE_VISIBLE_BOUNDS
const ISO_WALL_HEIGHT_VISIBLE_BOUNDS: Dictionary       = WallRendererRef.ISO_WALL_HEIGHT_VISIBLE_BOUNDS
const ISO_TEST_WALL_VISIBLE_BOUNDS: Dictionary       = WallRendererRef.ISO_TEST_WALL_VISIBLE_BOUNDS
const ISO_WALL_ASSET_PLACEMENT: Dictionary       = WallRendererRef.ISO_WALL_ASSET_PLACEMENT

const ISO_FLOOR_ATLAS_COLUMNS: int = FloorRendererRef.FLOOR_ATLAS_COLUMNS
const ISO_FLOOR_ATLAS_ROWS: int = FloorRendererRef.FLOOR_ATLAS_ROWS
const ISO_FLOOR_ATLAS_BASE_VARIANTS: int = FloorRendererRef.FLOOR_ATLAS_BASE_VARIANTS
const ISO_FLOOR_ATLAS_HEAVY_METAL_VARIANTS: int = FloorRendererRef.FLOOR_ATLAS_HEAVY_METAL_VARIANTS
const ISO_FLOOR_ATLAS_SOURCE_EDGE_PADDING: float = FloorRendererRef.FLOOR_ATLAS_SOURCE_EDGE_PADDING
const ISO_FLOOR_ATLAS_SCREEN_OVERLAP: float = FloorRendererRef.FLOOR_ATLAS_SCREEN_OVERLAP
const ISO_FLOOR_UNDERLAY_OVERLAP: float = FloorRendererRef.FLOOR_UNDERLAY_OVERLAP
const ISO_FLOOR_ASSET_SCREEN_OVERLAP: float = FloorRendererRef.FLOOR_ASSET_SCREEN_OVERLAP
const ISO_FLOOR_OVERLAY_INNER_INSET: float = FloorRendererRef.FLOOR_OVERLAY_INNER_INSET
const ISO_FLOOR_SEAM_SAFE_BASE_VARIANTS: Dictionary = FloorRendererRef.FLOOR_SEAM_SAFE_BASE_VARIANTS
const ISO_FLOOR_ATLAS_LAYOUT: Dictionary = FloorRendererRef.FLOOR_ATLAS_LAYOUT

const ISO_ASSET_ALIGNMENT_RULES: Dictionary = {
	"floor_default": {"anchor": "center", "scale": 1.0, "offset": Vector2.ZERO, "expected_size": ISO_STANDARD_TILE_SIZE, "layer_hint": "floor", "notes": "Default 128x71 floor diamond centered in the grid cell."},
	"floor_concrete": {"anchor": "center", "scale": 1.0, "offset": Vector2.ZERO, "expected_size": ISO_STANDARD_TILE_SIZE, "layer_hint": "floor", "notes": "Concrete floor PNG is squeezed to the active isometric floor footprint."},
	"floor_steel": {"anchor": "center", "scale": 1.0, "offset": Vector2.ZERO, "expected_size": ISO_STANDARD_TILE_SIZE, "layer_hint": "floor", "notes": "Steel floor PNG is squeezed to the active isometric floor footprint."},
	"floor_titan": {"anchor": "center", "scale": 1.0, "offset": Vector2.ZERO, "expected_size": ISO_STANDARD_TILE_SIZE, "layer_hint": "floor", "notes": "Titanium floor PNG is squeezed to the active isometric floor footprint."},
	"floor_stepped": {"anchor": "center", "scale": 1.0, "offset": Vector2.ZERO, "expected_size": ISO_STANDARD_TILE_SIZE, "layer_hint": "floor", "notes": "Stepped 128x71 floor diamond centered in the grid cell."},
	"floor_clean_lab": {"anchor": "center", "scale": 1.0, "offset": Vector2.ZERO, "expected_size": ISO_STANDARD_TILE_SIZE, "layer_hint": "floor", "notes": "Clean lab 128x71 floor diamond centered in the grid cell."},
	"floor_dark_service": {"anchor": "center", "scale": 1.0, "offset": Vector2.ZERO, "expected_size": ISO_STANDARD_TILE_SIZE, "layer_hint": "floor", "notes": "Dark service 128x71 floor diamond centered in the grid cell."},
	"floor_hazard": {"anchor": "center", "scale": 1.0, "offset": Vector2.ZERO, "expected_size": ISO_STANDARD_TILE_SIZE, "layer_hint": "floor", "notes": "Hazard 128x71 floor diamond centered in the grid cell."},
	"floor_power": {"anchor": "center", "scale": 1.0, "offset": Vector2.ZERO, "expected_size": ISO_STANDARD_TILE_SIZE, "layer_hint": "floor", "notes": "Powered 128x71 floor diamond centered in the grid cell."},
	"floor_damaged": {"anchor": "center", "scale": 1.0, "offset": Vector2.ZERO, "expected_size": ISO_STANDARD_TILE_SIZE, "layer_hint": "floor", "notes": "Damaged 128x71 floor diamond centered in the grid cell."},
	"floor_reinforced": {"anchor": "center", "scale": 1.0, "offset": Vector2.ZERO, "expected_size": ISO_STANDARD_TILE_SIZE, "layer_hint": "floor", "notes": "Reinforced 128x71 floor diamond centered in the grid cell."},
	"floor_diagnostic": {"anchor": "center", "scale": 1.0, "offset": Vector2.ZERO, "expected_size": ISO_STANDARD_TILE_SIZE, "layer_hint": "floor", "notes": "Diagnostic 128x71 floor diamond centered in the grid cell."},
	"floor_door_underlay": {"anchor": "center", "scale": 1.0, "offset": Vector2.ZERO, "expected_size": ISO_STANDARD_TILE_SIZE, "layer_hint": "floor", "notes": "Door underlay remains centered under the wall opening."},
	"ground_low": {"anchor": "center", "scale": 1.0, "offset": Vector2.ZERO, "expected_size": ISO_STANDARD_TILE_SIZE, "layer_hint": "floor", "notes": "Visual-only raised ground step 1 floor asset."},
	"ground_halflow": {"anchor": "center", "scale": 1.0, "offset": Vector2.ZERO, "expected_size": ISO_STANDARD_TILE_SIZE, "layer_hint": "floor", "notes": "Visual-only raised ground step 2 floor asset."},
	"wall_default": {"anchor": "wall_cell_base", "scale": 1.0, "offset": Vector2(0, -32), "expected_size": Vector2(128, 120), "layer_hint": "wall", "notes": "Wall canvas bottom-center aligns to the blocked wall cell base on the active 128x71 footprint."},
	"wall_outer": {"anchor": "wall_cell_base", "scale": 1.0, "offset": Vector2(0, -32), "expected_size": Vector2(128, 120), "layer_hint": "wall", "notes": "Outer wall canvas bottom-center aligns to the blocked wall cell base on the active 128x71 footprint."},
	"wall_brick": {"anchor": "wall_cell_base", "scale": 1.0, "offset": Vector2(0, -32), "expected_size": Vector2(128, 120), "layer_hint": "wall", "notes": "Brick wall canvas bottom-center aligns to the blocked wall cell base on the active 128x71 footprint."},
	"wall_concrete": {"anchor": "wall_cell_base", "scale": 1.0, "offset": Vector2(0, -32), "expected_size": Vector2(128, 120), "layer_hint": "wall", "notes": "Concrete wall canvas bottom-center aligns to the blocked wall cell base on the active 128x71 footprint."},
	"wall_grate": {"anchor": "wall_cell_base", "scale": 1.0, "offset": Vector2(0, -32), "expected_size": Vector2(128, 120), "layer_hint": "wall", "notes": "Grate wall canvas bottom-center aligns to the blocked wall cell base on the active 128x71 footprint."},
	"wall_concrete_damaged": {"anchor": "wall_cell_base", "scale": 1.0, "offset": Vector2(0, -32), "expected_size": Vector2(128, 120), "layer_hint": "wall", "notes": "Concrete damaged wall visible base anchors to the blocked wall cell base on the active 128x71 footprint."},
	"wall_brick_damaged": {"anchor": "wall_cell_base", "scale": 1.0, "offset": Vector2(0, -32), "expected_size": Vector2(128, 120), "layer_hint": "wall", "notes": "Brick damaged wall visible base anchors to the blocked wall cell base on the active 128x71 footprint."},
	"wall_steel": {"anchor": "wall_cell_base", "scale": 1.0, "offset": Vector2(0, -32), "expected_size": Vector2(128, 120), "layer_hint": "wall", "notes": "Steel wall canvas bottom-center aligns to the blocked wall cell base on the active 128x71 footprint."},
	"wall_energy": {"anchor": "wall_cell_base", "scale": 1.0, "offset": Vector2(0, -32), "expected_size": Vector2(128, 120), "layer_hint": "wall", "notes": "Energy wall canvas bottom-center aligns to the blocked wall cell base on the active 128x71 footprint."},
	"object_door": {"anchor": "door_insert_center", "scale": 0.9, "offset": Vector2(0, -20), "expected_size": Vector2(96, 96), "layer_hint": "object", "notes": "Door art centers inside the visual wall opening."},
	"object_terminal": {"anchor": "wall_mount_center", "scale": 0.8, "offset": Vector2(0, -18), "expected_size": Vector2(96, 96), "layer_hint": "object", "notes": "Terminal art centers on the wall mount band."},
	"object_key": {"anchor": "bottom_center", "scale": 0.55, "offset": Vector2(0, -6), "expected_size": Vector2(96, 96), "layer_hint": "object", "notes": "Key pickup uses a small bottom-centered floor footprint."},
	"object_component": {"anchor": "bottom_center", "scale": 0.75, "offset": Vector2(0, -8), "expected_size": Vector2(96, 96), "layer_hint": "object", "notes": "Component prop uses a readable bottom-centered floor footprint."},
	"object_socket": {"anchor": "wall_mount_center", "scale": 0.8, "offset": Vector2(0, -18), "expected_size": Vector2(96, 96), "layer_hint": "object", "notes": "Socket art centers on the wall mount band."},
	"object_cable": {"anchor": "bottom_center", "scale": 0.75, "offset": Vector2(0, -8), "expected_size": Vector2(96, 96), "layer_hint": "object", "notes": "Cable-like prop uses a readable bottom-centered floor footprint."},
	"object_generic": {"anchor": "bottom_center", "scale": 0.75, "offset": Vector2(0, -8), "expected_size": Vector2(96, 96), "layer_hint": "object", "notes": "Generic prop uses a readable bottom-centered floor footprint."},
	"object_fuse": {"anchor": "bottom_center", "scale": 0.55, "offset": Vector2(0, -6), "expected_size": Vector2(96, 96), "layer_hint": "object", "notes": "Fuse pickup uses a small bottom-centered floor footprint."},
	"object_repair_kit": {"anchor": "bottom_center", "scale": 0.55, "offset": Vector2(0, -6), "expected_size": Vector2(96, 96), "layer_hint": "object", "notes": "Repair kit pickup uses a small bottom-centered floor footprint."},
	"object_keycard": {"anchor": "bottom_center", "scale": 0.55, "offset": Vector2(0, -6), "expected_size": Vector2(96, 96), "layer_hint": "object", "notes": "Keycard pickup uses a small bottom-centered floor footprint."},
	"object_access_code": {"anchor": "bottom_center", "scale": 0.55, "offset": Vector2(0, -6), "expected_size": Vector2(96, 96), "layer_hint": "object", "notes": "Access-code pickup uses a small bottom-centered floor footprint."},
	"object_cable_reel": {"anchor": "bottom_center", "scale": 0.75, "offset": Vector2(0, -8), "expected_size": Vector2(96, 96), "layer_hint": "object", "notes": "Cable reel prop uses a readable bottom-centered floor footprint."},
	"object_button": {"anchor": "wall_mount_center", "scale": 0.8, "offset": Vector2(0, -18), "expected_size": Vector2(96, 96), "layer_hint": "object", "notes": "Button art centers on the wall mount band."},
	"object_switch": {"anchor": "wall_mount_center", "scale": 0.8, "offset": Vector2(0, -18), "expected_size": Vector2(96, 96), "layer_hint": "object", "notes": "Switch art centers on the wall mount band."}
}

var _iso_placeholder_texture_cache: Dictionary = {}
var _iso_object_png_texture_cache: Dictionary = {}
var _iso_light_overlay_animation_requested: bool = false
var selected_interaction_target: Dictionary = {}
var selected_interaction_overlay_time: float = 0.0
var _iso_wall_asset_texture_cache: Dictionary = {}
var _iso_wall_breach_overlay_texture_cache: Dictionary = {}
var _iso_floor_asset_texture_cache: Dictionary = {}
var _iso_ground_asset_texture_cache: Dictionary = {}
var _grid_manager: GridManager = null
var _rebuild_requested: bool = false
var debug_rebuild_request_count: int = 0

var selected_iso_cell: Vector2i = Vector2i(-1, -1)
var selected_iso_route_cells: Array[Vector2i] = []
var selected_iso_action_cell: Vector2i = Vector2i(-1, -1)
var map_constructor_preview_cell: Vector2i = Vector2i(-1, -1)
var map_constructor_preview_attached_wall_cell: Vector2i = Vector2i(-1, -1)
var map_constructor_preview_wall_side: String = ""
var map_constructor_preview_is_blocked: bool = false
var selected_wall_mounted_anchor_cell: Vector2i = Vector2i(-1, -1)
var selected_wall_mounted_attached_wall_cell: Vector2i = Vector2i(-1, -1)
var selected_wall_mounted_object_id: String = ""
var map_constructor_link_target_cell: Vector2i = Vector2i(-1, -1)
var map_constructor_link_target_object_id: String = ""
const WALL_SIDE_ORDER: Array[String]       = WallRendererRef.WALL_SIDE_ORDER
const WALL_MASS_RATIO: float       = WallRendererRef.WALL_MASS_RATIO
const WALL_MOUNT_BAND_RATIO: float       = WallRendererRef.WALL_MOUNT_BAND_RATIO

func _enter_tree() -> void:
	if _grid_manager == null:
		_grid_manager = get_parent() as GridManager
	_connect_grid_manager_invalidation()

func _ready() -> void:
	if _grid_manager != null:
		request_rebuild()

func _exit_tree() -> void:
	_disconnect_grid_manager_invalidation()

func set_grid_manager(grid: GridManager) -> void:
	if _grid_manager == grid:
		_connect_grid_manager_invalidation()
		return
	_disconnect_grid_manager_invalidation()
	_grid_manager = grid
	_connect_grid_manager_invalidation()
	request_rebuild()

func initialize_from_grid(grid: GridManager) -> void:
	# Atlas floor tiles are downsampled heavily, so nearest sampling avoids
	# bright sub-pixel bleed from neighboring atlas frames and transparent edges.
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_grid_manager(grid)

func _connect_grid_manager_invalidation() -> void:
	if _grid_manager != null and not _grid_manager.grid_visual_invalidated.is_connected(_on_grid_visual_invalidated):
		_grid_manager.grid_visual_invalidated.connect(_on_grid_visual_invalidated)

func _disconnect_grid_manager_invalidation() -> void:
	if _grid_manager != null and _grid_manager.grid_visual_invalidated.is_connected(_on_grid_visual_invalidated):
		_grid_manager.grid_visual_invalidated.disconnect(_on_grid_visual_invalidated)

func _on_grid_visual_invalidated(_reason: String, _changed_cells: Array) -> void:
	request_rebuild()

func is_grid_visual_invalidation_connected() -> bool:
	return _grid_manager != null and _grid_manager.grid_visual_invalidated.is_connected(_on_grid_visual_invalidated)

func request_rebuild() -> void:
	debug_rebuild_request_count += 1
	_rebuild_requested = true
	rebuild_visuals()
	queue_redraw()

func clear_visuals() -> void:
	_rebuild_requested = false
	queue_redraw()

func rebuild_visuals() -> void:
	if _grid_manager == null:
		_rebuild_requested = false
		return
	# Placeholder only: future PRs will build projected room visuals here.
	_rebuild_requested = false

func is_iso_visual_preview_active() -> bool:
	return use_iso_visual_preview_preset

func is_iso_renderer_active() -> bool:
	return (
		use_iso_visual_preview_preset
		or render_iso_floor_prototype
		or render_iso_wall_prototype
		or render_iso_object_prototype
		or use_iso_placeholder_asset_preset
	)

func should_render_iso_floor_visuals() -> bool:
	return (render_iso_floor_prototype or use_iso_visual_preview_preset)

func should_render_iso_wall_visuals() -> bool:
	return (render_iso_wall_prototype or use_iso_visual_preview_preset)

func should_render_iso_object_visuals() -> bool:
	return (render_iso_object_prototype or use_iso_visual_preview_preset)

func should_suppress_iso_fog_for_constructor() -> bool:
	var mission_manager: Node = get_mission_manager_ref()
	if mission_manager == null:
		return false
	if mission_manager.has_method("_is_task_test_constructor_context"):
		return bool(mission_manager.call("_is_task_test_constructor_context"))
	if mission_manager.has_method("get_current_mission_id"):
		return str(mission_manager.call("get_current_mission_id")) == "mission_10"
	return false

func should_render_iso_fog_visuals() -> bool:
	var fog_requested: bool = render_iso_fog_overlay or (use_iso_visual_preview_preset and iso_visual_preview_includes_fog)
	if should_suppress_iso_fog_for_constructor() and not render_iso_fog_overlay:
		return false
	return fog_requested

func should_draw_iso_fog_cell_shapes() -> bool:
	return should_render_iso_fog_visuals() and iso_fog_draw_cell_shapes

func should_use_iso_placeholder_asset_preset() -> bool:
	if not use_iso_placeholder_asset_preset:
		return false
	if iso_placeholder_asset_preset_requires_preview and not is_iso_visual_preview_active():
		return false
	return true

func should_use_iso_tile_asset_hook_visuals() -> bool:
	return (
		use_iso_tile_asset_hooks
		or (use_iso_visual_preview_preset and iso_visual_preview_includes_asset_hooks)
		or should_use_iso_placeholder_asset_preset()
	)

func is_task_test_visual_preview_context() -> bool:
	var mission_manager: Node = get_mission_manager_ref()
	if mission_manager == null:
		return use_iso_visual_preview_preset
	if mission_manager.has_method("_is_task_test_constructor_context"):
		return bool(mission_manager.call("_is_task_test_constructor_context"))
	if mission_manager.has_method("get_current_mission_id"):
		return str(mission_manager.call("get_current_mission_id")) == "mission_10"
	return use_iso_visual_preview_preset

func should_preview_drive_bipob_visual_position() -> bool:
	return (use_iso_visual_preview_preset and iso_visual_preview_drives_bipob_visual_position)

func get_iso_visual_preview_state() -> Dictionary:
	var projection_size: Vector2 = get_iso_tile_size()
	return {
		"preview_active": is_iso_visual_preview_active(),
		"projection_mode": get_iso_projection_mode(),
		"projection_tile_size": projection_size,
		"floor": should_render_iso_floor_visuals(),
		"wall": should_render_iso_wall_visuals(),
		"objects": should_render_iso_object_visuals(),
		"fog": should_render_iso_fog_visuals(),
		"fog_cell_shapes": should_draw_iso_fog_cell_shapes(),
		"constructor_fog_suppressed": should_suppress_iso_fog_for_constructor(),
		"asset_hooks": should_use_iso_tile_asset_hook_visuals(),
		"placeholder_assets": should_use_iso_placeholder_asset_preset(),
		"placeholder_requires_preview": iso_placeholder_asset_preset_requires_preview,
		"drives_bipob_visual_position": should_preview_drive_bipob_visual_position()
	}

func get_iso_visual_preview_state_text() -> String:
	var state: Dictionary = get_iso_visual_preview_state()
	return "IsoVisualPreview active=%s projection=%s tile=%s floor=%s wall=%s objects=%s fog=%s asset_hooks=%s placeholder_assets=%s drives_bipob=%s" % [
		str(state.get("preview_active", false)),
		str(state.get("projection_mode", ISO_PROJECTION_STANDARD)),
		str(Vector2(state.get("projection_tile_size", ISO_STANDARD_TILE_SIZE))),
		str(state.get("floor", false)),
		str(state.get("wall", false)),
		str(state.get("objects", false)),
		str(state.get("fog", false)),
		str(state.get("asset_hooks", false)),
		str(state.get("placeholder_assets", false)),
		str(state.get("drives_bipob_visual_position", false))
	]

func get_iso_projection_mode() -> String:
	return IsoProjectionServiceRef.normalize_mode(iso_projection_mode)

func get_iso_tile_size() -> Vector2:
	return IsoProjectionServiceRef.get_tile_size(iso_projection_mode, iso_tile_width, iso_tile_height)

func get_iso_exported_tile_size_matches_active_mode() -> bool:
	return IsoProjectionServiceRef.exported_tile_size_matches_active_mode(iso_projection_mode, iso_tile_width, iso_tile_height)

func get_iso_projection_diagnostic_text() -> String:
	var active_size: Vector2 = get_iso_tile_size()
	var ratio: float = active_size.x / maxf(active_size.y, 1.0)
	return "Iso projection: %s tile=%s ratio=%.4f exported_match=%s" % [
		get_iso_projection_mode(),
		str(active_size),
		ratio,
		str(get_iso_exported_tile_size_matches_active_mode())
	]

func get_iso_tile_half_size() -> Vector2:
	return IsoProjectionServiceRef.get_tile_half_size(get_iso_tile_size(), iso_floor_projection_pitch_correction_degrees)

func grid_to_iso(cell: Vector2i) -> Vector2:
	return IsoProjectionServiceRef.grid_to_iso(cell, iso_origin, get_iso_tile_half_size())

func get_object_visual_center(cell: Vector2i, object_data: Dictionary = {}) -> Vector2:
	# Visual-only helper for object overlay markers.
	# Keeps object anchors deterministic and independent of gameplay systems.
	var center: Vector2 = grid_to_iso(cell)
	var object_type: String = str(object_data.get("type", "")).to_lower()
	var object_kind: String = str(object_data.get("kind", "")).to_lower()
	var object_visual_hint: String = str(object_data.get("visual_hint", "")).to_lower()
	var object_id: String = str(object_data.get("id", "")).to_lower()
	var hint_blob: String = "%s %s %s %s" % [object_type, object_kind, object_visual_hint, object_id]
	if hint_blob.contains("wall") or hint_blob.contains("door") or hint_blob.contains("terminal"):
		return center + Vector2(0.0, -6.0)
	return center


func set_selected_interaction_target(target: Dictionary) -> void:
	selected_interaction_target = target.duplicate(true)
	queue_redraw()


func _get_selected_interaction_target_cell() -> Vector2i:
	if selected_interaction_target.is_empty():
		return Vector2i(-1, -1)
	return _try_parse_cell_variant(selected_interaction_target.get("cell", Vector2i(-1, -1)))


func _get_selected_interaction_overlay_rect(cell: Vector2i) -> Rect2:
	return OverlayRendererRef.build_interaction_target_rect(_build_selected_interaction_overlay_context(cell))


func _build_selected_interaction_overlay_context(cell: Vector2i) -> Dictionary:
	return {
		"kind": str(selected_interaction_target.get("kind", "world_object")).strip_edges().to_lower(),
		"object_type": str(selected_interaction_target.get("object_type", "")).strip_edges().to_lower(),
		"default_center": get_object_visual_center(cell, selected_interaction_target),
		"wall_center": grid_to_iso(cell) + Vector2(0.0, -iso_wall_height * 0.35),
		"tile_half_size": get_iso_tile_half_size(),
		"wall_height": iso_wall_height,
		"object_marker_height": iso_object_marker_height,
		"time_seconds": selected_interaction_overlay_time
	}


func draw_selected_interaction_target_overlay() -> void:
	var cell: Vector2i = _get_selected_interaction_target_cell()
	if cell.x < 0 or cell.y < 0:
		return
	_draw_overlay_commands(OverlayRendererRef.build_interaction_target_commands(_build_selected_interaction_overlay_context(cell)))

func iso_to_grid(iso_position: Vector2) -> Vector2i:
	return IsoProjectionServiceRef.iso_to_grid(iso_position, iso_origin, get_iso_tile_half_size())

func get_iso_diamond_points(cell: Vector2i) -> PackedVector2Array:
	return IsoProjectionServiceRef.get_diamond_points(cell, iso_origin, get_iso_tile_half_size())

func get_iso_inset_diamond_points(cell: Vector2i, inset: float) -> PackedVector2Array:
	return IsoProjectionServiceRef.get_inset_diamond_points(cell, inset, iso_origin, get_iso_tile_half_size())

func get_iso_wall_base_points(cell: Vector2i) -> PackedVector2Array:
	return WallRendererRef.get_base_points(_grid_manager, cell, iso_origin, get_iso_tile_half_size(), iso_wall_visual_inset)

func get_iso_wall_connected_base_points(cell: Vector2i, topology: Dictionary) -> PackedVector2Array:
	return WallRendererRef.get_connected_base_points(cell, topology, iso_origin, get_iso_tile_half_size(), iso_wall_visual_inset)


func is_point_inside_iso_diamond(point: Vector2, diamond_points: PackedVector2Array) -> bool:
	if diamond_points.size() < 3:
		return false
	if Geometry2D.is_point_in_polygon(point, diamond_points):
		return true
	var direction_sign: int = 0
	for idx in range(diamond_points.size()):
		var next_idx: int = (idx + 1) % diamond_points.size()
		var edge: Vector2 = diamond_points[next_idx] - diamond_points[idx]
		var point_delta: Vector2 = point - diamond_points[idx]
		var cross: float = edge.cross(point_delta)
		if is_zero_approx(cross):
			continue
		var current_sign: int = 1 if cross > 0.0 else -1
		if direction_sign == 0:
			direction_sign = current_sign
		elif direction_sign != current_sign:
			return false
	return true
func get_cell_runtime_surface_level_for_selection(cell: Vector2i) -> int:
	var ground_asset_key: String = get_ground_asset_key_for_cell(cell) if has_method("get_ground_asset_key_for_cell") else ""

	match ground_asset_key:
		"ground_low":
			return 1
		"ground_halflow":
			return 2

	var mission_manager: Node = get_mission_manager_ref()
	if mission_manager != null and mission_manager.has_method("get_cell_height_level"):
		return maxi(0, int(mission_manager.call("get_cell_height_level", cell)))

	return 0


func get_cell_runtime_surface_y_offset_for_selection(cell: Vector2i) -> float:
	var ground_asset_key: String = get_ground_asset_key_for_cell(cell) if has_method("get_ground_asset_key_for_cell") else ""

	if not ground_asset_key.is_empty() and has_method("get_ground_surface_y_offset_for_asset_key"):
		var ground_offset: float = float(get_ground_surface_y_offset_for_asset_key(ground_asset_key))
		if not is_zero_approx(ground_offset):
			return ground_offset

	var surface_level: int = get_cell_runtime_surface_level_for_selection(cell)
	if surface_level <= 0:
		return 0.0

	return -float(surface_level) * maxf(iso_object_marker_height, 18.0)


func _offset_iso_points_to_runtime_surface(points: PackedVector2Array, cell: Vector2i) -> PackedVector2Array:
	var surface_y_offset: float = get_cell_runtime_surface_y_offset_for_selection(cell)

	if is_zero_approx(surface_y_offset):
		return points

	var shifted: PackedVector2Array = PackedVector2Array()
	for point in points:
		shifted.append(point + Vector2(0.0, surface_y_offset))

	return shifted


func get_iso_surface_diamond_points(cell: Vector2i) -> PackedVector2Array:
	return _offset_iso_points_to_runtime_surface(get_iso_diamond_points(cell), cell)


func get_iso_inset_surface_diamond_points(cell: Vector2i, inset: float) -> PackedVector2Array:
	return _offset_iso_points_to_runtime_surface(get_iso_inset_diamond_points(cell, inset), cell)


func sort_cells_by_iso_surface_pick_depth(a: Vector2i, b: Vector2i) -> bool:
	var a_level: int = get_cell_runtime_surface_level_for_selection(a)
	var b_level: int = get_cell_runtime_surface_level_for_selection(b)

	if a_level != b_level:
		return a_level < b_level

	return sort_cells_by_iso_depth(a, b)
	
func get_cell_at_iso_visual_position(local_position: Vector2) -> Vector2i:
	if _grid_manager == null:
		return Vector2i(-1, -1)

	var map_width: int = _grid_manager.get_map_width()
	var map_height: int = _grid_manager.get_map_height()

	if map_width <= 0 or map_height <= 0:
		return Vector2i(-1, -1)

	var surface_matched_cells: Array[Vector2i] = []

	for y in range(map_height):
		for x in range(map_width):
			var cell: Vector2i = Vector2i(x, y)
			var surface_points: PackedVector2Array = get_iso_surface_diamond_points(cell)

			if is_point_inside_iso_diamond(local_position, surface_points):
				surface_matched_cells.append(cell)

	if not surface_matched_cells.is_empty():
		surface_matched_cells.sort_custom(sort_cells_by_iso_surface_pick_depth)
		return surface_matched_cells[surface_matched_cells.size() - 1]

	var matched_cells: Array[Vector2i] = []

	for y in range(map_height):
		for x in range(map_width):
			var cell: Vector2i = Vector2i(x, y)
			var diamond_points: PackedVector2Array = get_iso_diamond_points(cell)

			if is_point_inside_iso_diamond(local_position, diamond_points):
				matched_cells.append(cell)

	if matched_cells.is_empty():
		return Vector2i(-1, -1)

	matched_cells.sort_custom(sort_cells_by_iso_depth)
	return matched_cells[matched_cells.size() - 1]

func set_iso_mouse_selection_visuals(selected_cell: Vector2i, route_cells: Array, action_cell: Vector2i = Vector2i(-1, -1)) -> void:
	selected_iso_cell = selected_cell
	selected_iso_route_cells.clear()
	for route_cell_variant in route_cells:
		if route_cell_variant is Vector2i:
			selected_iso_route_cells.append(route_cell_variant)
	selected_iso_action_cell = action_cell
	queue_redraw()

func clear_iso_mouse_selection_visuals() -> void:
	selected_iso_cell = Vector2i(-1, -1)
	selected_iso_route_cells.clear()
	selected_iso_action_cell = Vector2i(-1, -1)
	queue_redraw()

func set_map_constructor_preview_cell(cell: Vector2i) -> void:
	map_constructor_preview_cell = cell
	map_constructor_preview_attached_wall_cell = Vector2i(-1, -1)
	map_constructor_preview_wall_side = ""
	map_constructor_preview_is_blocked = false
	queue_redraw()

func set_map_constructor_wall_mounted_preview(anchor_cell: Vector2i, attached_wall_cell: Vector2i, wall_side: String, is_blocked: bool = false) -> void:
	map_constructor_preview_cell = anchor_cell
	map_constructor_preview_attached_wall_cell = attached_wall_cell
	map_constructor_preview_wall_side = wall_side
	map_constructor_preview_is_blocked = is_blocked
	queue_redraw()

func set_selected_wall_mounted_object(anchor_cell: Vector2i, attached_wall_cell: Vector2i, object_id: String) -> void:
	selected_wall_mounted_anchor_cell = anchor_cell
	selected_wall_mounted_attached_wall_cell = attached_wall_cell
	selected_wall_mounted_object_id = object_id
	queue_redraw()

func clear_selected_wall_mounted_object() -> void:
	selected_wall_mounted_anchor_cell = Vector2i(-1, -1)
	selected_wall_mounted_attached_wall_cell = Vector2i(-1, -1)
	selected_wall_mounted_object_id = ""
	queue_redraw()

func set_map_constructor_link_target(cell: Vector2i, object_id: String) -> void:
	map_constructor_link_target_cell = cell
	map_constructor_link_target_object_id = object_id
	queue_redraw()

func clear_map_constructor_link_target() -> void:
	map_constructor_link_target_cell = Vector2i(-1, -1)
	map_constructor_link_target_object_id = ""
	queue_redraw()

func draw_iso_mouse_selection_overlay() -> void:
	var route_point_sets: Array[PackedVector2Array] = []
	for route_cell in selected_iso_route_cells:
		var route_points: PackedVector2Array = get_iso_inset_surface_diamond_points(route_cell, iso_floor_visual_inset + 10.0)
		route_point_sets.append(route_points)

	var selected_points: PackedVector2Array = PackedVector2Array()
	if selected_iso_cell.x >= 0 and selected_iso_cell.y >= 0:
		selected_points = get_iso_inset_surface_diamond_points(selected_iso_cell, iso_floor_visual_inset + 2.0)

	var action_points: PackedVector2Array = PackedVector2Array()
	if selected_iso_action_cell.x >= 0 and selected_iso_action_cell.y >= 0:
		action_points = get_iso_inset_surface_diamond_points(selected_iso_action_cell, iso_floor_visual_inset + 6.0)

	var wall_anchor_points: PackedVector2Array = PackedVector2Array()
	if selected_wall_mounted_anchor_cell.x >= 0 and selected_wall_mounted_anchor_cell.y >= 0:
		wall_anchor_points = get_iso_inset_diamond_points(selected_wall_mounted_anchor_cell, iso_floor_visual_inset + 4.0)

	var attached_wall_points: PackedVector2Array = PackedVector2Array()
	if selected_wall_mounted_attached_wall_cell.x >= 0 and selected_wall_mounted_attached_wall_cell.y >= 0:
		attached_wall_points = get_iso_inset_diamond_points(selected_wall_mounted_attached_wall_cell, iso_floor_visual_inset + 8.0)

	var has_wall_object_center: bool = false
	var wall_object_center: Vector2 = Vector2.ZERO
	if not selected_wall_mounted_object_id.is_empty():
		var mission_manager: Node = get_mission_manager_ref()
		var obj: Dictionary = {}

		if mission_manager != null and mission_manager.has_method("get_world_object_at_cell"):
			obj = Dictionary(mission_manager.call("get_world_object_at_cell", selected_wall_mounted_anchor_cell))

		if str(obj.get("id", "")) == selected_wall_mounted_object_id:
			wall_object_center = get_object_visual_center(selected_wall_mounted_anchor_cell, obj)
			has_wall_object_center = true

	_draw_overlay_commands(OverlayRendererRef.build_mouse_selection_commands({
		"route_point_sets": route_point_sets,
		"selected_points": selected_points,
		"action_points": action_points,
		"wall_anchor_points": wall_anchor_points,
		"attached_wall_points": attached_wall_points,
		"has_wall_object_center": has_wall_object_center,
		"wall_object_center": wall_object_center
	}))



func _draw_overlay_commands(commands: Array[Dictionary]) -> void:
	for command in commands:
		var kind: String = str(command.get("kind", ""))
		match kind:
			"polygon":
				draw_colored_polygon(PackedVector2Array(command.get("points", PackedVector2Array())), Color(command.get("color", Color.WHITE)))
			"polyline":
				draw_polyline(
					PackedVector2Array(command.get("points", PackedVector2Array())),
					Color(command.get("color", Color.WHITE)),
					float(command.get("width", 1.0)),
					bool(command.get("antialiased", false))
				)
			"line":
				draw_line(
					Vector2(command.get("start", Vector2.ZERO)),
					Vector2(command.get("end", Vector2.ZERO)),
					Color(command.get("color", Color.WHITE)),
					float(command.get("width", 1.0)),
					bool(command.get("antialiased", false))
				)
			"circle":
				draw_circle(
					Vector2(command.get("center", Vector2.ZERO)),
					float(command.get("radius", 1.0)),
					Color(command.get("color", Color.WHITE))
				)
			"rect":
				draw_rect(
					Rect2(command.get("rect", Rect2())),
					Color(command.get("color", Color.WHITE)),
					bool(command.get("filled", true)),
					float(command.get("width", 1.0)),
					bool(command.get("antialiased", false))
				)
			"text":
				draw_string(
					ThemeDB.fallback_font,
					Vector2(command.get("position", Vector2.ZERO)),
					str(command.get("text", "")),
					int(command.get("alignment", HORIZONTAL_ALIGNMENT_LEFT)),
					float(command.get("width", -1.0)),
					int(command.get("font_size", 10)),
					Color(command.get("color", Color.WHITE))
				)

var map_constructor_overlay_prefs: Dictionary = {
	"show_preview": true,
	"show_validation": true,
	"show_links": true,
	"show_power": true,
	"show_wall_side_arrows": true,
	"show_multi_select": true
}
var map_constructor_overlay_data: Dictionary = {}
var map_constructor_editor_render_active: bool = false
func set_map_constructor_overlay_preferences(prefs: Dictionary) -> void:
	for key_variant in prefs.keys():
		var key: String = str(key_variant)
		if map_constructor_overlay_prefs.has(key):
			map_constructor_overlay_prefs[key] = bool(prefs.get(key_variant, map_constructor_overlay_prefs[key]))
	queue_redraw()

func set_map_constructor_overlay_data(data: Dictionary) -> void:
	map_constructor_overlay_data = data.duplicate(true)
	map_constructor_editor_render_active = bool(map_constructor_overlay_data.get("map_constructor_active", map_constructor_editor_render_active))

func set_map_constructor_editor_render_active(active: bool) -> void:
	map_constructor_editor_render_active = active
	queue_redraw()

func _build_map_constructor_overlay_context() -> Dictionary:
	var selected: Dictionary = Dictionary(map_constructor_overlay_data.get("selected", {}))
	var hover: Dictionary = Dictionary(map_constructor_overlay_data.get("hover", {}))
	var preview: Dictionary = Dictionary(map_constructor_overlay_data.get("preview", {}))
	var room_visual_preview: Dictionary = Dictionary(map_constructor_overlay_data.get("room_visual_preview", {}))
	var context: Dictionary = {}
	if selected.has("cell"):
		var selected_cell: Vector2i = Vector2i(selected.get("cell", Vector2i(-1, -1)))
		if selected_cell.x >= 0 and selected_cell.y >= 0:
			context["selected_points"] = get_iso_inset_diamond_points(selected_cell, iso_floor_visual_inset + 1.5)
	if hover.has("cell"):
		var hover_cell: Vector2i = Vector2i(hover.get("cell", Vector2i(-1, -1)))
		if hover_cell.x >= 0 and hover_cell.y >= 0:
			context["hover_points"] = get_iso_inset_diamond_points(hover_cell, iso_floor_visual_inset + 6.0)
	if bool(map_constructor_overlay_prefs.get("show_preview", true)):
		if map_constructor_preview_cell.x >= 0 and map_constructor_preview_cell.y >= 0:
			context["preview_points"] = get_iso_inset_diamond_points(map_constructor_preview_cell, iso_floor_visual_inset + 3.0)
			context["preview_mode"] = MapConstructorOverlayRendererRef.normalize_preview_mode(map_constructor_preview_is_blocked, str(preview.get("mode", "")))
		var room_walls: Array[Dictionary] = []
		for wall_row_variant in Array(room_visual_preview.get("walls", [])):
			var wall_row: Dictionary = Dictionary(wall_row_variant)
			var wall_cell: Vector2i = Vector2i(wall_row.get("cell", Vector2i(-1, -1)))
			if wall_cell.x < 0 or wall_cell.y < 0:
				continue
			room_walls.append({"points": get_iso_inset_diamond_points(wall_cell, iso_floor_visual_inset + 12.0), "center": grid_to_iso(wall_cell)})
		context["room_walls"] = room_walls
		var door_centers: Array[Vector2] = []
		for door_row_variant in Array(room_visual_preview.get("doors", [])):
			var door_cell: Vector2i = Vector2i(Dictionary(door_row_variant).get("cell", Vector2i(-1, -1)))
			if door_cell.x < 0 or door_cell.y < 0:
				continue
			door_centers.append(grid_to_iso(door_cell))
		context["room_door_centers"] = door_centers
		var terminal_centers: Array[Vector2] = []
		for terminal_row_variant in Array(room_visual_preview.get("terminals", [])):
			var terminal_cell: Vector2i = Vector2i(Dictionary(terminal_row_variant).get("cell", Vector2i(-1, -1)))
			if terminal_cell.x < 0 or terminal_cell.y < 0:
				continue
			terminal_centers.append(grid_to_iso(terminal_cell))
		context["room_terminal_centers"] = terminal_centers
		var floor_point_sets: Array[PackedVector2Array] = []
		for floor_row_variant in Array(room_visual_preview.get("floors", [])):
			var floor_cell: Vector2i = Vector2i(Dictionary(floor_row_variant).get("cell", Vector2i(-1, -1)))
			if floor_cell.x < 0 or floor_cell.y < 0:
				continue
			floor_point_sets.append(get_iso_inset_diamond_points(floor_cell, iso_floor_visual_inset + 5.0))
		context["room_floor_point_sets"] = floor_point_sets
	if bool(map_constructor_overlay_prefs.get("show_multi_select", true)):
		var multi_select_point_sets: Array[PackedVector2Array] = []
		for row_variant in Array(map_constructor_overlay_data.get("multi_select", [])):
			var cell: Vector2i = Vector2i(Dictionary(row_variant).get("cell", Vector2i(-1, -1)))
			if cell.x < 0 or cell.y < 0:
				continue
			multi_select_point_sets.append(get_iso_inset_diamond_points(cell, iso_floor_visual_inset + 10.0))
		context["multi_select_point_sets"] = multi_select_point_sets
	if bool(map_constructor_overlay_prefs.get("show_validation", true)):
		var validation_markers: Array[Dictionary] = []
		for issue_variant in Array(map_constructor_overlay_data.get("validation", [])):
			var issue: Dictionary = Dictionary(issue_variant)
			var cell: Vector2i = Vector2i(issue.get("cell", Vector2i(-1, -1)))
			if cell.x < 0 or cell.y < 0:
				continue
			validation_markers.append({"center": grid_to_iso(cell), "severity": str(issue.get("severity", "info")), "expected_invalid": bool(issue.get("expected_invalid", false))})
		context["validation_markers"] = validation_markers
	if bool(map_constructor_overlay_prefs.get("show_links", true)):
		var link_rows: Array[Dictionary] = []
		for link_variant in Array(map_constructor_overlay_data.get("links", [])):
			var link: Dictionary = Dictionary(link_variant)
			var from_cell: Vector2i = Vector2i(link.get("from_cell", Vector2i(-1, -1)))
			var to_cell: Vector2i = Vector2i(link.get("to_cell", Vector2i(-1, -1)))
			if from_cell.x < 0 or to_cell.x < 0:
				continue
			link_rows.append({"start": grid_to_iso(from_cell), "end": grid_to_iso(to_cell), "broken": bool(link.get("broken", false))})
		context["links"] = link_rows
	if bool(map_constructor_overlay_prefs.get("show_power", true)):
		var power_rows: Array[Dictionary] = []
		for prow_variant in Array(map_constructor_overlay_data.get("power", [])):
			var prow: Dictionary = Dictionary(prow_variant)
			var f: Vector2i = Vector2i(prow.get("from_cell", Vector2i(-1, -1)))
			var t: Vector2i = Vector2i(prow.get("to_cell", Vector2i(-1, -1)))
			if f.x < 0 or t.x < 0:
				continue
			power_rows.append({"start": grid_to_iso(f), "end": grid_to_iso(t)})
		context["power_links"] = power_rows
	if bool(map_constructor_overlay_prefs.get("show_wall_side_arrows", true)):
		var wall_side_arrows: Array[Dictionary] = []
		if str(preview.get("wall_side", "")) != "" and map_constructor_preview_cell.x >= 0:
			wall_side_arrows.append({"center": grid_to_iso(map_constructor_preview_cell), "wall_side": str(preview.get("wall_side", "")), "mode": "preview"})
		if str(selected.get("wall_side", "")) != "":
			wall_side_arrows.append({"center": grid_to_iso(Vector2i(selected.get("cell", Vector2i(-1, -1)))), "wall_side": str(selected.get("wall_side", "")), "mode": "selected"})
		context["wall_side_arrows"] = wall_side_arrows
	return context

func draw_map_constructor_visual_overlay_passes() -> void:
	_draw_overlay_commands(MapConstructorOverlayRendererRef.build_commands(_build_map_constructor_overlay_context()))

const ISO_LAYER_BIAS_FLOOR: float = IsoDrawEntryContractRef.LAYER_BIAS_FLOOR
const ISO_LAYER_BIAS_CABLE: float = IsoDrawEntryContractRef.LAYER_BIAS_CABLE
const ISO_LAYER_BIAS_ITEM: float = IsoDrawEntryContractRef.LAYER_BIAS_ITEM
const ISO_LAYER_BIAS_DOOR: float = IsoDrawEntryContractRef.LAYER_BIAS_DOOR
const ISO_LAYER_BIAS_WALL: float = IsoDrawEntryContractRef.LAYER_BIAS_WALL
const ISO_LAYER_BIAS_WALL_MOUNTED: float = IsoDrawEntryContractRef.LAYER_BIAS_WALL_MOUNTED
const ISO_LAYER_BIAS_TERMINAL: float = IsoDrawEntryContractRef.LAYER_BIAS_TERMINAL
const ISO_LAYER_BIAS_ACTOR: float = IsoDrawEntryContractRef.LAYER_BIAS_ACTOR
const ISO_LAYER_BIAS_OVERLAY: float = IsoDrawEntryContractRef.LAYER_BIAS_OVERLAY

const ISO_DRAW_SUB_ORDER_FLOOR: float = IsoDrawEntryContractRef.SUB_ORDER_FLOOR
const ISO_DRAW_SUB_ORDER_GROUND: float = IsoDrawEntryContractRef.SUB_ORDER_GROUND
const ISO_DRAW_SUB_ORDER_PLATFORM_SURFACE: float = IsoDrawEntryContractRef.SUB_ORDER_PLATFORM_SURFACE
const ISO_DRAW_SUB_ORDER_CABLE: float = IsoDrawEntryContractRef.SUB_ORDER_CABLE
const ISO_DRAW_SUB_ORDER_ITEM: float = IsoDrawEntryContractRef.SUB_ORDER_ITEM
const ISO_DRAW_SUB_ORDER_DOOR: float = IsoDrawEntryContractRef.SUB_ORDER_DOOR
const ISO_DRAW_SUB_ORDER_WALL_BODY: float = IsoDrawEntryContractRef.SUB_ORDER_WALL_BODY
const ISO_DRAW_SUB_ORDER_WALL_TOP: float = IsoDrawEntryContractRef.SUB_ORDER_WALL_TOP
const ISO_DRAW_SUB_ORDER_WALL_MOUNTED: float = IsoDrawEntryContractRef.SUB_ORDER_WALL_MOUNTED
const ISO_DRAW_SUB_ORDER_TERMINAL: float = IsoDrawEntryContractRef.SUB_ORDER_TERMINAL
const ISO_DRAW_SUB_ORDER_OVERLAY: float = IsoDrawEntryContractRef.SUB_ORDER_OVERLAY

func get_iso_depth_key(cell: Vector2i, local_bias: float = 0.0) -> float:
	return IsoProjectionServiceRef.get_depth_key(cell, iso_origin, get_iso_tile_half_size(), local_bias)

func get_iso_floor_depth_key(cell: Vector2i) -> float:
	return IsoProjectionServiceRef.get_depth_key(cell, iso_origin, get_iso_tile_half_size())

func get_iso_wall_depth_key_for_cell(cell: Vector2i) -> float:
	return WallRendererRef.get_depth_key_for_cell(_grid_manager, cell, iso_origin, get_iso_tile_half_size(), iso_wall_visual_inset)

func get_iso_object_depth_key_for_payload(payload: Dictionary) -> float:
	var object_cell: Vector2i = Vector2i(payload.get("object_cell", Vector2i.ZERO))
	var object_data: Dictionary = Dictionary(payload.get("object_data", {}))
	if object_data.is_empty():
		return get_iso_floor_depth_key(object_cell)
	if is_wall_mounted_runtime_object(object_data) or is_wall_procedural_routed_object(object_data):
		var attached_wall_cell: Vector2i = _try_parse_cell_variant(object_data.get("attached_wall_cell", object_cell), object_cell)
		return get_iso_wall_depth_key_for_cell(attached_wall_cell)
	var grounding_profile: Dictionary = get_iso_object_grounding_profile(object_data, object_cell)
	var anchor_cell: Vector2i = Vector2i(grounding_profile.get("anchor_cell", object_cell))
	return get_iso_floor_depth_key(anchor_cell)

func sort_iso_draw_entries(a: Dictionary, b: Dictionary) -> bool:
	var fallback_a: float = get_iso_depth_key(Vector2i(a.get("cell", Vector2i.ZERO)))
	var fallback_b: float = get_iso_depth_key(Vector2i(b.get("cell", Vector2i.ZERO)))
	return IsoDrawEntryContractRef.less(a, b, fallback_a, fallback_b)

func sort_cells_by_iso_depth(a: Vector2i, b: Vector2i) -> bool:
	return IsoProjectionServiceRef.sort_cells_by_depth(a, b, iso_origin, get_iso_tile_half_size())

func is_floor_like_tile(tile_type: int) -> bool:
	return FloorRendererRef.is_floor_like_tile(tile_type)

func is_wall_tile(tile_type: int) -> bool:
	return WallRendererRef.is_wall_tile(tile_type)

func is_door_like_tile(tile_type: int) -> bool:
	if tile_type == GridManager.TILE_DOOR:
		return true
	if tile_type == GridManager.TILE_DIGITAL_DOOR:
		return true
	if tile_type == GridManager.TILE_POWERED_GATE:
		return true
	return false

func is_door_like_object_data(object_data: Dictionary) -> bool:
	var profile_key: String = get_iso_object_profile_key_for_object_data(object_data, "")
	if profile_key == "door" or profile_key == "digital_door" or profile_key == "powered_gate":
		return true
	var object_type: String = str(object_data.get("object_type", object_data.get("item_type", object_data.get("type", "")))).strip_edges().to_lower()
	var catalog_id: String = str(object_data.get("catalog_id", object_data.get("id", object_data.get("object_id", "")))).strip_edges().to_lower()
	var prefab_id: String = str(object_data.get("map_constructor_prefab_id", object_data.get("prefab", object_data.get("profile", "")))).strip_edges().to_lower()
	var blob: String = "%s %s %s %s" % [profile_key, object_type, catalog_id, prefab_id]
	return blob.contains("door") or blob.contains("powered_gate")

func _get_door_opening_polygon(center: Vector2, orientation: String, half_length: float, half_depth: float) -> PackedVector2Array:
	if orientation == "axis_y":
		return PackedVector2Array([
			center + Vector2(-half_depth, -half_length * 0.5),
			center + Vector2(half_length, -half_depth),
			center + Vector2(half_depth, half_length * 0.5),
			center + Vector2(-half_length, half_depth)
		])
	return PackedVector2Array([
		center + Vector2(-half_length, -half_depth),
		center + Vector2(half_depth, -half_length * 0.5),
		center + Vector2(half_length, half_depth),
		center + Vector2(-half_depth, half_length * 0.5)
	])

func get_door_opening_context(cell: Vector2i) -> Dictionary:
	var empty_context: Dictionary = {
		"ok": false,
		"cell": cell,
		"tile_type": -1,
		"orientation": "unknown",
		"adjacent_wall_cells": [],
		"adjacent_floor_cells": [],
		"left_jamb_cell": Vector2i(-1, -1),
		"right_jamb_cell": Vector2i(-1, -1),
		"has_wall_support": false,
		"opening_center": grid_to_iso(cell),
		"door_insert_center": grid_to_iso(cell) + Vector2(0.0, -iso_wall_height * 0.42),
		"door_frame_polygon": PackedVector2Array(),
		"threshold_polygon": PackedVector2Array()
	}
	if _grid_manager == null:
		return empty_context
	if not is_cell_in_bounds(cell):
		return empty_context
	var tile_type: int = _grid_manager.get_tile(cell)
	if not is_door_like_tile(tile_type):
		return empty_context
	var adjacent_wall_cells: Array[Vector2i] = []
	var adjacent_floor_cells: Array[Vector2i] = []
	var east_cell: Vector2i = cell + Vector2i(1, 0)
	var west_cell: Vector2i = cell + Vector2i(-1, 0)
	var north_cell: Vector2i = cell + Vector2i(0, -1)
	var south_cell: Vector2i = cell + Vector2i(0, 1)
	var neighbor_cells: Array[Vector2i] = [east_cell, west_cell, north_cell, south_cell]
	for neighbor_cell in neighbor_cells:
		if not is_cell_in_bounds(neighbor_cell):
			continue
		var neighbor_tile: int = _grid_manager.get_tile(neighbor_cell)
		if is_wall_tile(neighbor_tile):
			adjacent_wall_cells.append(neighbor_cell)
		else:
			adjacent_floor_cells.append(neighbor_cell)
	var has_east_wall: bool = is_cell_in_bounds(east_cell) and is_wall_tile(_grid_manager.get_tile(east_cell))
	var has_west_wall: bool = is_cell_in_bounds(west_cell) and is_wall_tile(_grid_manager.get_tile(west_cell))
	var has_north_wall: bool = is_cell_in_bounds(north_cell) and is_wall_tile(_grid_manager.get_tile(north_cell))
	var has_south_wall: bool = is_cell_in_bounds(south_cell) and is_wall_tile(_grid_manager.get_tile(south_cell))
	var axis_x_support: int = (1 if has_east_wall else 0) + (1 if has_west_wall else 0)
	var axis_y_support: int = (1 if has_north_wall else 0) + (1 if has_south_wall else 0)
	var orientation: String = "unknown"
	if axis_x_support > axis_y_support:
		orientation = "axis_x"
	elif axis_y_support > axis_x_support:
		orientation = "axis_y"
	elif axis_x_support > 0 and axis_y_support > 0:
		orientation = "axis_x"
	elif axis_x_support > 0:
		orientation = "axis_x"
	elif axis_y_support > 0:
		orientation = "axis_y"
	var left_jamb_cell: Vector2i = Vector2i(-1, -1)
	var right_jamb_cell: Vector2i = Vector2i(-1, -1)
	if orientation == "axis_y":
		left_jamb_cell = north_cell
		right_jamb_cell = south_cell
	else:
		left_jamb_cell = west_cell
		right_jamb_cell = east_cell
	var opening_center: Vector2 = grid_to_iso(cell) + Vector2(0.0, -iso_wall_height * 0.28)
	var door_insert_center: Vector2 = grid_to_iso(cell) + Vector2(0.0, -iso_wall_height * 0.46)
	var door_frame_polygon: PackedVector2Array = _get_door_opening_polygon(door_insert_center, orientation, get_iso_tile_half_size().x * 0.34, iso_wall_height * 0.34)
	var threshold_polygon: PackedVector2Array = _get_door_opening_polygon(grid_to_iso(cell) + Vector2(0.0, -2.0), orientation, get_iso_tile_half_size().x * 0.42, get_iso_tile_half_size().y * 0.2)
	return {
		"ok": true,
		"cell": cell,
		"tile_type": tile_type,
		"orientation": orientation,
		"adjacent_wall_cells": adjacent_wall_cells,
		"adjacent_floor_cells": adjacent_floor_cells,
		"left_jamb_cell": left_jamb_cell,
		"right_jamb_cell": right_jamb_cell,
		"has_wall_support": adjacent_wall_cells.size() > 0,
		"opening_center": opening_center,
		"door_insert_center": door_insert_center,
		"door_frame_polygon": door_frame_polygon,
		"threshold_polygon": threshold_polygon
	}

func should_skip_full_wall_for_door_opening(cell: Vector2i) -> bool:
	if _grid_manager == null:
		return false
	if not is_cell_in_bounds(cell):
		return false
	return is_door_like_tile(_grid_manager.get_tile(cell))

func _get_door_kind_for_tile(tile_type: int) -> String:
	if tile_type == GridManager.TILE_DIGITAL_DOOR:
		return "digital_door"
	if tile_type == GridManager.TILE_POWERED_GATE:
		return "powered_gate"
	return "mechanical_door"

func get_iso_door_opening_visual_profile(cell: Vector2i, object_data: Dictionary = {}) -> Dictionary:
	var tile_type: int = GridManager.TILE_DOOR
	if _grid_manager != null and is_cell_in_bounds(cell):
		tile_type = _grid_manager.get_tile(cell)
	var door_kind: String = _get_door_kind_for_tile(tile_type)
	var door_state: String = str(object_data.get("state", object_data.get("visual_state", "closed"))).to_lower().strip_edges()
	var object_id: String = str(object_data.get("id", object_data.get("object_id", ""))).strip_edges()
	var mission_manager: Node = get_mission_manager_ref()
	if not object_id.is_empty() and mission_manager != null and mission_manager.has_method("get_map_constructor_door_visual_state"):
		var resolved_state: Dictionary = Dictionary(mission_manager.call("get_map_constructor_door_visual_state", object_id))
		if bool(resolved_state.get("ok", false)):
			door_state = str(resolved_state.get("state", door_state)).to_lower().strip_edges()
	if bool(object_data.get("is_open", object_data.get("open", false))):
		door_state = "open"
	if bool(object_data.get("is_locked", object_data.get("locked", false))):
		door_state = "locked"
	if bool(object_data.get("damaged", object_data.get("broken", false))):
		door_state = "damaged"
	if door_state == "broken" or door_state == "jammed" or door_state == "destroyed":
		door_state = "damaged"
	if door_state.is_empty() or not (door_state in ["open", "closed", "locked", "powered", "unpowered", "damaged"]):
		door_state = "closed"
	var base_color: Color = Color(0.27, 0.24, 0.22, 0.96)
	var frame_color: Color = Color(0.12, 0.14, 0.16, 0.98)
	var accent_color: Color = Color(0.88, 0.72, 0.36, 0.98)
	var warning_color: Color = Color(1.0, 0.3, 0.22, 0.98)
	var threshold_color: Color = Color(0.16, 0.18, 0.2, 0.82)
	var alpha: float = 0.96
	if door_kind == "digital_door":
		base_color = Color(0.13, 0.2, 0.28, 0.96)
		accent_color = Color(0.38, 0.88, 1.0, 0.98)
	elif door_kind == "powered_gate":
		base_color = Color(0.09, 0.14, 0.2, 0.9)
		accent_color = Color(0.48, 0.96, 1.0, 0.98)
	if door_state == "open":
		alpha = 0.38
		base_color = base_color.darkened(0.18)
		accent_color = Color(0.58, 0.9, 0.98, 0.92)
	elif door_state == "locked":
		accent_color = Color(1.0, 0.72, 0.22, 0.99)
		warning_color = Color(1.0, 0.86, 0.24, 0.99)
	elif door_state == "powered":
		accent_color = Color(0.32, 0.92, 1.0, 0.99)
	elif door_state == "unpowered":
		base_color = Color(0.18, 0.19, 0.21, 0.86)
		accent_color = Color(0.48, 0.54, 0.58, 0.86)
		alpha = 0.72
	elif door_state == "damaged":
		accent_color = Color(1.0, 0.34, 0.22, 0.99)
		warning_color = Color(1.0, 0.18, 0.12, 0.99)
	return {
		"door_state": door_state,
		"door_kind": door_kind,
		"base_color": base_color,
		"frame_color": frame_color,
		"accent_color": accent_color,
		"warning_color": warning_color,
		"threshold_color": threshold_color,
		"alpha": alpha,
		"frame_enabled": true,
		"threshold_enabled": true,
		"state_badge_enabled": door_state != "closed",
		"damage_overlay_enabled": door_state == "damaged"
	}

func get_floor_prototype_color(tile_type: int, cell: Vector2i) -> Color:
	return FloorRendererRef.get_prototype_color(tile_type, cell)

func is_walkable_floor_like_for_iso_passage(tile_type: int) -> bool:
	return FloorRendererRef.is_walkable_floor_like_for_passage(tile_type)

func is_cell_in_bounds(cell: Vector2i) -> bool:
	if _grid_manager == null:
		return false
	return _grid_manager.is_in_bounds(cell)

func is_iso_interactive_floor_tile(tile_type: int) -> bool:
	return FloorRendererRef.is_interactive_floor_tile(tile_type)

func is_iso_passage_floor_cell(cell: Vector2i) -> bool:
	return FloorRendererRef.is_passage_floor_cell(_grid_manager, cell)

func get_iso_floor_visual_profile_key_for_cell(cell: Vector2i) -> String:
	return FloorRendererRef.get_visual_profile_key_for_cell(_grid_manager, cell)

func get_iso_floor_material_family_for_cell(cell: Vector2i) -> String:
	return FloorRendererRef.get_material_family_for_cell(_grid_manager, cell)

func should_draw_floor_cell_border(cell: Vector2i) -> bool:
	# Visual-only seam policy. Interior same-family floor cells suppress their
	# strong diamond border so rooms read as one continuous surface. Boundary,
	# wall, and doorway threshold edges retain local definition.
	if _grid_manager == null or not is_cell_in_bounds(cell):
		return false
	var tile_type: int = _grid_manager.get_tile(cell)
	if not is_floor_like_tile(tile_type):
		return false
	var family: String = get_iso_floor_material_family_for_cell(cell)
	for side in WALL_SIDE_ORDER:
		var neighbor: Vector2i = cell + _get_wall_side_delta(side)
		if not is_cell_in_bounds(neighbor):
			return true
		var neighbor_tile: int = _grid_manager.get_tile(neighbor)
		if not is_floor_like_tile(neighbor_tile):
			return true
		var neighbor_family: String = get_iso_floor_material_family_for_cell(neighbor)
		if neighbor_family != family:
			return true
	return false

func should_draw_floor_edge_border(cell: Vector2i, side: String) -> bool:
	if _grid_manager == null or not is_cell_in_bounds(cell):
		return false
	var tile_type: int = _grid_manager.get_tile(cell)
	if not is_floor_like_tile(tile_type):
		return false
	var neighbor: Vector2i = cell + _get_wall_side_delta(side)
	if not is_cell_in_bounds(neighbor):
		return true
	var neighbor_tile: int = _grid_manager.get_tile(neighbor)
	if not is_floor_like_tile(neighbor_tile):
		return true
	var family: String = get_iso_floor_material_family_for_cell(cell)
	var neighbor_family: String = get_iso_floor_material_family_for_cell(neighbor)
	return neighbor_family != family

func get_iso_diamond_edge_points(points: PackedVector2Array, side: String) -> Array[Vector2]:
	var edge_points: Array[Vector2] = []
	if points.size() < 4:
		return edge_points
	match side:
		"north":
			edge_points.append(points[3])
			edge_points.append(points[0])
		"east":
			edge_points.append(points[0])
			edge_points.append(points[1])
		"south":
			edge_points.append(points[1])
			edge_points.append(points[2])
		"west":
			edge_points.append(points[2])
			edge_points.append(points[3])
	return edge_points

func get_iso_floor_visual_profile(profile_key: String) -> Dictionary:
	return FloorRendererRef.get_visual_profile(profile_key)

func get_iso_door_visual_profile_key_for_tile(tile_type: int) -> String:
	if tile_type == GridManager.TILE_DOOR:
		return "door_mechanical"
	if tile_type == GridManager.TILE_DIGITAL_DOOR:
		return "door_digital"
	if tile_type == GridManager.TILE_POWERED_GATE:
		return "door_powered_gate"
	return ""

func normalize_floor_material_key(material_key: String) -> String:
	return FloorRendererRef.normalize_material_key(material_key)

func get_iso_floor_asset_key_for_material_key(material_key: String) -> String:
	return FloorRendererRef.get_asset_key_for_material_key(material_key, use_gray_room_visual_test_assets)

func get_iso_floor_asset_key_for_tile(tile_type: int) -> String:
	return FloorRendererRef.get_asset_key_for_tile(tile_type, use_gray_room_visual_test_assets)

func get_iso_floor_asset_key_for_visual_height(value: String) -> String:
	return FloorRendererRef.get_asset_key_for_visual_height(value)

func get_iso_floor_asset_key_for_visual_state(cell: Vector2i) -> String:
	return FloorRendererRef.get_asset_key_for_visual_state(_grid_manager, cell)

func get_iso_floor_texture_for_asset_key(asset_key: String) -> Texture2D:
	var normalized_asset_key: String = str(asset_key).strip_edges().to_lower()
	if normalized_asset_key.is_empty():
		return null

	var known_floor_asset: bool = ISO_FLOOR_ASSET_CATALOG.has(normalized_asset_key)
	var known_ground_asset: bool = ISO_GROUND_ASSET_CATALOG.has(normalized_asset_key)
	var known_test_asset: bool = normalized_asset_key == ISO_FLOOR_TEST_ASSET_KEY
	if not known_floor_asset and not known_ground_asset and not known_test_asset:
		return null

	if _iso_floor_asset_texture_cache.has(normalized_asset_key):
		var cached_value: Variant = _iso_floor_asset_texture_cache.get(normalized_asset_key)
		if cached_value is Texture2D:
			return cached_value as Texture2D
		return null

	var texture_path: String = VisualAssetCatalogScript.get_asset_path(normalized_asset_key)
	if texture_path.is_empty():
		_iso_floor_asset_texture_cache[normalized_asset_key] = null
		return null

	if ResourceLoader.exists(texture_path):
		var loaded_resource: Resource = ResourceLoader.load(texture_path)
		if loaded_resource is Texture2D:
			var loaded_texture: Texture2D = loaded_resource as Texture2D
			_iso_floor_asset_texture_cache[normalized_asset_key] = loaded_texture
			return loaded_texture

	_iso_floor_asset_texture_cache[normalized_asset_key] = null
	return null

func get_iso_floor_asset_placement(asset_key: String) -> Dictionary:
	return FloorRendererRef.get_asset_placement(asset_key, get_iso_tile_size())

func normalize_floor_height_level(value: String) -> String:
	return FloorRendererRef.normalize_height_level(value)

func get_iso_ground_asset_key_for_floor_height(floor_height: String) -> String:
	return FloorRendererRef.get_ground_asset_key_for_floor_height(floor_height)

func get_iso_ground_texture_for_asset_key(asset_key: String) -> Texture2D:
	var normalized_asset_key: String = str(asset_key).strip_edges().to_lower()
	if normalized_asset_key.is_empty():
		return null

	if not ISO_GROUND_ASSET_CATALOG.has(normalized_asset_key):
		return null

	if _iso_ground_asset_texture_cache.has(normalized_asset_key):
		var cached_value: Variant = _iso_ground_asset_texture_cache.get(normalized_asset_key)
		if cached_value is Texture2D:
			return cached_value as Texture2D
		return null

	var texture_path: String = VisualAssetCatalogScript.get_asset_path(normalized_asset_key)
	if texture_path.is_empty():
		_iso_ground_asset_texture_cache[normalized_asset_key] = null
		return null

	if ResourceLoader.exists(texture_path):
		var loaded_resource: Resource = ResourceLoader.load(texture_path)
		if loaded_resource is Texture2D:
			var loaded_texture: Texture2D = loaded_resource as Texture2D
			_iso_ground_asset_texture_cache[normalized_asset_key] = loaded_texture
			return loaded_texture

	_iso_ground_asset_texture_cache[normalized_asset_key] = null
	return null

func get_iso_ground_texture_draw_rect_for_cell(cell: Vector2i, texture: Texture2D, asset_key: String) -> Rect2:
	var placement: Dictionary = Dictionary(ISO_GROUND_ASSET_PLACEMENT.get(asset_key, {}))
	if placement.is_empty():
		placement = {"visible_bounds": Rect2(Vector2.ZERO, texture.get_size()), "target_base_width": get_iso_tile_size().x, "scale": 1.0, "offset": Vector2.ZERO}
	return IsoVisualAlignmentServiceRef.get_ground_destination_rect(grid_to_iso(cell), get_iso_tile_size(), texture.get_size(), placement)

func draw_iso_ground_asset_texture_for_cell(cell: Vector2i, asset_key: String) -> bool:
	if asset_key.is_empty():
		return false
	var texture: Texture2D = get_iso_ground_texture_for_asset_key(asset_key)
	if texture == null:
		return false
	var destination_rect: Rect2 = get_iso_ground_texture_draw_rect_for_cell(cell, texture, asset_key)
	if destination_rect.size.x <= 0.0 or destination_rect.size.y <= 0.0:
		return false
	draw_texture_rect(texture, destination_rect, false)
	draw_iso_asset_alignment_overlay(asset_key, destination_rect.position + Vector2(destination_rect.size.x * 0.5, destination_rect.size.y), destination_rect)
	return true

func draw_iso_floor_asset_safe_base(cell: Vector2i, color: Color, surface_y_offset: float = 0.0) -> void:
	var base_points: PackedVector2Array = get_iso_diamond_points_with_overlap(cell, ISO_FLOOR_UNDERLAY_OVERLAP)
	if not is_zero_approx(surface_y_offset):
		var shifted_points: PackedVector2Array = PackedVector2Array()
		for point in base_points:
			shifted_points.append(point + Vector2(0.0, surface_y_offset))
		base_points = shifted_points
	draw_colored_polygon(base_points, color)

func draw_missing_iso_asset_debug_fallback(cell: Vector2i, asset_key: String, destination_rect: Rect2) -> void:
	if destination_rect.size.x <= 0.0 or destination_rect.size.y <= 0.0:
		return
	var checker_color_a: Color = Color(1.0, 0.0, 0.85, 0.62)
	var checker_color_b: Color = Color(0.02, 0.02, 0.025, 0.74)
	var half_size: Vector2 = destination_rect.size * 0.5
	draw_rect(Rect2(destination_rect.position, half_size), checker_color_a, true)
	draw_rect(Rect2(destination_rect.position + Vector2(half_size.x, 0.0), half_size), checker_color_b, true)
	draw_rect(Rect2(destination_rect.position + Vector2(0.0, half_size.y), half_size), checker_color_b, true)
	draw_rect(Rect2(destination_rect.position + half_size, half_size), checker_color_a, true)
	draw_rect(destination_rect, Color(1.0, 0.05, 0.05, 0.95), false, 2.0)
	draw_line(destination_rect.position, destination_rect.position + destination_rect.size, Color(1.0, 0.05, 0.05, 0.95), 1.5)
	draw_line(destination_rect.position + Vector2(destination_rect.size.x, 0.0), destination_rect.position + Vector2(0.0, destination_rect.size.y), Color(1.0, 0.05, 0.05, 0.95), 1.5)
	draw_string(ThemeDB.fallback_font, destination_rect.position + Vector2(3.0, 11.0), "MISSING %s" % asset_key, HORIZONTAL_ALIGNMENT_LEFT, maxf(destination_rect.size.x - 6.0, 24.0), 9, Color(1.0, 0.95, 0.95, 0.98))
	draw_iso_asset_alignment_overlay(asset_key, grid_to_iso(cell), destination_rect)

func get_iso_floor_asset_destination_rect_for_cell(cell: Vector2i, asset_key: String, surface_y_offset: float = 0.0) -> Rect2:
	return IsoVisualAlignmentServiceRef.get_floor_destination_rect(grid_to_iso(cell), get_iso_tile_size(), get_iso_floor_asset_placement(asset_key), surface_y_offset)

func draw_iso_floor_asset_texture_for_cell(cell: Vector2i, asset_key: String, surface_y_offset: float = 0.0) -> bool:
	var texture: Texture2D = get_iso_floor_texture_for_asset_key(asset_key)
	var destination_rect: Rect2 = get_iso_floor_asset_destination_rect_for_cell(cell, asset_key, surface_y_offset)
	if texture == null:
		if use_gray_room_visual_test_assets and asset_key == ISO_FLOOR_TEST_ASSET_KEY:
			draw_missing_iso_asset_debug_fallback(cell, asset_key, destination_rect)
			return true
		return false
	var placement: Dictionary = get_iso_floor_asset_placement(asset_key)
	var visible_bounds_rect: Rect2 = IsoVisualAlignmentServiceRef.clamp_visible_bounds(Rect2(placement.get("visible_bounds", Rect2i(0, 0, texture.get_width(), texture.get_height()))), texture.get_size())
	var visible_bounds: Rect2i = Rect2i(int(visible_bounds_rect.position.x), int(visible_bounds_rect.position.y), int(visible_bounds_rect.size.x), int(visible_bounds_rect.size.y))
	if visible_bounds.size.x <= 0 or visible_bounds.size.y <= 0:
		return false
	if bool(placement.get("draw_safe_base", not use_gray_room_visual_test_assets)):
		draw_iso_floor_asset_safe_base(cell, Color(placement.get("fallback_color", Color(0.08, 0.085, 0.09, 0.96))), surface_y_offset)
	draw_texture_rect_region(texture, destination_rect, Rect2(Vector2(visible_bounds.position), Vector2(visible_bounds.size)))
	draw_iso_asset_alignment_overlay(asset_key, grid_to_iso(cell) + Vector2(0.0, surface_y_offset), destination_rect)
	return true

func get_ground_surface_y_offset_for_asset_key(asset_key: String) -> float:
	if asset_key.is_empty():
		return 0.0
	var texture: Texture2D = get_iso_ground_texture_for_asset_key(asset_key)
	if texture == null:
		return 0.0
	var placement: Dictionary = Dictionary(ISO_GROUND_ASSET_PLACEMENT.get(asset_key, {}))
	return IsoVisualAlignmentServiceRef.get_ground_top_surface_y_offset(get_iso_tile_size(), texture.get_size(), placement)

func get_cell_surface_y_offset_for_floor_height(floor_height_level: String) -> float:
	var ground_asset_key: String = get_iso_ground_asset_key_for_floor_height(floor_height_level)
	return get_ground_surface_y_offset_for_asset_key(ground_asset_key)

func get_ground_asset_key_for_cell(cell: Vector2i) -> String:
	return FloorRendererRef.get_ground_asset_key_for_cell(_grid_manager, get_mission_manager_ref(), cell)

func enrich_iso_object_surface_context_for_cell(object_data: Dictionary, cell: Vector2i) -> Dictionary:
	var enriched: Dictionary = object_data.duplicate(true)

	if enriched.has("ground_surface_y_offset"):
		return enriched

	var ground_asset_key: String = get_ground_asset_key_for_cell(cell) if has_method("get_ground_asset_key_for_cell") else ""
	if ground_asset_key.is_empty():
		return enriched

	var ground_texture: Texture2D = get_iso_ground_texture_for_asset_key(ground_asset_key) if has_method("get_iso_ground_texture_for_asset_key") else null
	if ground_texture == null:
		return enriched

	var placement: Dictionary = Dictionary(ISO_GROUND_ASSET_PLACEMENT.get(ground_asset_key, {}))
	var offset: float = IsoVisualAlignmentServiceRef.get_ground_top_surface_y_offset(
		get_iso_tile_size(),
		ground_texture.get_size(),
		placement
	)

	enriched["ground_surface_y_offset"] = offset
	return enriched

func draw_platform_floor_visual_for_cell(cell: Vector2i, platform_data: Dictionary, base_surface_y_offset: float = 0.0) -> bool:
	if use_gray_room_visual_test_assets or platform_data.is_empty() or not PlatformTypesRef.is_platform_data(platform_data):
		return false
	var descriptor: Dictionary = PlatformVisualServiceRef.get_platform_draw_descriptor(platform_data)
	var texture: Texture2D = get_iso_floor_texture_for_asset_key(str(descriptor.get("floor_asset_key", "platform_floor")))
	if texture == null:
		return false
	var platform_y_offset: float = base_surface_y_offset + float(descriptor.get("visual_y_offset", 0.0))
	var destination_rect: Rect2 = get_iso_floor_asset_destination_rect_for_cell(cell, "platform_floor", platform_y_offset)
	var platform_placement: Dictionary = get_iso_floor_asset_placement("platform_floor")
	var source_rect: Rect2 = IsoVisualAlignmentServiceRef.clamp_visible_bounds(Rect2(platform_placement.get("visible_bounds", Rect2(Vector2.ZERO, texture.get_size()))), texture.get_size())
	if str(descriptor.get("source_region_mode", "full_with_rim")) == "top_only_flush":
		# Level-0 platforms use the same authored top diamond footprint as floor tiles.
		source_rect = IsoVisualAlignmentServiceRef.clamp_visible_bounds(Rect2(0, 163, 512, 286), texture.get_size())
	else:
		var scale_value: float = destination_rect.size.x / maxf(source_rect.size.x, 1.0)
		destination_rect.size.y = source_rect.size.y * scale_value
	if bool(descriptor.get("is_flush", false)):
		draw_iso_floor_asset_safe_base(cell, Color(0.08, 0.085, 0.09, 0.96), base_surface_y_offset)
	draw_texture_rect_region(texture, destination_rect, source_rect)
	draw_iso_asset_alignment_overlay("platform_floor", grid_to_iso(cell) + Vector2(0.0, platform_y_offset), destination_rect)
	return true

func get_platform_data_for_floor_cell(cell: Vector2i) -> Dictionary:
	return _get_platform_data_for_cell(cell)

func _get_platform_data_for_cell(cell: Vector2i) -> Dictionary:
	var mission_manager: Node = get_mission_manager_ref()
	if mission_manager == null:
		return {}
	for object_variant in Array(mission_manager.get("mission_world_objects")):
		if not (object_variant is Dictionary):
			continue
		var object_data: Dictionary = Dictionary(object_variant)
		if not PlatformTypesRef.is_platform_data(object_data):
			continue
		for platform_cell_variant in Array(object_data.get("platform_cells", [object_data.get("position", Vector2i(-1, -1))])):
			if _try_parse_cell_variant(platform_cell_variant, Vector2i(-1, -1)) == cell:
				return object_data
		if _try_parse_cell_variant(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1)) == cell:
			return object_data
	return {}

func _get_platform_visual_y_offset_for_cell(cell: Vector2i) -> float:
	var platform_data: Dictionary = _get_platform_data_for_cell(cell)
	if platform_data.is_empty():
		return 0.0
	var ground_asset_key: String = get_ground_asset_key_for_cell(cell)
	var ground_y_offset: float = get_ground_surface_y_offset_for_asset_key(ground_asset_key)
	var descriptor: Dictionary = PlatformVisualServiceRef.get_platform_draw_descriptor(platform_data)
	return ground_y_offset + float(descriptor.get("visual_y_offset", 0.0))

func _with_platform_visual_surface_context(object_data: Dictionary, cell: Vector2i) -> Dictionary:
	if object_data.is_empty() or PlatformTypesRef.is_platform_data(object_data):
		return object_data
	var platform_data: Dictionary = _get_platform_data_for_cell(cell)
	if platform_data.is_empty():
		return object_data
	var enriched: Dictionary = object_data.duplicate(true)
	if bool(enriched.get("on_platform", false)) or not str(enriched.get("platform_id", enriched.get("carried_by_platform_id", ""))).strip_edges().is_empty() or _try_parse_cell_variant(enriched.get("platform_cell", cell), cell) == cell:
		var descriptor: Dictionary = PlatformVisualServiceRef.get_platform_draw_descriptor(platform_data)
		enriched["explicit_surface_y_offset"] = _get_platform_visual_y_offset_for_cell(cell)
		enriched["platform_height_level"] = int(round(float(descriptor.get("visual_level", enriched.get("platform_height_level", 0)))))
	return enriched

func _get_platform_occupants_for_cell(cell: Vector2i) -> Array[Dictionary]:
	var occupants: Array[Dictionary] = []
	var mission_manager: Node = get_mission_manager_ref()
	if mission_manager == null:
		return occupants
	var platform_data: Dictionary = _get_platform_data_for_cell(cell)
	if platform_data.is_empty():
		return occupants
	var platform_id: String = str(platform_data.get("platform_id", platform_data.get("id", ""))).strip_edges()
	for object_variant in Array(mission_manager.get("mission_world_objects")):
		if not (object_variant is Dictionary):
			continue
		var object_data: Dictionary = Dictionary(object_variant)
		if object_data.is_empty() or PlatformTypesRef.is_platform_data(object_data):
			continue
		if _try_parse_cell_variant(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1)) != cell:
			continue
		var object_platform_id: String = str(object_data.get("platform_id", object_data.get("carried_by_platform_id", ""))).strip_edges()
		var object_platform_cell: Vector2i = _try_parse_cell_variant(object_data.get("platform_cell", cell), cell)
		if bool(object_data.get("on_platform", false)) or (not platform_id.is_empty() and object_platform_id == platform_id) or object_platform_cell == cell:
			occupants.append(_with_platform_visual_surface_context(object_data, cell))
	return occupants

func get_iso_wall_asset_key_for_profile(profile_key: String) -> String:
	return WallRendererRef.normalize_asset_key(profile_key)

func get_iso_wall_asset_catalog() -> Dictionary:
	return WallRendererRef.get_asset_catalog()

func get_iso_gray_test_asset_path(asset_key: String) -> String:
	var normalized_asset_key: String = str(asset_key).strip_edges().to_lower()
	if normalized_asset_key.is_empty():
		return ""

	var catalog_path: String = VisualAssetCatalogScript.get_asset_path(normalized_asset_key)
	if catalog_path.find("/test/") >= 0:
		return catalog_path

	if normalized_asset_key == ISO_FLOOR_TEST_ASSET_KEY:
		return ISO_TEST_ASSET_PACK_DIR + str(ISO_FLOOR_ASSET_CATALOG.get(normalized_asset_key, ""))

	if ISO_WALL_ASSET_CATALOG.has(normalized_asset_key) and normalized_asset_key.begins_with("wall_gray_"):
		return ISO_TEST_ASSET_PACK_DIR + str(ISO_WALL_ASSET_CATALOG.get(normalized_asset_key, ""))

	return ""

func get_gray_room_visual_test_asset_validation() -> Dictionary:
	var assets: Dictionary = {}
	var missing: Array[String] = []
	var invalid: Array[String] = []
	for asset_key in ISO_GRAY_TEST_REQUIRED_ASSET_KEYS:
		var path: String = get_iso_gray_test_asset_path(asset_key)
		var exists: bool = not path.is_empty() and ResourceLoader.exists(path)
		var loads_as_texture: bool = false
		if exists:
			var loaded_resource: Resource = ResourceLoader.load(path)
			loads_as_texture = loaded_resource is Texture2D
		assets[asset_key] = {"path": path, "exists": exists, "loads_as_texture": loads_as_texture}
		if not exists:
			missing.append(asset_key)
		elif not loads_as_texture:
			invalid.append(asset_key)
	return {"ok": missing.is_empty() and invalid.is_empty(), "enabled": use_gray_room_visual_test_assets, "assets": assets, "missing": missing, "invalid": invalid, "fallback": "magenta_black_missing_asset_debug_checker"}


func normalize_wall_material_asset_base_key(profile_key: String) -> String:
	return WallRendererRef.normalize_material_asset_base_key(profile_key)

func normalize_wall_asset_key(profile_key: String) -> String:
	return WallRendererRef.normalize_asset_key(profile_key)

func get_iso_wall_explicit_texture_for_asset_key(asset_key: String) -> Texture2D:
	var base_key: String = normalize_wall_material_asset_base_key(asset_key)
	match base_key:
		"wall_concrete":
			return iso_wall_concrete_texture
		"wall_outer":
			return iso_wall_outer_texture
		"wall_brick":
			return iso_wall_brick_texture
		"wall_grate":
			return iso_wall_grate_texture
		"wall_steel", "wall_reinforced_steel", "wall_titan":
			return iso_wall_steel_texture
	return null

func get_iso_wall_texture_for_asset_key(asset_key: String) -> Texture2D:
	var normalized_key: String = normalize_wall_asset_key(asset_key)
	var catalog: Dictionary = get_iso_wall_asset_catalog()

	if catalog.has(normalized_key):
		if _iso_wall_asset_texture_cache.has(normalized_key):
			var cached_value: Variant = _iso_wall_asset_texture_cache.get(normalized_key)
			if cached_value is Texture2D:
				return cached_value as Texture2D
			return null

		var texture_path: String = VisualAssetCatalogScript.get_asset_path(normalized_key)
		if texture_path.is_empty():
			_iso_wall_asset_texture_cache[normalized_key] = null
			return null

		if ResourceLoader.exists(texture_path):
			var loaded_resource: Resource = ResourceLoader.load(texture_path)
			if loaded_resource is Texture2D:
				var loaded_texture: Texture2D = loaded_resource as Texture2D
				_iso_wall_asset_texture_cache[normalized_key] = loaded_texture
				return loaded_texture

		_iso_wall_asset_texture_cache[normalized_key] = null

	if normalized_key.begins_with("wall_gray_"):
		return null

	var explicit_texture: Texture2D = get_iso_wall_explicit_texture_for_asset_key(normalized_key)
	if explicit_texture != null:
		return explicit_texture

	if normalized_key != "wall_concrete_mid":
		return get_iso_wall_texture_for_asset_key("wall_concrete_mid")

	return null

func get_iso_wall_texture_for_profile(profile_key: String) -> Texture2D:
	return get_iso_wall_texture_for_asset_key(normalize_wall_asset_key(profile_key))

func get_iso_wall_material_base_key_for_material_row(material_row: Dictionary, fallback_profile_key: String) -> String:
	return WallRendererRef.get_material_base_key_for_row(material_row, fallback_profile_key)

func get_iso_wall_asset_key_for_material_row(material_row: Dictionary, fallback_profile_key: String) -> String:
	return WallRendererRef.get_asset_key_for_material_row(material_row, fallback_profile_key)

func normalize_test_wall_height(value: String) -> String:
	return WallRendererRef.normalize_test_height(value)

func normalize_wall_height_level(value: String) -> String:
	return WallRendererRef.normalize_height_level(value)

func normalize_wall_height_level_for_material(base_key: String, height_level: String) -> String:
	return WallRendererRef.normalize_height_for_material(base_key, height_level)

func get_wall_asset_key_for_material_and_height(material_asset_key: String, height_level: String) -> String:
	return WallRendererRef.get_asset_key_for_material_and_height(material_asset_key, height_level)

func get_raw_wall_height_value(wall_data: Dictionary) -> String:
	return WallRendererRef.get_raw_height_value(wall_data)

func get_iso_wall_depth_bounds() -> Dictionary:
	return WallRendererRef.get_depth_bounds(_grid_manager)

func resolve_auto_test_wall_height(cell: Vector2i, map_bounds: Dictionary = {}) -> String:
	return WallRendererRef.resolve_auto_test_height(cell, map_bounds if not map_bounds.is_empty() else get_iso_wall_depth_bounds())

func resolve_outer_wall_height_level(cell: Vector2i, map_bounds: Dictionary = {}) -> String:
	return WallRendererRef.resolve_outer_height(cell, map_bounds if not map_bounds.is_empty() else get_iso_wall_depth_bounds())

func get_production_wall_height_level(wall_data: Dictionary, cell: Vector2i, material_asset_key: String, map_bounds: Dictionary = {}) -> String:
	return WallRendererRef.get_production_height_level(wall_data, cell, material_asset_key, map_bounds if not map_bounds.is_empty() else get_iso_wall_depth_bounds())

func get_production_wall_asset_key(wall_data: Dictionary, cell: Vector2i, fallback_profile_key: String, map_bounds: Dictionary = {}) -> String:
	return WallRendererRef.get_production_asset_key(wall_data, cell, fallback_profile_key, map_bounds if not map_bounds.is_empty() else get_iso_wall_depth_bounds())

func get_test_wall_height_asset_key(wall_data: Dictionary, cell: Vector2i, map_bounds: Dictionary = {}) -> String:
	return WallRendererRef.get_test_height_asset_key(wall_data, cell, map_bounds if not map_bounds.is_empty() else get_iso_wall_depth_bounds())

func get_iso_wall_asset_placement(asset_key: String, source_size: Vector2) -> Dictionary:
	return WallRendererRef.get_asset_placement(asset_key, source_size, get_iso_tile_size())

func get_iso_wall_texture_draw_rect_for_cell(cell: Vector2i, texture: Texture2D, profile_key: String, _topology: Dictionary) -> Rect2:
	var source_size: Vector2 = texture.get_size()
	if source_size.x <= 0.0 or source_size.y <= 0.0:
		return Rect2()
	var asset_key: String = normalize_wall_asset_key(profile_key)
	var placement: Dictionary = get_iso_wall_asset_placement(asset_key, source_size)
	var visible_bounds: Rect2 = Rect2(placement.get("visible_bounds", Rect2(Vector2.ZERO, source_size)))
	if visible_bounds.size.x <= 0.0 or visible_bounds.size.y <= 0.0:
		visible_bounds = Rect2(Vector2.ZERO, source_size)
	var target_base_width: float = maxf(float(placement.get("target_base_width", get_iso_tile_size().x)), get_iso_tile_size().x)
	var placement_scale: float = maxf(float(placement.get("scale", 1.0)), 0.01)
	var scale_value: float = (target_base_width / visible_bounds.size.x) * placement_scale
	var destination_size: Vector2 = source_size * scale_value
	var visible_bottom_center_in_source: Vector2 = visible_bounds.position + Vector2(visible_bounds.size.x * 0.5, visible_bounds.size.y)
	var visible_bottom_center_in_destination: Vector2 = visible_bottom_center_in_source * scale_value
	var base_anchor: Vector2 = (grid_to_iso(cell) + Vector2(0.0, get_iso_tile_half_size().y) + Vector2(placement.get("offset", Vector2.ZERO))).round()
	return Rect2((base_anchor - visible_bottom_center_in_destination).round(), destination_size)

func should_mirror_iso_wall_asset_for_topology(topology: Dictionary) -> bool:
	return WallRendererRef.should_mirror_asset_for_topology(topology)

func get_iso_wall_visible_source_rect(asset_key: String, texture: Texture2D) -> Rect2:
	var source_size: Vector2 = texture.get_size()
	var placement: Dictionary = get_iso_wall_asset_placement(asset_key, source_size)
	var visible_bounds: Rect2 = Rect2(placement.get("visible_bounds", Rect2(Vector2.ZERO, source_size)))
	if visible_bounds.size.x <= 0.0 or visible_bounds.size.y <= 0.0:
		return Rect2(Vector2.ZERO, source_size)
	return visible_bounds

func get_iso_wall_visible_destination_rect(texture_rect: Rect2, source_rect: Rect2, texture: Texture2D) -> Rect2:
	var texture_size: Vector2 = texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return Rect2()
	var scale_value: Vector2 = Vector2(texture_rect.size.x / texture_size.x, texture_rect.size.y / texture_size.y)
	return Rect2(texture_rect.position + source_rect.position * scale_value, source_rect.size * scale_value)

func draw_iso_wall_asset_texture_rect(texture: Texture2D, texture_rect: Rect2, source_rect: Rect2, mirror_x: bool) -> Rect2:
	var destination_rect: Rect2 = get_iso_wall_visible_destination_rect(texture_rect, source_rect, texture)
	if destination_rect.size.x <= 0.0 or destination_rect.size.y <= 0.0:
		return Rect2()
	if not mirror_x:
		draw_texture_rect_region(texture, destination_rect, source_rect)
		return destination_rect
	var center: Vector2 = destination_rect.position + destination_rect.size * 0.5
	draw_set_transform(center, 0.0, Vector2(-1.0, 1.0))
	draw_texture_rect_region(texture, Rect2(destination_rect.size * -0.5, destination_rect.size), source_rect)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	return destination_rect

func draw_iso_wall_asset_texture_for_cell(cell: Vector2i, profile_key: String, topology: Dictionary) -> bool:
	var asset_key: String = normalize_wall_asset_key(profile_key)
	var texture: Texture2D = get_iso_wall_texture_for_profile(asset_key)
	var debug_destination_rect: Rect2 = Rect2(grid_to_iso(cell) - Vector2(get_iso_tile_size().x * 0.5, get_iso_tile_size().y + iso_wall_height), Vector2(get_iso_tile_size().x, get_iso_tile_size().y + iso_wall_height))
	if texture == null:
		if use_gray_room_visual_test_assets and asset_key.begins_with("wall_gray_"):
			draw_missing_iso_asset_debug_fallback(cell, asset_key, debug_destination_rect)
			return true
		return false
	var texture_rect: Rect2 = get_iso_wall_texture_draw_rect_for_cell(cell, texture, asset_key, topology)
	if texture_rect.size.x <= 0.0 or texture_rect.size.y <= 0.0:
		return false
	var source_rect: Rect2 = get_iso_wall_visible_source_rect(asset_key, texture)
	var drawn_rect: Rect2 = draw_iso_wall_asset_texture_rect(texture, texture_rect, source_rect, should_mirror_iso_wall_asset_for_topology(topology))
	if drawn_rect.size.x <= 0.0 or drawn_rect.size.y <= 0.0:
		return false
	draw_iso_asset_alignment_overlay(asset_key, drawn_rect.position + Vector2(drawn_rect.size.x * 0.5, drawn_rect.size.y), drawn_rect)
	return true

func normalize_breach_side(value: String) -> String:
	return BreachableWallServiceRef.normalize_breach_side(value)

func get_breach_grid_side_for_visual_side(breach_side: String) -> String:
	match normalize_breach_side(breach_side):
		"sw":
			return "south"
		"se":
			return "east"
		"nw":
			return "west"
		"ne":
			return "north"
	return "south"

func is_breachable_wall_material_id(material_id: String) -> bool:
	return WallRendererRef.is_breachable_material_id(material_id)

func get_breach_overlay_asset_key(base_material: String) -> String:
	var base_key: String = normalize_wall_material_asset_base_key(base_material)
	match base_key:
		"wall_concrete":
			return "breach_overlay_concrete_sw"
		"wall_brick":
			return "breach_overlay_brick_sw"
	return ""

func get_breach_overlay_texture_for_asset_key(asset_key: String) -> Texture2D:
	var normalized_key: String = str(asset_key).strip_edges().to_lower()
	if normalized_key.is_empty():
		return null

	if not ISO_WALL_BREACH_OVERLAY_CATALOG.has(normalized_key):
		return null

	if _iso_wall_breach_overlay_texture_cache.has(normalized_key):
		var cached_value: Variant = _iso_wall_breach_overlay_texture_cache.get(normalized_key)
		if cached_value is Texture2D:
			return cached_value as Texture2D
		return null

	var texture_path: String = VisualAssetCatalogScript.get_asset_path(normalized_key)
	if texture_path.is_empty():
		_iso_wall_breach_overlay_texture_cache[normalized_key] = null
		return null

	if ResourceLoader.exists(texture_path):
		var loaded_resource: Resource = ResourceLoader.load(texture_path)
		if loaded_resource is Texture2D:
			var loaded_texture: Texture2D = loaded_resource as Texture2D
			_iso_wall_breach_overlay_texture_cache[normalized_key] = loaded_texture
			return loaded_texture

	_iso_wall_breach_overlay_texture_cache[normalized_key] = null
	return null

func get_breach_overlay_transform_for_side(side: String, height_level: String = "") -> Dictionary:
	var normalized_side: String = normalize_breach_side(side)
	var flip_h: bool = false
	var flip_v: bool = false
	var offset: Vector2 = Vector2.ZERO
	match normalized_side:
		"se":
			flip_h = true
		"nw":
			flip_v = true
		"ne":
			flip_h = true
			flip_v = true
	if BreachableWallRulesServiceRef.normalize_overlay_height(height_level) == BreachableWallRulesServiceRef.BREACH_OVERLAY_HALFMID:
		offset.x = -2.0 if normalized_side == "sw" else 2.0
	return {"side": normalized_side, "flip_h": flip_h, "flip_v": flip_v, "offset": offset, "visible": true}

func is_breach_side_visible_for_wall(_cell: Vector2i, breach_side: String, _topology: Dictionary) -> bool:
	return BreachableWallServiceRef.is_visible_breach_side(breach_side)

func get_normalized_breachable_wall_height(wall_data: Dictionary) -> String:
	return WallRendererRef.get_normalized_breachable_height(wall_data)

func get_breach_overlay_destination_rect(base_texture_rect: Rect2, base_source_rect: Rect2, base_texture: Texture2D, overlay_texture: Texture2D, height_level: String) -> Rect2:
	if base_texture == null or overlay_texture == null:
		return Rect2()
	var layout: Dictionary = BreachableWallServiceRef.get_texture_overlay_layout(base_texture_rect, base_source_rect, base_texture.get_size(), overlay_texture.get_size(), height_level, ISO_WALL_HEIGHT_VISIBLE_BOUNDS, ISO_WALL_BASELINE_VISIBLE_BOUNDS)
	if not bool(layout.get("ok", false)):
		return Rect2()
	return _apply_breach_overlay_rules_adjustment(Rect2(layout.get("rect", Rect2())), height_level)

func _apply_breach_overlay_rules_adjustment(destination_rect: Rect2, height_level: String) -> Rect2:
	if destination_rect.size.x <= 0.0 or destination_rect.size.y <= 0.0:
		return destination_rect
	var adjustment: Dictionary = BreachableWallRulesServiceRef.get_overlay_adjustment(height_level)
	var scale_y: float = float(adjustment.get("scale_y", 1.0))
	var offset_y: float = float(adjustment.get("offset_y", 0.0))
	if is_equal_approx(scale_y, 1.0) and is_equal_approx(offset_y, 0.0):
		return destination_rect
	var adjusted: Rect2 = destination_rect
	var bottom_y: float = adjusted.position.y + adjusted.size.y + offset_y
	adjusted.size.y = maxf(1.0, adjusted.size.y * scale_y)
	adjusted.position.y = bottom_y - adjusted.size.y
	return adjusted

func draw_breach_overlay_texture_rect(texture: Texture2D, destination_rect: Rect2, source_rect: Rect2, texture_transform: Dictionary) -> void:
	if destination_rect.size.x <= 0.0 or destination_rect.size.y <= 0.0:
		return
	var flip_h: bool = bool(texture_transform.get("flip_h", false))
	var flip_v: bool = bool(texture_transform.get("flip_v", false))
	if not flip_h and not flip_v:
		draw_texture_rect_region(texture, destination_rect, source_rect)
		return
	var center: Vector2 = destination_rect.position + destination_rect.size * 0.5
	var draw_scale: Vector2 = Vector2(1.0, 1.0)
	if flip_h:
		draw_scale.x = -1.0
	if flip_v:
		draw_scale.y = -1.0
	draw_set_transform(center, 0.0, draw_scale)
	draw_texture_rect_region(texture, Rect2(destination_rect.size * -0.5, destination_rect.size), source_rect)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func draw_breachable_wall_overlay_for_cell(cell: Vector2i, wall_data: Dictionary, wall_asset_key: String, topology: Dictionary) -> void:
	var material_row: Dictionary = Dictionary(wall_data.get("material", {}))
	var material_id: String = str(material_row.get("id", material_row.get("material_id", ""))).strip_edges().to_lower()
	if not is_breachable_wall_material_id(material_id):
		return
	var override_data: Dictionary = Dictionary(wall_data.get("override", {}))
	var breach_side: String = normalize_breach_side(str(override_data.get("breach_side", material_row.get("breach_side", "sw"))))
	if not is_breach_side_visible_for_wall(cell, breach_side, topology):
		return
	var overlay_asset_key: String = get_breach_overlay_asset_key(str(material_row.get("texture_asset_id", material_id)))
	if overlay_asset_key.is_empty():
		return
	var overlay_texture: Texture2D = get_breach_overlay_texture_for_asset_key(overlay_asset_key)
	if overlay_texture == null:
		return
	var base_texture: Texture2D = get_iso_wall_texture_for_asset_key(wall_asset_key)
	if base_texture == null:
		return
	var texture_rect: Rect2 = get_iso_wall_texture_draw_rect_for_cell(cell, base_texture, wall_asset_key, topology)
	var source_rect: Rect2 = get_iso_wall_visible_source_rect(wall_asset_key, base_texture)
	var height_level: String = get_normalized_breachable_wall_height(wall_data)
	var destination_rect: Rect2 = get_breach_overlay_destination_rect(texture_rect, source_rect, base_texture, overlay_texture, height_level)
	var overlay_source_rect: Rect2 = Rect2(Vector2.ZERO, overlay_texture.get_size())
	var overlay_adjustment: Dictionary = BreachableWallRulesServiceRef.get_overlay_adjustment(height_level)
	var bottom_trim_px: int = maxi(0, int(overlay_adjustment.get("bottom_trim_px", 0)))
	if bottom_trim_px > 0:
		overlay_source_rect.size.y = maxf(1.0, overlay_source_rect.size.y - float(bottom_trim_px))
	var side_transform: Dictionary = get_breach_overlay_transform_for_side(breach_side, height_level)
	var offset: Vector2 = Vector2(side_transform.get("offset", Vector2.ZERO))
	destination_rect.position += offset
	draw_breach_overlay_texture_rect(overlay_texture, destination_rect, overlay_source_rect, side_transform)
	draw_iso_asset_alignment_overlay(overlay_asset_key, destination_rect.position + Vector2(destination_rect.size.x * 0.5, destination_rect.size.y), destination_rect)

func get_iso_object_asset_key_for_profile(profile_key: String) -> String:
	return ObjectRendererRef.get_asset_key_for_profile(profile_key)

func get_iso_object_profile_key_for_object_data(object_data: Dictionary, fallback_profile_key: String = "generic_object") -> String:
	return ObjectRendererRef.get_profile_key_for_object_data(object_data, fallback_profile_key)

func is_wall_mounted_runtime_object(object_data: Dictionary) -> bool:
	return ObjectRendererRef.is_wall_mounted_runtime_object(object_data)

func get_wall_mounted_cardinal_side(object_data: Dictionary) -> String:
	return ObjectRendererRef.get_wall_mounted_cardinal_side(object_data)

func get_wall_mounted_visual_center(object_data: Dictionary, fallback_cell: Vector2i) -> Vector2:
	var wall_cell: Vector2i = _try_parse_cell_variant(object_data.get("attached_wall_cell", Vector2i(-1, -1)), Vector2i(-1, -1))
	if wall_cell.x < 0 or wall_cell.y < 0:
		wall_cell = _try_parse_cell_variant(object_data.get("position", fallback_cell), fallback_cell)
	return get_wall_mounted_anchor(wall_cell, normalize_wall_visual_side(object_data), object_data)

func get_wall_mounted_anchor(cell: Vector2i, wall_side: String, object_data: Dictionary) -> Vector2:
	var normalized_side: String = wall_side.strip_edges().to_lower()
	if normalized_side not in ["sw", "se"]:
		var side_data: Dictionary = object_data.duplicate(false)
		side_data["wall_side"] = normalized_side
		normalized_side = normalize_wall_visual_side(side_data)

	var side_offset: Vector2 = WALL_MOUNT_SIDE_OFFSET_SE if normalized_side == "se" else WALL_MOUNT_SIDE_OFFSET_SW
	var horizontal_offset: float = side_offset.x + WALL_MOUNTED_COMMON_X_OFFSET
	var height_offset: float = WALL_MOUNTED_LIGHT_HEIGHT_OFFSET if LightVisualServiceRef.is_light_object(object_data) else WALL_MOUNTED_DEVICE_HEIGHT_OFFSET
	return grid_to_iso(cell) + Vector2(horizontal_offset, WALL_MOUNT_SIDE_SHARED_Y_OFFSET + height_offset)

func log_wall_mounted_positioning(object_data: Dictionary, render_path_name: String, wall_side: String, normalized_side: String, final_anchor: Vector2, final_destination_rect: Rect2, used_wall_mounted_anchor: bool) -> void:
	if not debug_log_wall_mounted_positioning:
		return
	print("[WallMountedPositioning] object_id=%s object_type=%s prefab_id=%s render_path=%s wall_side=%s normalized_side=%s final_anchor=%s final_destination_rect=%s used_get_wall_mounted_anchor=%s" % [
		str(object_data.get("id", object_data.get("object_id", ""))),
		str(object_data.get("object_type", object_data.get("type", ""))),
		str(object_data.get("prefab_id", object_data.get("map_constructor_prefab_id", object_data.get("visual_id", "")))),
		render_path_name,
		wall_side,
		normalized_side,
		str(final_anchor),
		str(final_destination_rect),
		str(used_wall_mounted_anchor)
	])

func _get_object_mount_mode(object_data: Dictionary) -> String:
	return ObjectRendererRef.get_mount_mode(object_data)

func _is_object_state_on(object_data: Dictionary) -> bool:
	return ObjectRendererRef.is_state_on(object_data)

func _is_fuse_present(object_data: Dictionary) -> bool:
	return ObjectRendererRef.is_fuse_present(object_data)

func get_iso_object_asset_key_for_object_data(object_data: Dictionary, fallback_profile_key: String) -> String:
	return ObjectRendererRef.get_asset_key_for_object_data(object_data, fallback_profile_key)

func get_iso_object_asset_resolution_diagnostic(object_data: Dictionary, fallback_profile_key: String, resolved_asset_key: String) -> Dictionary:
	var normalized_asset_key: String = resolved_asset_key.strip_edges().to_lower()
	var visual_family: String = VisualStateAssetServiceRef.get_visual_family(object_data)
	var visual_state: String = VisualStateAssetServiceRef.resolve_visual_state(object_data) if VisualStateAssetServiceRef.object_uses_visual_states(object_data) else ""
	var visual_variant: String = VisualStateAssetServiceRef.resolve_visual_variant(object_data) if VisualStateAssetServiceRef.object_uses_visual_states(object_data) else ""
	var resolved_path: String = get_iso_object_png_asset_path(normalized_asset_key)
	var used_png: bool = not resolved_path.is_empty()
	var used_svg_fallback: bool = false
	if not used_png:
		resolved_path = get_iso_placeholder_asset_path(normalized_asset_key)
		used_svg_fallback = not resolved_path.is_empty() and is_placeholder_object_texture_path(resolved_path)
	return {
		"object_id": str(object_data.get("id", object_data.get("object_id", ""))),
		"object_type": str(object_data.get("object_type", object_data.get("item_type", object_data.get("type", "")))),
		"map_constructor_prefab_id": str(object_data.get("map_constructor_prefab_id", "")),
		"visual_family": str(object_data.get("visual_family", object_data.get("visual_asset_family", ""))),
		"visual_state_policy": str(object_data.get("visual_state_policy", "")),
		"resolved_family": visual_family,
		"resolved_state": visual_state,
		"resolved_variant": visual_variant,
		"texture_path": resolved_path,
		"texture_load_result": "png" if used_png else ("placeholder" if used_svg_fallback else "missing"),
		"fallback_profile": fallback_profile_key,
		"resolved_asset_key": normalized_asset_key,
		"resolved_path": resolved_path,
		"used_png": used_png,
		"used_svg_fallback": used_svg_fallback
	}

func log_iso_object_asset_resolution(object_data: Dictionary, fallback_profile_key: String, resolved_asset_key: String) -> void:
	if not debug_log_iso_object_asset_resolution:
		return
	var diagnostic: Dictionary = get_iso_object_asset_resolution_diagnostic(object_data, fallback_profile_key, resolved_asset_key)
	print("[IsoObjectAsset] object_id=%s object_type=%s map_constructor_prefab_id=%s visual_family=%s visual_state_policy=%s resolved_family=%s resolved_state=%s resolved_variant=%s resolved_asset_id=%s texture_path=%s texture_load_result=%s fallback_profile=%s used_png=%s used_svg_fallback=%s" % [
		str(diagnostic.get("object_id", "")),
		str(diagnostic.get("object_type", "")),
		str(diagnostic.get("map_constructor_prefab_id", "")),
		str(diagnostic.get("visual_family", "")),
		str(diagnostic.get("visual_state_policy", "")),
		str(diagnostic.get("resolved_family", "")),
		str(diagnostic.get("resolved_state", "")),
		str(diagnostic.get("resolved_variant", "")),
		str(diagnostic.get("resolved_asset_key", "")),
		str(diagnostic.get("texture_path", "")),
		str(diagnostic.get("texture_load_result", "")),
		str(diagnostic.get("fallback_profile", "")),
		str(diagnostic.get("used_png", false)),
		str(diagnostic.get("used_svg_fallback", false))
	])

func get_iso_object_png_asset_path(asset_key: String, descriptor: Dictionary = {}) -> String:
	var normalized_asset_key: String = str(asset_key).strip_edges().to_lower()
	if normalized_asset_key.is_empty() and descriptor.is_empty():
		return ""

	var descriptor_visual_id: String = str(descriptor.get("visual_id", descriptor.get("visual_asset_id", descriptor.get("asset_id", normalized_asset_key)))).strip_edges()
	var descriptor_path: String = str(descriptor.get("path", descriptor.get("texture_path", ""))).strip_edges()
	var catalog_path: String = VisualAssetCatalogScript.resolve_visual_texture_path(descriptor_visual_id, descriptor_path)
	if catalog_path.ends_with(".png") and (catalog_path.find("/objects/") >= 0 or catalog_path.find("/moovable/") >= 0 or catalog_path.find("/light/") >= 0 or catalog_path.find("/items/") >= 0 or catalog_path.find("/cooling system/") >= 0):
		return catalog_path

	return ""
	
func is_iso_object_png_asset_key(asset_key: String) -> bool:
	return not get_iso_object_png_asset_path(asset_key).is_empty()

func get_iso_object_png_texture_for_resolved_path(asset_key: String, texture_path: String) -> Texture2D:
	var normalized_asset_key: String = asset_key.strip_edges().to_lower()
	var normalized_texture_path: String = texture_path.strip_edges()
	if normalized_texture_path.is_empty():
		return null
	var cache_key: String = "%s|%s" % [normalized_asset_key, normalized_texture_path]
	if _iso_object_png_texture_cache.has(cache_key):
		var cached_value: Variant = _iso_object_png_texture_cache.get(cache_key)
		if cached_value is Texture2D:
			return cached_value as Texture2D
		return null
	if not ResourceLoader.exists(normalized_texture_path, "Texture2D"):
		push_warning("[IsoObjectPNG] missing object PNG for visual_id=%s path=%s" % [normalized_asset_key, normalized_texture_path])
		_iso_object_png_texture_cache[cache_key] = null
		return null
	var loaded_resource: Resource = ResourceLoader.load(normalized_texture_path)
	if loaded_resource is Texture2D:
		var loaded_texture: Texture2D = loaded_resource as Texture2D
		_iso_object_png_texture_cache[cache_key] = loaded_texture
		return loaded_texture
	push_warning("[IsoObjectPNG] failed to load object PNG as Texture2D for visual_id=%s path=%s" % [normalized_asset_key, normalized_texture_path])
	_iso_object_png_texture_cache[cache_key] = null
	return null

func get_iso_object_png_texture_for_asset_key(asset_key: String, descriptor: Dictionary = {}) -> Texture2D:
	var normalized_asset_key: String = asset_key.strip_edges().to_lower()
	var texture_path: String = get_iso_object_png_asset_path(normalized_asset_key, descriptor)
	return get_iso_object_png_texture_for_resolved_path(normalized_asset_key, texture_path)

func get_iso_placeholder_asset_path(asset_key: String) -> String:
	var normalized_asset_key: String = str(asset_key).strip_edges().to_lower()
	if normalized_asset_key.is_empty():
		return ""

	var catalog_path: String = VisualAssetCatalogScript.get_asset_path(normalized_asset_key)
	if catalog_path.find("/placeholders/") >= 0:
		return catalog_path

	return ""
	
func is_placeholder_object_texture_path(texture_path: String) -> bool:
	var normalized_path: String = texture_path.strip_edges().to_lower()
	return normalized_path.begins_with("res://assets/visual/isometric/placeholders/iso_object_") and normalized_path.ends_with(".svg")

func is_placeholder_object_texture_asset_key(asset_key: String) -> bool:
	if asset_key.is_empty():
		return false
	var placeholder_path: String = get_iso_placeholder_asset_path(asset_key)
	return is_placeholder_object_texture_path(placeholder_path)

func should_skip_placeholder_object_texture_in_gray_test(asset_key: String) -> bool:
	if not use_gray_room_visual_test_assets:
		return false
	if get_explicit_iso_texture_for_asset_key(asset_key) != null:
		return false
	return is_placeholder_object_texture_asset_key(asset_key)

func should_skip_placeholder_object_texture_path_in_gray_test(texture_path: String) -> bool:
	if not use_gray_room_visual_test_assets:
		return false
	return is_placeholder_object_texture_path(texture_path)

func get_iso_placeholder_texture_for_asset_key(asset_key: String) -> Texture2D:
	if not should_use_iso_placeholder_asset_preset():
		return null

	var normalized_asset_key: String = str(asset_key).strip_edges().to_lower()
	if normalized_asset_key.is_empty():
		return null

	if should_skip_placeholder_object_texture_in_gray_test(normalized_asset_key):
		return null

	var placeholder_path: String = VisualAssetCatalogScript.get_asset_path(normalized_asset_key)
	if placeholder_path.is_empty() or placeholder_path.find("/placeholders/") < 0:
		return null

	if _iso_placeholder_texture_cache.has(normalized_asset_key):
		var cached_value: Variant = _iso_placeholder_texture_cache.get(normalized_asset_key)
		if cached_value is Texture2D:
			return cached_value as Texture2D
		return null

	var loaded_resource: Resource = ResourceLoader.load(placeholder_path)
	if loaded_resource is Texture2D:
		var loaded_texture: Texture2D = loaded_resource as Texture2D
		_iso_placeholder_texture_cache[normalized_asset_key] = loaded_texture
		return loaded_texture

	_iso_placeholder_texture_cache[normalized_asset_key] = null
	return null

func clear_iso_placeholder_texture_cache() -> void:
	_iso_placeholder_texture_cache.clear()
	_iso_object_png_texture_cache.clear()
	_iso_wall_asset_texture_cache.clear()
	_iso_floor_asset_texture_cache.clear()
	_iso_ground_asset_texture_cache.clear()

func get_explicit_iso_texture_for_asset_key(asset_key: String) -> Texture2D:
	match asset_key:
		"floor_default":
			return iso_floor_default_texture
		"floor_stepped":
			return iso_floor_stepped_texture
		"floor_clean_lab":
			return iso_floor_clean_lab_texture
		"floor_dark_service":
			return iso_floor_dark_service_texture
		"floor_hazard":
			return iso_floor_hazard_texture
		"floor_power":
			return iso_floor_power_texture
		"floor_damaged":
			return iso_floor_damaged_texture
		"floor_reinforced":
			return iso_floor_reinforced_texture
		"floor_diagnostic":
			return iso_floor_diagnostic_texture
		"floor_door_underlay":
			return iso_floor_door_underlay_texture
		"wall_default":
			return iso_wall_default_texture
		"wall_outer":
			return iso_wall_outer_texture
		"wall_brick":
			return iso_wall_brick_texture
		"wall_concrete":
			return iso_wall_concrete_texture
		"wall_grate":
			return iso_wall_grate_texture
		"wall_steel":
			return iso_wall_steel_texture
		"wall_energy":
			return iso_wall_energy_texture
		"object_door":
			return iso_object_door_texture
		"object_terminal":
			return iso_object_terminal_texture
		"object_key":
			return iso_object_key_texture
		"object_component":
			return iso_object_component_texture
		"object_socket":
			return iso_object_socket_texture
		"object_cable":
			return iso_object_cable_texture
		"object_generic":
			return iso_object_generic_texture
		"object_fuse":
			return iso_object_fuse_texture
		"object_repair_kit":
			return iso_object_repair_kit_texture
		"object_keycard":
			return iso_object_keycard_texture
		"object_access_code":
			return iso_object_access_code_texture
		"object_cable_reel":
			return iso_object_cable_reel_texture
		"object_button":
			return iso_object_button_texture
		"object_switch":
			return iso_object_switch_texture
		_:
			return null

func get_iso_texture_for_asset_key(asset_key: String) -> Texture2D:
	var normalized_asset_key: String = asset_key.strip_edges().to_lower()
	if normalized_asset_key.begins_with("wall_"):
		return get_iso_wall_texture_for_asset_key(normalized_asset_key)
	if is_iso_object_png_asset_key(normalized_asset_key):
		return get_iso_object_png_texture_for_asset_key(normalized_asset_key)
	var explicit_texture: Texture2D = get_explicit_iso_texture_for_asset_key(normalized_asset_key)
	if explicit_texture != null:
		return explicit_texture
	if should_skip_placeholder_object_texture_in_gray_test(normalized_asset_key):
		return null
	var placeholder_path: String = VisualAssetCatalogScript.get_asset_path(normalized_asset_key)
	if placeholder_path.is_empty() or placeholder_path.find("/placeholders/") < 0:
		return null

	return get_iso_placeholder_texture_for_asset_key(normalized_asset_key)

func has_iso_texture_for_asset_key(asset_key: String) -> bool:
	return get_iso_texture_for_asset_key(asset_key) != null

func get_iso_visual_layer_debug_state() -> Dictionary:
	return {
		"floor_enabled": should_render_iso_floor_visuals(),
		"wall_enabled": should_render_iso_wall_visuals(),
		"object_enabled": should_render_iso_object_visuals(),
		"fog_enabled": should_render_iso_fog_visuals(),
		"fog_overlay_will_draw": should_draw_iso_fog_cell_shapes(),
		"fog_cell_shapes_enabled": iso_fog_draw_cell_shapes,
		"constructor_fog_suppressed": should_suppress_iso_fog_for_constructor(),
		"asset_hooks_enabled": should_use_iso_tile_asset_hook_visuals(),
		"placeholder_assets_enabled": should_use_iso_placeholder_asset_preset(),
		"preview_active": is_iso_visual_preview_active(),
		"debug_marker": debug_draw_marker,
		"helper_preview": debug_draw_iso_helper_preview,
		"fog_outlines": debug_draw_iso_fog_outlines,
		"cell_outlines": debug_draw_iso_cell_outlines,
		"wall_outlines": debug_draw_iso_wall_outlines,
		"object_outlines": debug_draw_iso_object_outlines,
		"asset_alignment_overlay": show_asset_alignment_overlay,
		"gray_test_asset_validation": get_gray_room_visual_test_asset_validation()
	}

func get_iso_visual_texture_debug_state() -> Dictionary:
	var texture_keys: Array[String] = get_iso_visual_texture_debug_keys()
	var placeholder_preset_enabled: bool = should_use_iso_placeholder_asset_preset()
	var debug_state: Dictionary = {}
	for texture_key in texture_keys:
		var explicit_texture: Texture2D = get_explicit_iso_texture_for_asset_key(texture_key)
		var has_explicit_texture: bool = explicit_texture != null
		var placeholder_path: String = get_iso_placeholder_asset_path(texture_key)
		var placeholder_available: bool = false
		var wall_catalog_path: String = ""
		var wall_catalog_available: bool = false
		var ground_catalog_path: String = ""
		var ground_catalog_available: bool = false
		var gray_test_placeholder_object_skipped: bool = should_skip_placeholder_object_texture_in_gray_test(texture_key)
		if texture_key == ISO_FLOOR_TEST_ASSET_KEY:
			wall_catalog_path = get_iso_gray_test_asset_path(texture_key)
			wall_catalog_available = ResourceLoader.exists(wall_catalog_path)
		elif texture_key.begins_with("wall_"):
			var wall_catalog: Dictionary = get_iso_wall_asset_catalog()
			if wall_catalog.has(texture_key):
				wall_catalog_path = get_iso_gray_test_asset_path(texture_key) if texture_key.begins_with("wall_gray_") else ISO_WALL_ASSET_PACK_DIR + str(wall_catalog.get(texture_key, ""))
				wall_catalog_available = ResourceLoader.exists(wall_catalog_path)
		elif texture_key.begins_with("ground_"):
			if ISO_GROUND_ASSET_CATALOG.has(texture_key):
				ground_catalog_path = ISO_GROUND_ASSET_PACK_DIR + str(ISO_GROUND_ASSET_CATALOG.get(texture_key, ""))
				ground_catalog_available = ResourceLoader.exists(ground_catalog_path)
		elif placeholder_preset_enabled and placeholder_path != "" and not gray_test_placeholder_object_skipped:
			placeholder_available = ResourceLoader.exists(placeholder_path)
		var object_png_path: String = get_iso_object_png_asset_path(texture_key)
		var object_png_available: bool = false
		if not object_png_path.is_empty():
			object_png_available = ResourceLoader.exists(object_png_path, "Texture2D")

		var active_texture_source: String = "none"
		if object_png_available:
			active_texture_source = "object_png"
		elif wall_catalog_available:
			active_texture_source = "wall_catalog"
		elif ground_catalog_available:
			active_texture_source = "ground_catalog"
		elif has_explicit_texture:
			active_texture_source = "explicit"
		elif gray_test_placeholder_object_skipped:
			active_texture_source = "gray_test_placeholder_object_skipped"
		elif placeholder_preset_enabled and placeholder_available:
			active_texture_source = "placeholder"

		debug_state[texture_key] = {
			"has_explicit_texture": has_explicit_texture,
			"placeholder_path": placeholder_path,
			"placeholder_available": placeholder_available,
			"gray_test_placeholder_object_skipped": gray_test_placeholder_object_skipped,
			"object_png_path": object_png_path,
			"object_png_available": object_png_available,
			"wall_catalog_path": wall_catalog_path,
			"wall_catalog_available": wall_catalog_available,
			"ground_catalog_path": ground_catalog_path,
			"ground_catalog_available": ground_catalog_available,
			"active_texture_source": active_texture_source
		}
	return debug_state

func validate_iso_object_png_assets() -> Dictionary:
	var missing_paths: Array[Dictionary] = []
	var invalid_textures: Array[Dictionary] = []
	var svg_conflicts: Array[Dictionary] = []
	var assets: Dictionary = {}
	for visual_id_variant in VisualAssetCatalogScript.get_canonical_object_visual_ids():
		var visual_id: String = str(visual_id_variant)
		var expected_path: String = get_iso_object_png_asset_path(visual_id)
		var exists: bool = false
		var loads_as_texture: bool = false
		if not expected_path.is_empty():
			exists = ResourceLoader.exists(expected_path)
			loads_as_texture = ResourceLoader.exists(expected_path, "Texture2D")
		assets[visual_id] = {"path": expected_path, "exists": exists, "loads_as_texture": loads_as_texture, "resolver": "object_png"}
		if expected_path.is_empty() or not exists:
			missing_paths.append({"visual_id": visual_id, "expected_path": expected_path})
		elif not loads_as_texture:
			invalid_textures.append({"visual_id": visual_id, "expected_path": expected_path})
		var placeholder_path: String = get_iso_placeholder_asset_path(visual_id)
		if not placeholder_path.is_empty() and is_placeholder_object_texture_path(placeholder_path):
			svg_conflicts.append({"visual_id": visual_id, "png_path": expected_path, "svg_path": placeholder_path})
	return {
		"ok": missing_paths.is_empty() and invalid_textures.is_empty() and svg_conflicts.is_empty(),
		"asset_count": VisualAssetCatalogScript.get_canonical_object_visual_ids().size(),
		"assets": assets,
		"missing_paths": missing_paths,
		"invalid_textures": invalid_textures,
		"svg_conflicts": svg_conflicts,
		"fallback": "magenta_black_missing_asset_debug_checker"
	}

func get_iso_visual_texture_debug_keys() -> Array[String]:
	return [
		"floor_concrete", "floor_steel", "floor_titan", "floor_default", "floor_stepped", "floor_clean_lab", "floor_dark_service", "floor_hazard", "floor_power", "floor_damaged", "floor_reinforced", "floor_diagnostic", "floor_door_underlay",
		"ground_low", "ground_halflow",
		"wall_concrete_low", "wall_concrete_halflow", "wall_concrete_mid", "wall_concrete_halfmid", "wall_concrete_tall",
		"wall_steel_low", "wall_steel_halflow", "wall_steel_mid", "wall_steel_halfmid", "wall_steel_tall",
		"wall_titan_low", "wall_titan_halflow", "wall_titan_mid", "wall_titan_halfmid", "wall_titan_tall",
		"wall_reinforced_steel_low", "wall_reinforced_steel_halflow", "wall_reinforced_steel_mid", "wall_reinforced_steel_halfmid", "wall_reinforced_steel_tall",
		"wall_brick_low", "wall_brick_halflow", "wall_brick_mid", "wall_brick_halfmid", "wall_brick_tall",
		"wall_outer_low", "wall_outer_halflow", "wall_outer_mid", "wall_outer_halfmid", "wall_outer_tall",
		"wall_grate_mid", "wall_grate_halfmid", "wall_grate_tall",
		"object_door", "object_terminal", "object_key", "object_component", "object_socket", "object_cable", "object_generic",
		"object_fuse", "object_repair_kit", "object_keycard", "object_access_code", "object_cable_reel", "object_button", "object_switch",
		"power_source_01", "terminal_01", "radiator_01", "radiator_floor_01", "light_01", "light_off_wall_01", "light_on_wall_01", "light_on_wall_pulsar_overlay_01", "cable_reel_01", "cable_reel_02",
		"fuse_box_in_01", "fuse_box_out_01", "fuse_box_in_wall_01", "fuse_box_out_wall_01",
		"barrel_01", "fire_barrel_01", "normal_barrel_floor_01", "fire_barrel_floor_01",
		"normal_crate_floor_01", "radiator_floor_01"
	]


func get_iso_asset_alignment_diagnostics() -> Dictionary:
	var missing_alignment_rules: Array[String] = []
	var unused_alignment_rules: Array[String] = []
	var scale_overrides: Dictionary = {}

	var known_object_asset_keys: Dictionary = {}
	var all_asset_paths: Dictionary = VisualAssetCatalogScript.get_all_asset_paths()

	for asset_key_variant in all_asset_paths.keys():
		var asset_key: String = str(asset_key_variant)
		var asset_path: String = str(all_asset_paths.get(asset_key, ""))

		if asset_path.find("/objects/") >= 0 or asset_path.find("/moovable/") >= 0:
			known_object_asset_keys[asset_key] = true
		elif asset_path.find("/placeholders/") >= 0 and asset_key.begins_with("object_"):
			known_object_asset_keys[asset_key] = true

	for rule_key_variant in ISO_ASSET_ALIGNMENT_RULES.keys():
		var rule_key: String = str(rule_key_variant)
		var rule: Dictionary = Dictionary(ISO_ASSET_ALIGNMENT_RULES.get(rule_key, {}))

		if not known_object_asset_keys.has(rule_key):
			unused_alignment_rules.append(rule_key)

		var scale_value: float = float(rule.get("scale", 1.0))
		if not is_equal_approx(scale_value, 1.0):
			scale_overrides[rule_key] = scale_value

	for asset_key_variant in known_object_asset_keys.keys():
		var asset_key: String = str(asset_key_variant)
		if not ISO_ASSET_ALIGNMENT_RULES.has(asset_key):
			missing_alignment_rules.append(asset_key)

	return {
		"missing_alignment_rules": missing_alignment_rules,
		"unused_alignment_rules": unused_alignment_rules,
		"scale_overrides": scale_overrides
	}

func _increment_iso_debug_count(counts: Dictionary, key: String) -> void:
	if key.is_empty():
		return
	var current_value: int = int(counts.get(key, 0))
	counts[key] = current_value + 1

func get_iso_visual_cell_stats() -> Dictionary:
	var stats: Dictionary = {
		"has_grid_manager": _grid_manager != null,
		"map_width": 0,
		"map_height": 0,
		"total_cells": 0,
		"floor_like_cells": 0,
		"wall_cells": 0,
		"object_cells": 0,
		"fog_overlay_cells": 0,
		"visible_cells": 0,
		"explored_cells": 0,
		"unexplored_cells": 0,
		"tile_type_counts": {},
		"object_profile_counts": {},
		"wall_profile_counts": {},
		"floor_profile_counts": {},
		"floor_height_counts": {},
		"asset_key_counts": {}
	}
	if _grid_manager == null:
		return stats

	var map_width: int = _grid_manager.get_map_width()
	var map_height: int = _grid_manager.get_map_height()
	stats["map_width"] = map_width
	stats["map_height"] = map_height
	var total_cells: int = maxi(map_width, 0) * maxi(map_height, 0)
	stats["total_cells"] = total_cells

	var tile_type_counts: Dictionary = Dictionary(stats.get("tile_type_counts", {}))
	var object_profile_counts: Dictionary = Dictionary(stats.get("object_profile_counts", {}))
	var wall_profile_counts: Dictionary = Dictionary(stats.get("wall_profile_counts", {}))
	var floor_profile_counts: Dictionary = Dictionary(stats.get("floor_profile_counts", {}))
	var floor_height_counts: Dictionary = Dictionary(stats.get("floor_height_counts", {}))
	var asset_key_counts: Dictionary = Dictionary(stats.get("asset_key_counts", {}))
	var mission_manager: Node = get_mission_manager_ref()

	for y in range(map_height):
		for x in range(map_width):
			var cell: Vector2i = Vector2i(x, y)
			var tile_type: int = _grid_manager.get_tile(cell)
			_increment_iso_debug_count(tile_type_counts, str(tile_type))

			if is_floor_like_tile(tile_type):
				stats["floor_like_cells"] = int(stats.get("floor_like_cells", 0)) + 1
				_increment_iso_debug_count(floor_profile_counts, get_iso_floor_visual_profile_key_for_cell(cell))
				_increment_iso_debug_count(asset_key_counts, get_iso_floor_asset_key_for_tile(tile_type))
				var floor_height_level: String = ""
				if mission_manager != null and mission_manager.has_method("get_map_constructor_floor_material_for_cell"):
					var floor_material_result: Dictionary = _safe_variant_dictionary(mission_manager.call("get_map_constructor_floor_material_for_cell", cell))
					if bool(floor_material_result.get("ok", false)):
						var floor_override: Dictionary = _safe_variant_dictionary(floor_material_result.get("override", {}))
						floor_height_level = normalize_floor_height_level(str(floor_override.get("floor_height", floor_override.get("floor_visual_height", floor_override.get("ground_height", "")))))
				if floor_height_level.is_empty() and _grid_manager != null and _grid_manager.has_method("get_floor_height_for_cell"):
					floor_height_level = normalize_floor_height_level(str(_grid_manager.call("get_floor_height_for_cell", cell)))
				var floor_height_count_key: String = "default"
				if not floor_height_level.is_empty():
					floor_height_count_key = floor_height_level
				_increment_iso_debug_count(floor_height_counts, floor_height_count_key)
				var ground_asset_key: String = get_iso_ground_asset_key_for_floor_height(floor_height_level)
				if not ground_asset_key.is_empty():
					_increment_iso_debug_count(asset_key_counts, ground_asset_key)
			if is_wall_tile(tile_type):
				stats["wall_cells"] = int(stats.get("wall_cells", 0)) + 1
				var wall_profile_key: String = get_wall_visual_profile_key_for_cell(cell)
				var wall_material_override: Dictionary = _get_wall_material_override_for_cell(cell)
				var wall_asset_key: String = get_production_wall_asset_key(wall_material_override, cell, wall_profile_key, get_iso_wall_depth_bounds())
				if use_gray_room_visual_test_assets:
					wall_asset_key = get_test_wall_height_asset_key(wall_material_override, cell, get_iso_wall_depth_bounds())
				_increment_iso_debug_count(wall_profile_counts, wall_profile_key)
				_increment_iso_debug_count(asset_key_counts, wall_asset_key)
			if is_iso_object_tile(tile_type):
				stats["object_cells"] = int(stats.get("object_cells", 0)) + 1
				var object_profile_key: String = get_iso_object_profile_key_for_tile(tile_type)
				_increment_iso_debug_count(object_profile_counts, object_profile_key)
				_increment_iso_debug_count(asset_key_counts, get_iso_object_asset_key_for_profile(object_profile_key))
			if should_draw_iso_fog_for_cell(cell):
				stats["fog_overlay_cells"] = int(stats.get("fog_overlay_cells", 0)) + 1

			if _grid_manager.has_method("is_cell_visible") and _grid_manager.is_cell_visible(cell):
				stats["visible_cells"] = int(stats.get("visible_cells", 0)) + 1
			if _grid_manager.has_method("is_explored") and _grid_manager.is_explored(cell):
				stats["explored_cells"] = int(stats.get("explored_cells", 0)) + 1

	stats["unexplored_cells"] = int(stats.get("total_cells", 0)) - int(stats.get("explored_cells", 0))
	stats["tile_type_counts"] = tile_type_counts
	stats["object_profile_counts"] = object_profile_counts
	stats["wall_profile_counts"] = wall_profile_counts
	stats["floor_profile_counts"] = floor_profile_counts
	stats["floor_height_counts"] = floor_height_counts
	stats["asset_key_counts"] = asset_key_counts
	return stats

func get_iso_visual_cell_stats_text() -> String:
	var stats: Dictionary = get_iso_visual_cell_stats()
	var lines: Array[String] = []
	var asset_key_counts: Dictionary = Dictionary(stats.get("asset_key_counts", {}))
	lines.append("IsoVisualCellStats:")
	lines.append("Grid:")
	lines.append("- has_grid_manager: %s" % str(stats.get("has_grid_manager", false)))
	lines.append("- map_size: %sx%s" % [str(stats.get("map_width", 0)), str(stats.get("map_height", 0))])
	lines.append("- total_cells: %s" % str(stats.get("total_cells", 0)))
	lines.append("Cells:")
	lines.append("- floor_like: %s" % str(stats.get("floor_like_cells", 0)))
	lines.append("- walls: %s" % str(stats.get("wall_cells", 0)))
	lines.append("- objects: %s" % str(stats.get("object_cells", 0)))
	lines.append("- fog_overlay: %s" % str(stats.get("fog_overlay_cells", 0)))
	lines.append("- visible: %s" % str(stats.get("visible_cells", 0)))
	lines.append("- explored: %s" % str(stats.get("explored_cells", 0)))
	lines.append("- unexplored: %s" % str(stats.get("unexplored_cells", 0)))
	lines.append("Asset keys:")
	for asset_key in asset_key_counts.keys():
		lines.append("- %s: %s" % [str(asset_key), str(asset_key_counts.get(asset_key, 0))])
	var floor_height_counts: Dictionary = Dictionary(stats.get("floor_height_counts", {}))
	lines.append("Floor heights:")
	for floor_height_key in floor_height_counts.keys():
		lines.append("- %s: %s" % [str(floor_height_key), str(floor_height_counts.get(floor_height_key, 0))])
	return "\n".join(lines)

func validate_iso_visual_cell_stats() -> Array[String]:
	var warnings: Array[String] = []
	var stats: Dictionary = get_iso_visual_cell_stats()
	if not bool(stats.get("has_grid_manager", false)):
		warnings.append("iso_cell_stats_missing_grid_manager")
	if int(stats.get("map_width", 0)) <= 0 or int(stats.get("map_height", 0)) <= 0:
		warnings.append("iso_cell_stats_empty_map")
	if int(stats.get("total_cells", 0)) > 0 and int(stats.get("floor_like_cells", 0)) <= 0:
		warnings.append("iso_cell_stats_no_floor_like_cells")
	if int(stats.get("total_cells", 0)) > 0 and int(stats.get("wall_cells", 0)) <= 0:
		warnings.append("iso_cell_stats_no_wall_cells")
	if int(stats.get("total_cells", 0)) > 0 and int(stats.get("object_cells", 0)) <= 0:
		warnings.append("iso_cell_stats_no_object_cells")
	if is_iso_visual_preview_active() and (
		int(stats.get("floor_like_cells", 0))
		+ int(stats.get("wall_cells", 0))
		+ int(stats.get("object_cells", 0))
	) <= 0:
		warnings.append("iso_cell_stats_preview_enabled_but_no_visual_cells")
	return warnings

func get_iso_visual_cell_stats_validation_text() -> String:
	var warnings: Array[String] = validate_iso_visual_cell_stats()
	if warnings.is_empty():
		return "IsoVisualCellStatsValidation: ok"
	var lines: Array[String] = ["IsoVisualCellStatsValidation:"]
	for warning_key in warnings:
		lines.append("- %s" % warning_key)
	return "\n".join(lines)

func get_iso_visual_debug_report() -> Dictionary:
	var has_grid_manager: bool = _grid_manager != null
	var map_width: int = 0
	var map_height: int = 0
	var legacy_grid_should_draw: bool = false
	if has_grid_manager:
		map_width = _grid_manager.get_map_width()
		map_height = _grid_manager.get_map_height()
		legacy_grid_should_draw = false
	var iso_active: bool = is_iso_renderer_active()
	var floor_enabled: bool = should_render_iso_floor_visuals()
	var wall_enabled: bool = should_render_iso_wall_visuals()
	var object_enabled: bool = should_render_iso_object_visuals()
	var fog_enabled: bool = should_render_iso_fog_visuals()
	var fog_overlay_will_draw: bool = should_draw_iso_fog_cell_shapes()
	var constructor_fog_suppressed: bool = should_suppress_iso_fog_for_constructor()
	var duplicate_overlay_risk: bool = is_iso_visual_preview_active() and (floor_enabled or wall_enabled or object_enabled) and fog_overlay_will_draw
	var ground_low_path: String = ISO_GROUND_ASSET_PACK_DIR + str(ISO_GROUND_ASSET_CATALOG.get("ground_low", ""))
	var ground_halflow_path: String = ISO_GROUND_ASSET_PACK_DIR + str(ISO_GROUND_ASSET_CATALOG.get("ground_halflow", ""))
	return {
		"single_render_path": not (legacy_grid_should_draw and iso_active),
		"legacy_grid_should_draw": legacy_grid_should_draw,
		"iso_renderer_active": iso_active,
		"placeholder_assets_enabled": should_use_iso_placeholder_asset_preset(),
		"procedural_wall_under_texture_enabled": false,
		"ground_assets_enabled": floor_enabled,
		"ground_low_loaded": ResourceLoader.exists(ground_low_path),
		"ground_halflow_loaded": ResourceLoader.exists(ground_halflow_path),
		"fog_enabled": fog_enabled,
		"fog_overlay_will_draw": fog_overlay_will_draw,
		"fog_cell_shapes_enabled": iso_fog_draw_cell_shapes,
		"constructor_fog_suppressed": constructor_fog_suppressed,
		"duplicate_overlay_risk": duplicate_overlay_risk,
		"layers": get_iso_visual_layer_debug_state(),
		"preview": get_iso_visual_preview_state(),
		"textures": get_iso_visual_texture_debug_state(),
		"asset_alignment": get_iso_asset_alignment_diagnostics(),
		"object_png_assets": validate_iso_object_png_assets(),
		"cell_stats": get_iso_visual_cell_stats(),
		"iso_settings": {
			"projection_mode": get_iso_projection_mode(),
			"projection_diagnostic": get_iso_projection_diagnostic_text(),
			"tile_width": get_iso_tile_size().x,
			"tile_height": get_iso_tile_size().y,
			"tile_ratio": get_iso_tile_size().x / maxf(get_iso_tile_size().y, 1.0),
			"exported_tile_size_matches_active_mode": get_iso_exported_tile_size_matches_active_mode(),
			"custom_tile_width": iso_tile_width,
			"custom_tile_height": iso_tile_height,
			"wall_height": iso_wall_height,
			"object_marker_height": iso_object_marker_height,
			"origin": iso_origin
		},
		"grid": {
			"has_grid_manager": has_grid_manager,
			"map_width": map_width,
			"map_height": map_height
		}
	}

func get_iso_visual_debug_report_text() -> String:
	var report: Dictionary = get_iso_visual_debug_report()
	var lines: Array[String] = []
	var layers: Dictionary = Dictionary(report.get("layers", {}))
	var preview: Dictionary = Dictionary(report.get("preview", {}))
	var textures: Dictionary = Dictionary(report.get("textures", {}))
	var cell_stats: Dictionary = Dictionary(report.get("cell_stats", {}))
	var asset_alignment: Dictionary = Dictionary(report.get("asset_alignment", {}))
	var object_png_assets: Dictionary = Dictionary(report.get("object_png_assets", {}))
	var grid: Dictionary = Dictionary(report.get("grid", {}))
	var iso_settings: Dictionary = Dictionary(report.get("iso_settings", {}))
	lines.append("IsoVisualDebugReport:")
	lines.append("Single render path:")
	lines.append("- ok: %s" % str(report.get("single_render_path", false)))
	lines.append("- legacy_grid_should_draw: %s" % str(report.get("legacy_grid_should_draw", false)))
	lines.append("- iso_renderer_active: %s" % str(report.get("iso_renderer_active", false)))
	lines.append("- placeholder_assets_enabled: %s" % str(report.get("placeholder_assets_enabled", false)))
	lines.append("- procedural_wall_under_texture_enabled: %s" % str(report.get("procedural_wall_under_texture_enabled", false)))
	lines.append("- ground_assets_enabled: %s" % str(report.get("ground_assets_enabled", false)))
	lines.append("- ground_low_loaded: %s" % str(report.get("ground_low_loaded", false)))
	lines.append("- ground_halflow_loaded: %s" % str(report.get("ground_halflow_loaded", false)))
	lines.append("Fog overlay diagnostics:")
	lines.append("- fog_enabled: %s" % str(report.get("fog_enabled", false)))
	lines.append("- fog_overlay_will_draw: %s" % str(report.get("fog_overlay_will_draw", false)))
	lines.append("- fog_cell_shapes_enabled: %s" % str(report.get("fog_cell_shapes_enabled", false)))
	lines.append("- constructor_fog_suppressed: %s" % str(report.get("constructor_fog_suppressed", false)))
	lines.append("- duplicate_overlay_risk: %s" % str(report.get("duplicate_overlay_risk", false)))
	lines.append("Layers:")
	lines.append("- floor: %s" % str(layers.get("floor_enabled", false)))
	lines.append("- wall: %s" % str(layers.get("wall_enabled", false)))
	lines.append("- objects: %s" % str(layers.get("object_enabled", false)))
	lines.append("- fog: %s" % str(layers.get("fog_enabled", false)))
	lines.append("- asset_hooks: %s" % str(layers.get("asset_hooks_enabled", false)))
	lines.append("- placeholder_assets: %s" % str(layers.get("placeholder_assets_enabled", false)))
	lines.append("- asset_alignment_overlay: %s" % str(layers.get("asset_alignment_overlay", false)))
	lines.append("Preview:")
	lines.append("- active: %s" % str(preview.get("preview_active", false)))
	lines.append("- includes_fog: %s" % str(iso_visual_preview_includes_fog))
	lines.append("- includes_asset_hooks: %s" % str(iso_visual_preview_includes_asset_hooks))
	lines.append("Asset alignment:")
	lines.append("- ok: %s" % str(asset_alignment.get("ok", false)))
	lines.append("- assets/rules: %s/%s" % [str(asset_alignment.get("asset_count", 0)), str(asset_alignment.get("rule_count", 0))])
	lines.append("- missing_rules: %s" % str(asset_alignment.get("missing_alignment_rules", [])))
	lines.append("Object PNG assets:")
	lines.append("- ok: %s" % str(object_png_assets.get("ok", false)))
	lines.append("- asset_count: %s" % str(object_png_assets.get("asset_count", 0)))
	lines.append("- missing_paths: %s" % str(object_png_assets.get("missing_paths", [])))
	lines.append("- invalid_textures: %s" % str(object_png_assets.get("invalid_textures", [])))
	lines.append("- svg_conflicts: %s" % str(object_png_assets.get("svg_conflicts", [])))
	lines.append("Textures:")
	for texture_key in get_iso_visual_texture_debug_keys():
		var texture_entry: Dictionary = Dictionary(textures.get(texture_key, {}))
		lines.append("- %s: %s" % [texture_key, str(texture_entry.get("active_texture_source", "none"))])
	lines.append("Grid:")
	lines.append("- has_grid_manager: %s" % str(grid.get("has_grid_manager", false)))
	lines.append("- map_size: %sx%s" % [str(grid.get("map_width", 0)), str(grid.get("map_height", 0))])
	lines.append("Cell stats:")
	lines.append("- floor_like: %s" % str(cell_stats.get("floor_like_cells", 0)))
	lines.append("- floor_height_counts: %s" % str(cell_stats.get("floor_height_counts", {})))
	lines.append("- walls: %s" % str(cell_stats.get("wall_cells", 0)))
	lines.append("- objects: %s" % str(cell_stats.get("object_cells", 0)))
	lines.append("- fog_overlay: %s" % str(cell_stats.get("fog_overlay_cells", 0)))
	lines.append("Iso:")
	lines.append("- %s" % str(iso_settings.get("projection_diagnostic", get_iso_projection_diagnostic_text())))
	lines.append("- projection: %s" % str(iso_settings.get("projection_mode", ISO_PROJECTION_STANDARD)))
	lines.append("- tile: %sx%s" % [str(iso_settings.get("tile_width", 0.0)), str(iso_settings.get("tile_height", 0.0))])
	lines.append("- ratio: %.4f" % float(iso_settings.get("tile_ratio", 0.0)))
	lines.append("- exported_match: %s" % str(iso_settings.get("exported_tile_size_matches_active_mode", false)))
	lines.append("- wall_height: %s" % str(iso_settings.get("wall_height", 0.0)))
	lines.append("- object_marker_height: %s" % str(iso_settings.get("object_marker_height", 0.0)))
	return "\n".join(lines)

func validate_iso_visual_debug_report() -> Array[String]:
	var warnings: Array[String] = []

	if get_iso_tile_size().x <= 0.0:
		warnings.append("iso_tile_width_invalid")

	if get_iso_tile_size().y <= 0.0:
		warnings.append("iso_tile_height_invalid")

	if iso_wall_height <= 0.0:
		warnings.append("iso_wall_height_invalid")

	if iso_object_marker_height <= 0.0:
		warnings.append("iso_object_marker_height_invalid")

	if use_iso_placeholder_asset_preset and get_iso_placeholder_asset_path("object_generic").is_empty():
		warnings.append("iso_placeholder_asset_paths_missing")

	var alignment_diagnostics: Dictionary = get_iso_asset_alignment_diagnostics()
	if not bool(alignment_diagnostics.get("ok", false)):
		warnings.append("iso_asset_alignment_rules_missing")

	var object_png_diagnostics: Dictionary = validate_iso_object_png_assets()
	if not bool(object_png_diagnostics.get("ok", false)):
		warnings.append("iso_object_png_assets_invalid")

	if use_iso_placeholder_asset_preset and iso_placeholder_asset_preset_requires_preview and not is_iso_visual_preview_active():
		warnings.append("iso_placeholder_preset_waiting_for_preview")

	var debug_report: Dictionary = get_iso_visual_debug_report()
	if not bool(debug_report.get("single_render_path", false)):
		warnings.append("iso_single_render_path_conflict")

	var cell_stat_warnings: Array[String] = validate_iso_visual_cell_stats()
	for warning_key in cell_stat_warnings:
		warnings.append(warning_key)

	return warnings

func get_iso_visual_debug_validation_text() -> String:
	var warnings: Array[String] = validate_iso_visual_debug_report()
	if warnings.is_empty():
		return "IsoVisualDebugValidation: ok"
	var lines: Array[String] = ["IsoVisualDebugValidation:"]
	for warning_key in warnings:
		lines.append("- %s" % warning_key)
	return "\n".join(lines)

func _get_color_from_dict(data: Dictionary, key: String, fallback: Color) -> Color:
	var value: Variant = data.get(key, fallback)
	if value is Color:
		return value
	return fallback
	
const ISO_OBJECT_PNG_MIN_VISUAL_SCALE: float = 0.5
const ISO_OBJECT_PNG_MAX_VISUAL_SCALE: float = 1.5
const ISO_OBJECT_SOURCE_CANVAS_WIDTH := 512.0
const WALL_MOUNT_HEIGHT_DEVICE_SOURCE_PX := 180.0
const WALL_MOUNT_HEIGHT_LIGHT_SOURCE_PX := 330.0
const WALL_MOUNT_SIDE_OFFSET_SW := Vector2(-1.0, 0.0)
const WALL_MOUNT_SIDE_OFFSET_SE := Vector2(1.0, 0.0)
const WALL_MOUNT_SIDE_SHARED_Y_OFFSET := -3.0
const WALL_MOUNTED_COMMON_X_OFFSET := 0.0
const WALL_MOUNTED_DEVICE_HEIGHT_OFFSET := -0.0
const WALL_MOUNTED_LIGHT_HEIGHT_OFFSET := 6.0
const COOLING_WALL_CANVAS_COMMON_X_OFFSET := 0.0
const COOLING_WALL_CANVAS_COMMON_Y_OFFSET := 0.0
const AUTHORED_WALL_CANVAS_SOURCE_WIDTH: float = 512.0
const AUTHORED_WALL_CANVAS_ANCHOR_RATIO: Vector2 = Vector2(0.5, 0.75)
const AUTHORED_FLOOR_CANVAS_SOURCE_WIDTH: float = 512.0
const AUTHORED_FLOOR_CANVAS_ANCHOR_RATIO: Vector2 = Vector2(0.5, 0.5)

func get_iso_object_png_visual_rule(asset_key: String) -> Dictionary:
	var normalized_asset_key: String = asset_key.strip_edges().to_lower()
	var wall_mounted: bool = normalized_asset_key.contains("_wall_") or normalized_asset_key == "cable_reel_02" or normalized_asset_key == "light_01" or normalized_asset_key.begins_with("light_")
	var rule: Dictionary = {"anchor": "wall_mount_center" if wall_mounted else "bottom_center", "scale": 1.0, "offset": Vector2.ZERO, "expected_size": Vector2(72, 72), "layer_hint": "object", "notes": "Normalized object PNG draw size/pivot."}
	match normalized_asset_key:
		"terminal_01":
			rule["expected_size"] = Vector2(80, 78)
		"power_source_01":
			rule["expected_size"] = Vector2(84, 86)
		"radiator_01":
			rule["expected_size"] = Vector2(82, 74)
		"barrel_01", "fire_barrel_01":
			rule["expected_size"] = Vector2(58, 76)
		"case_01":
			rule["expected_size"] = Vector2(68, 56)
		"steel_box_01":
			rule["expected_size"] = Vector2(72, 60)
		"fuse_box_in_01", "fuse_box_out_01":
			rule["expected_size"] = Vector2(52, 58)
		"fuse_box_in_wall_01", "fuse_box_out_wall_01":
			rule["expected_size"] = Vector2(46, 54)
		"power_switcher_off_01", "power_switcher_on_01":
			rule["expected_size"] = Vector2(48, 42)
		"power_switcher_off_wall_01", "power_switcher_on_wall_01":
			rule["expected_size"] = Vector2(42, 42)
		"light_01", "light_off_wall_01", "light_on_wall_01", "light_on_wall_pulsar_overlay_01":
			rule["expected_size"] = Vector2(128, 120)
		"cable_reel_01", "cable_reel_02":
			rule["expected_size"] = Vector2(58, 58)
	return rule

func get_iso_object_surface_level(object_data: Dictionary) -> int:
	if object_data.has("platform_height_level"):
		return int(object_data.get("platform_height_level", 0))
	if object_data.has("height_level") and typeof(object_data.get("height_level")) in [TYPE_INT, TYPE_FLOAT]:
		return int(object_data.get("height_level", 0))
	return 0

func _parse_visual_pivot(value: Variant, fallback: Vector2) -> Vector2:
	if value is Vector2:
		return value
	if value is Array and Array(value).size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	if value is Dictionary:
		var dict: Dictionary = Dictionary(value)
		return Vector2(float(dict.get("x", fallback.x)), float(dict.get("y", fallback.y)))
	return fallback

func get_wall_mount_height_screen_px(source_height_px: float) -> float:
	return source_height_px * (get_iso_tile_size().x / ISO_OBJECT_SOURCE_CANVAS_WIDTH)

func get_wall_mounted_object_height_source_px(object_data: Dictionary, asset_key: String) -> float:
	var normalized_asset_key: String = asset_key.strip_edges().to_lower()
	var object_type: String = str(object_data.get("object_type", object_data.get("type", ""))).strip_edges().to_lower()
	var blob: String = "%s %s" % [object_type, normalized_asset_key]
	if normalized_asset_key == "light_01" or normalized_asset_key.begins_with("light_") or LightVisualServiceRef.is_light_object(object_data):
		return WALL_MOUNT_HEIGHT_LIGHT_SOURCE_PX
	if normalized_asset_key.contains("fuse_box") or blob.contains("fuse_box"):
		return WALL_MOUNT_HEIGHT_DEVICE_SOURCE_PX
	if normalized_asset_key.contains("power_switcher") or blob.contains("power_switcher") or blob.contains("switch"):
		return WALL_MOUNT_HEIGHT_DEVICE_SOURCE_PX
	if blob.contains("power_socket") or blob.contains("socket"):
		return WALL_MOUNT_HEIGHT_DEVICE_SOURCE_PX
	return WALL_MOUNT_HEIGHT_DEVICE_SOURCE_PX

func normalize_wall_visual_side(object_data: Dictionary) -> String:
	var candidates: Array[String] = [
		str(object_data.get("wall_side", "")),
		str(object_data.get("interaction_side", "")),
		str(object_data.get("facing_side", "")),
		str(object_data.get("facing_dir", "")),
		str(object_data.get("facing", "")),
		ObjectFacingServiceRef.get_facing_side(object_data)
	]

	for raw_candidate in candidates:
		var side: String = raw_candidate.strip_edges().to_lower()
		side = side.replace("-", "_")
		side = side.replace(" ", "_")

		match side:
			"sw", "south_west", "southwest", "south", "west", "left":
				return "sw"
			"se", "south_east", "southeast", "east", "right":
				return "se"

	return "sw"

func get_wall_mount_side_visual_offset(object_data: Dictionary) -> Vector2:
	var side: String = normalize_wall_visual_side(object_data)
	var half_size: Vector2 = get_iso_tile_half_size()

	# Wall-mounted objects are drawn on one of the two visible wall planes.
	# SW shifts toward the left wall plane, SE toward the right wall plane.
	if side == "se":
		return Vector2(half_size.x * 0.36, -half_size.y * 0.18)

	return Vector2(-half_size.x * 0.36, -half_size.y * 0.18)

func _draw_route_commands(commands: Array[Dictionary], fallback_profile: Dictionary = {}) -> bool:
	for command in commands:
		match str(command.get("kind", "")):
			"line":
				draw_line(
					Vector2(command.get("start", Vector2.ZERO)),
					Vector2(command.get("end", Vector2.ZERO)),
					Color(command.get("color", Color.WHITE)),
					float(command.get("width", 1.0)),
					bool(command.get("antialiased", true))
				)
			"circle":
				draw_circle(
					Vector2(command.get("center", Vector2.ZERO)),
					float(command.get("radius", 1.0)),
					Color(command.get("color", Color.WHITE))
				)
			"wall_cable_segment":
				var profile: Dictionary = fallback_profile
				if command.get("profile", {}) is Dictionary:
					profile = Dictionary(command.get("profile", {}))
				draw_iso_cable_wall_segment(
					Vector2(command.get("start", Vector2.ZERO)),
					Vector2(command.get("end", Vector2.ZERO)),
					profile
				)
	return not commands.is_empty()

func get_wall_routing_mode(object_data: Dictionary) -> String:
	return RouteRendererRef.normalize_wall_routing_mode(object_data)

func is_floor_cable_object(object_data: Dictionary) -> bool:
	return _get_wall_routed_object_family(object_data) == "cable" and get_cable_install_mode(object_data) == "floor"

func is_wall_cable_object(object_data: Dictionary) -> bool:
	if _get_wall_routed_object_family(object_data) != "cable":
		return false
	if get_cable_install_mode(object_data) == "wall":
		return true
	var placement_mode: String = str(object_data.get("placement_mode", object_data.get("placement", ""))).strip_edges().to_lower()
	var mount_mode: String = str(object_data.get("mount", "")).strip_edges().to_lower()
	var install_mode: String = str(object_data.get("install_mode", "")).strip_edges().to_lower()
	return (
		bool(object_data.get("is_wall_mounted", false))
		or placement_mode in ["wall", "wall_mounted"]
		or mount_mode == "wall"
		or install_mode == "wall"
		or _get_object_mount_mode(object_data) == "wall"
	)

func is_hidden_floor_cable_object(object_data: Dictionary) -> bool:
	return _get_wall_routed_object_family(object_data) == "cable" and get_cable_install_mode(object_data) == "hidden"

func get_cable_wall_side(object_data: Dictionary) -> String:
	return normalize_wall_visual_side(object_data)

func get_cable_wall_routing_mode(object_data: Dictionary) -> String:
	return get_wall_routing_mode(object_data)


func _get_wall_cable_face_center(cell: Vector2i, side: String) -> Vector2:
	var center: Vector2 = grid_to_iso(cell)
	var half_size: Vector2 = get_iso_tile_half_size()
	match side:
		"se":
			return center + Vector2(half_size.x * 0.36, -half_size.y * 0.18)
		_:
			return center + Vector2(-half_size.x * 0.36, -half_size.y * 0.18)

func _get_wall_cable_rail_height_px() -> float:
	return maxf(iso_wall_height * WALL_CABLE_RAIL_Y_RATIO, 1.0)

func _get_wall_cable_visual_axis_for_side(wall_side: String) -> Vector2:
	return RouteRendererRef.get_wall_visual_axis_for_side(wall_side)

func _get_wall_cable_rail_anchor(cell: Vector2i, side: String) -> Vector2:
	var segment: Dictionary = _get_wall_cable_face_line_segment(cell, side)
	return Vector2(segment.get("mid", grid_to_iso(cell)))
		
func _get_wall_cable_face_occluder_delta(face: String) -> Vector2i:
	return RouteRendererRef.get_wall_face_occluder_delta(face)

func _is_wall_cable_face_visible(cell: Vector2i, face: String) -> bool:
	if cell.x < 0 or cell.y < 0:
		return false

	var normalized_face: String = face.strip_edges().to_lower()
	if normalized_face not in ["sw", "se"]:
		return false

	var occluder_delta: Vector2i = _get_wall_cable_face_occluder_delta(normalized_face)
	if occluder_delta == Vector2i.ZERO:
		return true

	var occluder_cell: Vector2i = cell + occluder_delta

	# Грань видима только если снаружи этой грани нет другой wall-cell.
	return not _cell_has_wall_for_iso_cable(occluder_cell)
	
func _is_wall_cable_broken(object_data: Dictionary) -> bool:
	return RouteRendererRef.is_broken_route(object_data)

func _draw_wall_cable_broken_overlay_segment(start_edge: Vector2, end_edge: Vector2, normal: Vector2, profile: Dictionary) -> void:
	_draw_route_commands(RouteRendererRef.build_wall_cable_commands(start_edge, end_edge, normal, profile, true), profile)

func _draw_wall_cable_break_overlay(cell: Vector2i, face: String, profile: Dictionary) -> bool:
	if not _is_wall_cable_face_visible(cell, face):
		return false
	var segment: Dictionary = _get_wall_cable_face_line_segment(cell, face)
	return _draw_route_commands(RouteRendererRef.build_wall_break_overlay_commands(segment, profile), profile)

func _draw_wall_cable_broken_end(anchor: Vector2, away_from_gap: Vector2, normal: Vector2, profile: Dictionary) -> void:
	_draw_route_commands(RouteRendererRef.build_wall_broken_end_commands(anchor, away_from_gap, normal, profile), profile)

func _get_wall_cable_face_line_segment(cell: Vector2i, face: String) -> Dictionary:
	return RouteRendererRef.build_wall_face_segment(grid_to_iso(cell), get_iso_tile_half_size(), face, 50.0)

func _draw_wall_cable_face_half_segment(start: Vector2, end: Vector2, normal: Vector2, routing_mode: String, profile: Dictionary) -> void:
	if routing_mode.strip_edges().to_lower() == "inner":
		return
	_draw_route_commands(RouteRendererRef.build_wall_cable_commands(start, end, normal, profile, false), profile)

func _draw_wall_cable_face_segment(cell: Vector2i, face: String, routing_mode: String, profile: Dictionary, object_data: Dictionary = {}) -> bool:
	if not _is_wall_cable_face_visible(cell, face):
		return false
	if routing_mode.strip_edges().to_lower() == "inner":
		return true
	var segment: Dictionary = _get_wall_cable_face_line_segment(cell, face)
	var commands: Array[Dictionary] = RouteRendererRef.build_wall_cable_commands(
		Vector2(segment.get("start_edge", Vector2.ZERO)),
		Vector2(segment.get("end_edge", Vector2.ZERO)),
		Vector2(segment.get("normal", Vector2.UP)),
		profile,
		RouteRendererRef.is_broken_route(object_data)
	)
	_draw_route_commands(commands, profile)
	return true

func _draw_wall_cable_faces_for_cell(cell: Vector2i, object_data: Dictionary, profile: Dictionary) -> bool:
	if cell.x < 0 or cell.y < 0:
		return false

	if not _cell_has_wall_for_iso_cable(cell):
		return false

	var routing_mode: String = get_cable_wall_routing_mode(object_data).strip_edges().to_lower()

	# Inner/hidden кабель не рисуем снаружи, но считаем обработанным,
	# чтобы не падал в PNG/SVG fallback.
	if routing_mode == "inner":
		return true

	if _is_wall_cable_face_visible(cell, "sw"):
		_draw_wall_cable_face_segment(cell, "sw", routing_mode, profile, object_data)

	if _is_wall_cable_face_visible(cell, "se"):
		_draw_wall_cable_face_segment(cell, "se", routing_mode, profile, object_data)

	# Даже если обе грани скрыты, wall cable обработан.
	return true
	
func draw_wall_mounted_cable_tap(_object_data: Dictionary, _visual_center: Vector2, _profile: Dictionary, _has_terminal_visual: bool = false) -> bool:
	# Wall cable taps belonged to the old anchor/topology renderer.
	# The new wall cable renderer is face-based, so taps are intentionally disabled here.
	return false
						
func draw_wall_cable_visual_path(cell: Vector2i, object_data: Dictionary, _visual_center: Vector2, profile: Dictionary, _topology: Dictionary = {}) -> bool:
	if get_cable_install_mode(object_data) != "wall":
		return false

	if not _cell_has_wall_for_iso_cable(cell):
		return false

	# Wall cable больше не использует выбранную сторону SW/SE.
	# Он рисуется на всех видимых гранях своей wall-cell.
	# Если граней нет или routing inner — функция всё равно вернёт true,
	# чтобы объект не ушёл в PNG/SVG fallback.
	_draw_wall_cable_faces_for_cell(cell, object_data, profile)
	return true
	
func _get_cable_object_cell(object_data: Dictionary) -> Vector2i:
	return _try_parse_cell_variant(object_data.get("position", object_data.get("cell", Vector2i(-1, -1))), Vector2i(-1, -1))


func _get_wall_routed_object_family(object_data: Dictionary) -> String:
	return RouteRendererRef.get_route_family(object_data)

func is_wall_procedural_routed_object(object_data: Dictionary) -> bool:
	return RouteRendererRef.is_wall_procedural_routed_object(object_data, _get_object_mount_mode(object_data))

func get_wall_routed_height_source_px(object_data: Dictionary) -> float:
	return RouteRendererRef.get_wall_routed_height_source_px(object_data)

func get_wall_route_segment_points(visual_center: Vector2, object_data: Dictionary, _source_height_px: float) -> Dictionary:
	return RouteRendererRef.build_wall_route_segment(visual_center, get_iso_tile_half_size(), normalize_wall_visual_side(object_data))

func _draw_wall_routed_dashed_line(start: Vector2, end: Vector2, dash_length: float, gap_length: float, color: Color, width: float) -> void:
	var delta: Vector2 = end - start
	var length: float = delta.length()
	if length <= 0.1:
		return
	var direction: Vector2 = delta / length
	var cursor: float = 0.0
	while cursor < length:
		var dash_end: float = minf(cursor + dash_length, length)
		draw_line(start + direction * cursor, start + direction * dash_end, color, width, true)
		cursor += dash_length + gap_length

func _get_wall_cable_center(visual_center: Vector2, object_data: Dictionary) -> Vector2:
	var segment: Dictionary = get_wall_route_segment_points(visual_center, object_data, get_wall_routed_height_source_px(object_data))
	return Vector2(segment.get("start", visual_center)).lerp(Vector2(segment.get("end", visual_center)), 0.5)

func draw_wall_topology_cable(cell: Vector2i, object_data: Dictionary, visual_center: Vector2, profile: Dictionary) -> bool:
	if not is_wall_cable_object(object_data):
		return false

	# Old anchor/corner topology is intentionally bypassed.
	# Wall cable is now rendered per visible wall face.
	return draw_wall_cable_visual_path(cell, object_data, visual_center, profile, {})
	
func draw_wall_procedural_cable(segment: Dictionary, routing_mode: String) -> bool:
	return _draw_route_commands(RouteRendererRef.build_procedural_route_commands("cable", segment, routing_mode))

func draw_wall_procedural_air_duct(segment: Dictionary, routing_mode: String) -> bool:
	return _draw_route_commands(RouteRendererRef.build_procedural_route_commands("air_duct", segment, routing_mode))

func draw_wall_procedural_water_pipe(segment: Dictionary, routing_mode: String) -> bool:
	return _draw_route_commands(RouteRendererRef.build_procedural_route_commands("water_pipe", segment, routing_mode))

func is_wall_routing_utility_object(object_data: Dictionary) -> bool:
	return WallRoutingValidationServiceRef.is_wall_routing_utility_object(object_data)

func _wall_route_side_to_visible_face(wall_side: String) -> String:
	match wall_side.strip_edges().to_upper():
		"NW", "SW":
			return "sw"
		"NE", "SE":
			return "se"
	return ""

func draw_wall_routing_utility(cell: Vector2i, object_data: Dictionary, visual_center: Vector2) -> bool:
	if not is_wall_routing_utility_object(object_data):
		return false
	if is_authored_cooling_wall_canvas_object(object_data):
		var faces: Array[String] = get_cooling_wall_canvas_visible_faces(object_data)
		return draw_cooling_wall_canvas_asset_for_faces(cell, object_data, faces)
	if get_wall_routing_mode(object_data) == "inner":
		for side_key in ["wall_side_1", "wall_side_2"]:
			draw_inner_wall_route_port(cell, object_data, str(object_data.get(side_key, "")), visual_center)
		return true
	return draw_outer_wall_route_surface(cell, object_data, visual_center)

func get_inner_wall_route_asset_id(object_data: Dictionary) -> String:
	var kind: String = str(object_data.get("routing_kind", _get_wall_routed_object_family(object_data))).strip_edges().to_lower()
	match kind:
		"air_duct":
			return "air_duct_inner_wall_01"
		"water_pipe":
			return "water_pipe_inner_wall_01"
	return ""

func is_authored_cooling_wall_canvas_object(object_data: Dictionary) -> bool:
	var object_type: String = str(object_data.get("object_type", object_data.get("type", ""))).strip_edges().to_lower()
	var routing_kind: String = str(object_data.get("routing_kind", _get_wall_routed_object_family(object_data))).strip_edges().to_lower()
	var asset_id: String = get_inner_wall_route_asset_id(object_data)
	return (
		(object_type == "external_air_duct" and routing_kind == "air_duct" and asset_id == "air_duct_inner_wall_01")
		or (object_type == "external_water_pipe" and routing_kind == "water_pipe" and asset_id == "water_pipe_inner_wall_01")
	)

func get_wall_canvas_asset_key_for_cell(cell: Vector2i) -> String:
	var material_override: Dictionary = _get_wall_material_override_for_cell(cell)
	var wall_profile_key: String = get_wall_visual_profile_key_for_cell(cell)
	if use_gray_room_visual_test_assets:
		return get_test_wall_height_asset_key(material_override, cell, get_iso_wall_depth_bounds())
	return get_production_wall_asset_key(material_override, cell, wall_profile_key, get_iso_wall_depth_bounds())

func get_cooling_wall_canvas_visible_faces(object_data: Dictionary) -> Array[String]:
	var faces: Array[String] = []

	if get_wall_routing_mode(object_data) == "inner":
		for side_key in ["wall_side_1", "wall_side_2"]:
			var face: String = _wall_route_side_to_visible_face(str(object_data.get(side_key, "")))
			if not face.is_empty() and face not in faces:
				faces.append(face)
	else:
		var fallback_face: String = normalize_wall_visual_side(object_data)
		if not fallback_face.is_empty():
			faces.append(fallback_face)

	if faces.is_empty():
		faces.append("sw")
		faces.append("se")

	return faces

func _get_cooling_wall_canvas_region(region_key: String, full_size: Vector2) -> Rect2:
	var normalized_region: Rect2 = Rect2(0.0, 0.0, 1.0, 1.0)
	if ISO_COOLING_WALL_CANVAS_FACE_REGIONS.has(region_key):
		normalized_region = Rect2(ISO_COOLING_WALL_CANVAS_FACE_REGIONS.get(region_key))
	return Rect2(
		Vector2(full_size.x * normalized_region.position.x, full_size.y * normalized_region.position.y),
		Vector2(full_size.x * normalized_region.size.x, full_size.y * normalized_region.size.y)
	)

func draw_cooling_wall_canvas_asset_for_faces(cell: Vector2i, object_data: Dictionary, faces: Array[String]) -> bool:
	var asset_id: String = get_inner_wall_route_asset_id(object_data)
	if asset_id.is_empty():
		return false
	var texture_path: String = get_iso_object_png_asset_path(asset_id, {"visual_id": asset_id})
	if texture_path.is_empty():
		return false
	var texture: Texture2D = get_iso_object_png_texture_for_resolved_path(asset_id, texture_path)
	if texture == null:
		return false
	var texture_size: Vector2 = texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return false
	var wall_canvas_asset_key: String = get_wall_canvas_asset_key_for_cell(cell)
	var texture_rect: Rect2 = get_iso_wall_texture_draw_rect_for_cell(cell, texture, wall_canvas_asset_key, get_wall_render_topology(cell))
	if texture_rect.size.x <= 0.0 or texture_rect.size.y <= 0.0:
		return false
	texture_rect.position += Vector2(COOLING_WALL_CANVAS_COMMON_X_OFFSET, COOLING_WALL_CANVAS_COMMON_Y_OFFSET)

	if "sw" in faces and "se" in faces:
		log_wall_mounted_positioning(object_data, "cooling_wall_canvas_whole", str(object_data.get("wall_side", object_data.get("interaction_side", ""))), "sw,se", texture_rect.position + Vector2(texture_rect.size.x * 0.5, texture_rect.size.y), texture_rect, false)
		draw_texture_rect_region(texture, texture_rect, Rect2(Vector2.ZERO, texture_size))
	else:
		for face in faces:
			if face not in ISO_COOLING_WALL_CANVAS_FACE_REGIONS:
				continue
			var source_region: Rect2 = _get_cooling_wall_canvas_region(face, texture_size)
			var destination_region: Rect2 = _get_cooling_wall_canvas_region(face, texture_rect.size)
			destination_region.position += texture_rect.position
			log_wall_mounted_positioning(object_data, "cooling_wall_canvas_face_region", str(object_data.get("wall_side", object_data.get("interaction_side", ""))), face, destination_region.position + Vector2(destination_region.size.x * 0.5, destination_region.size.y), destination_region, false)
			draw_texture_rect_region(texture, destination_region, source_region)

	draw_iso_asset_alignment_overlay(asset_id, texture_rect.position + Vector2(texture_rect.size.x * 0.5, texture_rect.size.y), texture_rect)
	return true

func draw_cooling_wall_canvas_asset(cell: Vector2i, object_data: Dictionary) -> bool:
	var asset_id: String = get_inner_wall_route_asset_id(object_data)
	if asset_id.is_empty():
		return false
	var texture_path: String = get_iso_object_png_asset_path(asset_id, {"visual_id": asset_id})
	if texture_path.is_empty():
		return false
	var texture: Texture2D = get_iso_object_png_texture_for_resolved_path(asset_id, texture_path)
	if texture == null:
		return false
	var texture_size: Vector2 = texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return false
	var wall_canvas_asset_key: String = get_wall_canvas_asset_key_for_cell(cell)
	var texture_rect: Rect2 = get_iso_wall_texture_draw_rect_for_cell(cell, texture, wall_canvas_asset_key, get_wall_render_topology(cell))
	if texture_rect.size.x <= 0.0 or texture_rect.size.y <= 0.0:
		return false
	texture_rect.position += Vector2(COOLING_WALL_CANVAS_COMMON_X_OFFSET, COOLING_WALL_CANVAS_COMMON_Y_OFFSET)
	log_wall_mounted_positioning(object_data, "cooling_wall_canvas_legacy_whole", str(object_data.get("wall_side", object_data.get("interaction_side", ""))), normalize_wall_visual_side(object_data), texture_rect.position + Vector2(texture_rect.size.x * 0.5, texture_rect.size.y), texture_rect, false)
	draw_texture_rect_region(texture, texture_rect, Rect2(Vector2.ZERO, texture_size))
	draw_iso_asset_alignment_overlay(asset_id, texture_rect.position + Vector2(texture_rect.size.x * 0.5, texture_rect.size.y), texture_rect)
	return true

func draw_inner_wall_route_asset(cell: Vector2i, object_data: Dictionary, wall_side: String) -> bool:
	var asset_id: String = get_inner_wall_route_asset_id(object_data)
	if asset_id.is_empty():
		return false
	var face: String = _wall_route_side_to_visible_face(wall_side)
	if face.is_empty() or not _is_wall_cable_face_visible(cell, face):
		return true
	var texture_path: String = get_iso_object_png_asset_path(asset_id, {"visual_id": asset_id})
	if texture_path.is_empty():
		return false
	var texture: Texture2D = get_iso_object_png_texture_for_resolved_path(asset_id, texture_path)
	if texture == null:
		return false
	var segment: Dictionary = _get_wall_cable_face_line_segment(cell, face)
	var anchor: Vector2 = Vector2(segment.get("mid", grid_to_iso(cell)))
	var texture_size: Vector2 = texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return false
	var scale_value: float = get_iso_tile_size().x / texture_size.x
	var destination_size: Vector2 = texture_size * scale_value
	var destination_rect: Rect2 = Rect2(anchor - Vector2(destination_size.x * 0.5, destination_size.y), destination_size)
	if face == "se":
		draw_set_transform(destination_rect.position + Vector2(destination_rect.size.x, 0.0), 0.0, Vector2(-1.0, 1.0))
		draw_texture_rect_region(texture, Rect2(Vector2.ZERO, destination_rect.size), Rect2(Vector2.ZERO, texture_size))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		draw_texture_rect_region(texture, destination_rect, Rect2(Vector2.ZERO, texture_size))
	draw_iso_asset_alignment_overlay(asset_id, anchor, destination_rect)
	return true

func draw_inner_wall_route_port(cell: Vector2i, object_data: Dictionary, wall_side: String, _visual_center: Vector2) -> void:
	if draw_inner_wall_route_asset(cell, object_data, wall_side):
		return
	var face: String = _wall_route_side_to_visible_face(wall_side)
	if face.is_empty() or not _is_wall_cable_face_visible(cell, face):
		return
	var segment: Dictionary = _get_wall_cable_face_line_segment(cell, face)
	var center: Vector2 = Vector2(segment.get("mid", grid_to_iso(cell)))
	var axis: Vector2 = Vector2(segment.get("end_edge", center)) - Vector2(segment.get("start_edge", center))
	if axis.length() <= 0.001:
		return
	axis = axis.normalized()
	var normal: Vector2 = Vector2(segment.get("normal", Vector2.UP)).normalized()
	var kind: String = str(object_data.get("routing_kind", _get_wall_routed_object_family(object_data))).strip_edges().to_lower()
	if kind == "water_pipe":
		draw_circle(center, 7.5, Color(0.02, 0.03, 0.035, 0.96))
		draw_circle(center, 5.2, Color(0.005, 0.007, 0.010, 0.98))
		draw_arc(center, 7.5, -0.8, 2.6, 14, Color(0.64, 0.86, 0.92, 0.55), 1.5, true)
		return
	var half_width: float = 12.0
	var half_height: float = 5.5
	var points: PackedVector2Array = PackedVector2Array([
		center - axis * half_width - normal * half_height,
		center + axis * half_width - normal * half_height,
		center + axis * half_width + normal * half_height,
		center - axis * half_width + normal * half_height
	])
	draw_colored_polygon(points, Color(0.005, 0.007, 0.010, 0.96))
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), Color(0.45, 0.52, 0.58, 0.55), 1.4, true)

func draw_outer_wall_route_surface(cell: Vector2i, object_data: Dictionary, _visual_center: Vector2) -> bool:
	var face: String = normalize_wall_visual_side(object_data)
	if not _is_wall_cable_face_visible(cell, face):
		return true
	var segment: Dictionary = _get_wall_cable_face_line_segment(cell, face)
	var center: Vector2 = Vector2(segment.get("mid", grid_to_iso(cell))) + Vector2(segment.get("normal", Vector2.UP)).normalized() * OUTER_UTILITY_VERTICAL_OFFSET_SCALE
	var width: float = 4.0 * OUTER_UTILITY_WIDTH_SCALE
	var kind: String = str(object_data.get("routing_kind", _get_wall_routed_object_family(object_data))).strip_edges().to_lower()
	if kind == "water_pipe":
		draw_line(Vector2(segment.get("start_edge", center)), Vector2(segment.get("end_edge", center)), Color(0.08, 0.11, 0.13, 0.98), width, true)
		draw_line(Vector2(segment.get("start_edge", center)), Vector2(segment.get("end_edge", center)), Color(0.36, 0.70, 0.80, 0.98), width * 0.62, true)
	else:
		draw_line(Vector2(segment.get("start_edge", center)), Vector2(segment.get("end_edge", center)), Color(0.08, 0.09, 0.10, 0.98), width * OUTER_UTILITY_HEIGHT_SCALE, true)
		draw_line(Vector2(segment.get("start_edge", center)), Vector2(segment.get("end_edge", center)), Color(0.47, 0.54, 0.60, 0.98), width * 1.55, true)
	return true

func draw_wall_procedural_routed_object(cell: Vector2i, object_data: Dictionary, visual_center: Vector2) -> bool:
	if not is_wall_procedural_routed_object(object_data):
		return false

	var family: String = _get_wall_routed_object_family(object_data)

	if family == "cable":
		# Кабель обрабатывается новым face-based renderer.
		# Не даём ему падать в object PNG/SVG fallback.
		return draw_wall_topology_cable(cell, object_data, visual_center, get_iso_object_profile("cable"))

	if is_wall_routing_utility_object(object_data):
		return draw_wall_routing_utility(cell, object_data, visual_center)

	var routing_mode: String = get_wall_routing_mode(object_data)
	var source_height_px: float = get_wall_routed_height_source_px(object_data)
	var segment: Dictionary = get_wall_route_segment_points(visual_center, object_data, source_height_px)

	match family:
		"air_duct":
			return draw_wall_procedural_air_duct(segment, routing_mode)
		"water_pipe":
			return draw_wall_procedural_water_pipe(segment, routing_mode)

	return false
	
func draw_wall_routed_procedural_visual(object_data: Dictionary, _profile: Dictionary, fallback_cell: Vector2i) -> bool:
	var visual_center: Vector2 = get_wall_mounted_visual_center(object_data, fallback_cell)
	return draw_wall_procedural_routed_object(fallback_cell, object_data, visual_center)

func get_safe_iso_object_png_visual_scale(object_data: Dictionary, asset_key: String, rule: Dictionary = {}) -> float:
	var active_rule: Dictionary = rule
	if active_rule.is_empty():
		active_rule = get_iso_asset_alignment_rule(asset_key)
	return ObjectRendererRef.get_safe_visual_scale(
		object_data,
		active_rule,
		ISO_OBJECT_PNG_MIN_VISUAL_SCALE,
		ISO_OBJECT_PNG_MAX_VISUAL_SCALE,
		is_iso_object_png_asset_key(asset_key)
	)

func build_iso_object_surface_context(object_data: Dictionary, _cell_visual_center: Vector2 = Vector2.INF) -> Dictionary:
	var surface_level: int = get_iso_object_surface_level(object_data)
	var rule: Dictionary = {}
	if object_data.get("rule", {}) is Dictionary:
		rule = Dictionary(object_data.get("rule", {}))
	elif object_data.get("alignment_rule", {}) is Dictionary:
		rule = Dictionary(object_data.get("alignment_rule", {}))
	elif object_data.get("visual_rule", {}) is Dictionary:
		rule = Dictionary(object_data.get("visual_rule", {}))
	var policy: Dictionary = ObjectRendererRef.get_surface_context_policy(object_data, rule)
	if bool(policy.get("wall_mounted", false)):
		return IsoVisualAlignmentServiceRef.build_surface_context(surface_level, 0.0, 0.0, true)
	if bool(policy.get("has_explicit_surface_y_offset", false)):
		return {"explicit_surface_y_offset": float(policy.get("explicit_surface_y_offset", 0.0)), "surface_level": surface_level, "wall_mounted": false}
	var platform_offset: float = 0.0
	if bool(policy.get("uses_platform_offset", false)):
		platform_offset = IsoVisualAlignmentServiceRef.get_platform_surface_y_offset(object_data)
	return IsoVisualAlignmentServiceRef.build_surface_context(surface_level, float(policy.get("ground_surface_y_offset", 0.0)), platform_offset, false)

func build_iso_object_visual_descriptor(object_data: Dictionary, asset_key: String, visual_center: Vector2, texture: Texture2D = null) -> Dictionary:
	var rule: Dictionary = get_iso_asset_alignment_rule(asset_key)
	var expected_size: Vector2 = get_iso_asset_alignment_expected_size(asset_key)
	var visual_scale: float = get_safe_iso_object_png_visual_scale(object_data, asset_key, rule)
	var destination_size: Vector2 = expected_size * visual_scale
	var default_pivot: Vector2 = get_iso_asset_alignment_anchor_offset(str(rule.get("anchor", "bottom_center")), destination_size)
	var visual_pivot: Vector2 = _parse_visual_pivot(object_data.get("visual_pivot", default_pivot), default_pivot)
	var surface_level: int = get_iso_object_surface_level(object_data)
	var surface_context: Dictionary = build_iso_object_surface_context(object_data, visual_center)
	var surface_y_offset: float = IsoVisualAlignmentServiceRef.get_object_surface_y_offset(surface_context)
	var explicit_visual_offset: Vector2 = _parse_visual_pivot(object_data.get("visual_offset", Vector2.ZERO), Vector2.ZERO)
	var wall_mounted: bool = bool(ObjectRendererRef.get_surface_context_policy(object_data, rule).get("wall_mounted", false))
	var wall_visual_side: String = normalize_wall_visual_side(object_data) if wall_mounted else ""
	var mirror_h: bool = (wall_visual_side == "se" and bool(object_data.get("mirror_visual_for_facing_side", true))) if wall_mounted else (ObjectFacingServiceRef.get_facing_side(object_data) == ObjectFacingServiceRef.FACING_SIDE_SE and bool(object_data.get("mirror_visual_for_facing_side", true)))
	var descriptor: Dictionary = ObjectRendererRef.build_descriptor_for_contract({
		"descriptor_mode": "object",
		"visual_asset_key": asset_key,
		"texture": texture,
		"render_contract": VisualAssetRenderContractServiceRef.CONTRACT_OBJECT_SPRITE,
		"expected_size": expected_size,
		"source_size": texture.get_size() if texture != null else expected_size,
		"visual_scale": visual_scale,
		"visual_pivot": visual_pivot,
		"surface_level": surface_level,
		"surface_context": surface_context,
		"surface_y_offset": surface_y_offset,
		"visual_center": visual_center,
		"rule_offset": Vector2(rule.get("offset", Vector2.ZERO)),
		"explicit_visual_offset": explicit_visual_offset,
		"wall_mounted": wall_mounted,
		"mirror_h": mirror_h
	})
	if wall_mounted:
		var raw_wall_side: String = str(object_data.get("wall_side", object_data.get("interaction_side", ""))).strip_edges().to_lower()
		log_wall_mounted_positioning(object_data, "iso_object_png_descriptor", raw_wall_side, wall_visual_side, visual_center, Rect2(descriptor.get("destination_rect", Rect2())), true)
	return descriptor

func build_authored_wall_canvas_descriptor(object_data: Dictionary, asset_key: String, texture_path: String, visual_center: Vector2, texture: Texture2D) -> Dictionary:
	var descriptor: Dictionary = ObjectRendererRef.build_descriptor_for_contract({
		"descriptor_mode": "authored_canvas",
		"visual_asset_key": asset_key,
		"texture": texture,
		"texture_path": texture_path,
		"render_contract": VisualAssetRenderContractServiceRef.CONTRACT_WALL_AUTHORED_CANVAS,
		"texture_size": texture.get_size(),
		"tile_size": get_iso_tile_size(),
		"source_width": authored_wall_canvas_source_width,
		"anchor_ratio": authored_wall_canvas_anchor_ratio,
		"visual_center": visual_center,
		"explicit_visual_offset": _parse_visual_pivot(object_data.get("visual_offset", Vector2.ZERO), Vector2.ZERO),
		"surface_level": get_iso_object_surface_level(object_data),
		"mirror_h": ObjectFacingServiceRef.get_facing_side(object_data) == ObjectFacingServiceRef.FACING_SIDE_SE and bool(object_data.get("mirror_visual_for_facing_side", true))
	})
	log_authored_canvas_descriptor(object_data, asset_key, texture_path, descriptor)
	return descriptor

func build_authored_floor_canvas_descriptor(object_data: Dictionary, asset_key: String, texture_path: String, visual_center: Vector2, texture: Texture2D) -> Dictionary:
	var descriptor: Dictionary = ObjectRendererRef.build_descriptor_for_contract({
		"descriptor_mode": "authored_canvas",
		"visual_asset_key": asset_key,
		"texture": texture,
		"texture_path": texture_path,
		"render_contract": VisualAssetRenderContractServiceRef.CONTRACT_FLOOR_AUTHORED_CANVAS,
		"texture_size": texture.get_size(),
		"tile_size": get_iso_tile_size(),
		"source_width": authored_floor_canvas_source_width,
		"anchor_ratio": authored_floor_canvas_anchor_ratio,
		"visual_center": visual_center,
		"explicit_visual_offset": _parse_visual_pivot(object_data.get("visual_offset", Vector2.ZERO), Vector2.ZERO),
		"surface_level": get_iso_object_surface_level(object_data),
		"mirror_h": ObjectFacingServiceRef.get_facing_side(object_data) == ObjectFacingServiceRef.FACING_SIDE_SE and bool(object_data.get("mirror_visual_for_facing_side", true))
	})
	log_authored_canvas_descriptor(object_data, asset_key, texture_path, descriptor)
	return descriptor

func log_authored_canvas_descriptor(object_data: Dictionary, asset_key: String, texture_path: String, descriptor: Dictionary) -> void:
	if not debug_log_iso_object_asset_resolution:
		return
	var texture: Texture2D = descriptor.get("texture", null) as Texture2D
	var texture_size: Vector2 = texture.get_size() if texture != null else Vector2.ZERO
	print("[IsoAuthoredCanvas] object_id=%s asset_key=%s texture_path=%s render_contract=%s texture_size=%s visual_scale=%s destination_rect=%s mirror_h=%s" % [
		str(object_data.get("id", object_data.get("object_id", ""))),
		asset_key,
		texture_path,
		str(descriptor.get("render_contract", "")),
		str(texture_size),
		str(descriptor.get("visual_scale", 1.0)),
		str(descriptor.get("destination_rect", Rect2())),
		str(descriptor.get("mirror_h", false))
	])

func build_iso_object_visual_descriptor_for_contract(object_data: Dictionary, asset_key: String, texture_path: String, render_contract: String, visual_center: Vector2, texture: Texture2D) -> Dictionary:
	match ObjectRendererRef.get_descriptor_mode(render_contract, VisualAssetRenderContractServiceRef.CONTRACT_WALL_AUTHORED_CANVAS, VisualAssetRenderContractServiceRef.CONTRACT_FLOOR_AUTHORED_CANVAS):
		"wall_authored":
			return build_authored_wall_canvas_descriptor(object_data, asset_key, texture_path, visual_center, texture)
		"floor_authored":
			return build_authored_floor_canvas_descriptor(object_data, asset_key, texture_path, visual_center, texture)
	return build_iso_object_visual_descriptor(object_data, asset_key, visual_center, texture)

func draw_iso_object_png_texture_with_descriptor_modulated(texture: Texture2D, descriptor: Dictionary, modulate_color: Color, destination_rect_override: Rect2 = Rect2()) -> void:
	var destination_rect: Rect2 = Rect2(descriptor.get("destination_rect", Rect2()))
	if destination_rect_override.size != Vector2.ZERO:
		destination_rect = destination_rect_override
	var source_rect: Rect2 = Rect2(descriptor.get("source_rect", Rect2(Vector2.ZERO, texture.get_size())))
	if bool(descriptor.get("mirror_h", false)):
		draw_set_transform(destination_rect.position + Vector2(destination_rect.size.x, 0.0), 0.0, Vector2(-1.0, 1.0))
		draw_texture_rect_region(texture, Rect2(Vector2.ZERO, destination_rect.size), source_rect, modulate_color)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		draw_texture_rect_region(texture, destination_rect, source_rect, modulate_color)

func draw_iso_object_png_texture_with_descriptor(texture: Texture2D, descriptor: Dictionary) -> void:
	var destination_rect: Rect2 = Rect2(descriptor.get("destination_rect", Rect2()))
	draw_iso_object_png_texture_with_descriptor_modulated(texture, descriptor, Color.WHITE)
	draw_iso_asset_alignment_overlay(str(descriptor.get("visual_asset_key", "")), destination_rect.position + Vector2(descriptor.get("visual_pivot", destination_rect.size * 0.5)), destination_rect)
	if debug_log_iso_object_asset_resolution:
		print("[IsoObjectVisual] visual_asset_key=%s visual_scale=%s visual_pivot=%s surface_level=%s surface_y_offset=%s final_draw_position=%s" % [str(descriptor.get("visual_asset_key", "")), str(descriptor.get("visual_scale", 1.0)), str(descriptor.get("visual_pivot", Vector2.ZERO)), str(descriptor.get("surface_level", 0)), str(descriptor.get("surface_y_offset", 0.0)), str(descriptor.get("final_draw_position", Vector2.ZERO))])

func draw_visual_state_overlays_for_descriptor(object_data: Dictionary, descriptor: Dictionary) -> void:
	var overlay_asset_keys: Array[String] = VisualStateAssetServiceRef.resolve_overlay_asset_ids(object_data, str(descriptor.get("visual_asset_key", "")))
	if overlay_asset_keys.is_empty():
		return
	var base_rect: Rect2 = Rect2(descriptor.get("destination_rect", Rect2()))
	var expand_amount: float = maxf(2.0, minf(base_rect.size.x, base_rect.size.y) * 0.035)
	var glow_rect: Rect2 = base_rect.grow(expand_amount)
	var time_seconds: float = float(Time.get_ticks_msec()) / 1000.0
	for overlay_asset_key in overlay_asset_keys:
		var overlay_texture: Texture2D = get_iso_object_png_texture_for_asset_key(overlay_asset_key)
		if overlay_texture == null:
			continue
		var overlay_descriptor: Dictionary = descriptor.duplicate(true)
		overlay_descriptor["visual_asset_key"] = overlay_asset_key
		overlay_descriptor["texture"] = overlay_texture
		draw_iso_object_png_texture_with_descriptor_modulated(overlay_texture, overlay_descriptor, Color(1.0, 1.0, 1.0, VisualStateAssetServiceRef.get_soft_glow_alpha(time_seconds, object_data)), glow_rect)
		draw_iso_object_png_texture_with_descriptor_modulated(overlay_texture, overlay_descriptor, Color(1.0, 1.0, 1.0, VisualStateAssetServiceRef.get_pulsar_overlay_alpha(time_seconds, object_data)))
		_iso_light_overlay_animation_requested = true

func get_iso_asset_alignment_rule(asset_key: String) -> Dictionary:
	var rule: Dictionary = {}

	if ISO_ASSET_ALIGNMENT_RULES.has(asset_key):
		var raw_rule: Variant = ISO_ASSET_ALIGNMENT_RULES.get(asset_key, {})
		if raw_rule is Dictionary:
			rule = Dictionary(raw_rule).duplicate(true)
		else:
			rule = {}
	elif asset_key.begins_with("floor_"):
		rule = {
			"anchor": "center",
			"scale": 1.0,
			"offset": Vector2.ZERO,
			"expected_size": get_iso_tile_size(),
			"layer_hint": "floor",
			"notes": "Fallback floor alignment."
		}
	elif asset_key.begins_with("wall_"):
		rule = {
			"anchor": "wall_cell_base",
			"scale": 1.0,
			"offset": Vector2(0, -get_iso_tile_half_size().y),
			"expected_size": Vector2(128, 120),
			"layer_hint": "wall",
			"notes": "Fallback wall alignment against the active 128x71 footprint."
		}
	elif asset_key == "object_door":
		rule = {
			"anchor": "door_insert_center",
			"scale": 0.9,
			"offset": Vector2(0, -20),
			"expected_size": Vector2(96, 96),
			"layer_hint": "object",
			"notes": "Fallback door alignment."
		}
	elif asset_key.begins_with("object_"):
		rule = {
			"anchor": "bottom_center",
			"scale": 0.75,
			"offset": Vector2(0, -8),
			"expected_size": Vector2(96, 96),
			"layer_hint": "object",
			"notes": "Fallback object alignment."
		}
	elif is_iso_object_png_asset_key(asset_key):
		rule = get_iso_object_png_visual_rule(asset_key)
	else:
		rule = {
			"anchor": "center",
			"scale": 1.0,
			"offset": Vector2.ZERO,
			"expected_size": Vector2(96, 96),
			"layer_hint": "unknown",
			"notes": "Fallback generic alignment."
		}

	if asset_key.begins_with("floor_"):
		rule["expected_size"] = get_iso_tile_size()

	if str(rule.get("anchor", "")) == "wall_cell_base":
		var offset: Vector2 = Vector2(rule.get("offset", Vector2.ZERO))
		if is_equal_approx(offset.y, -ISO_CLASSIC_TILE_SIZE.y * 0.5):
			rule["offset"] = Vector2(offset.x, -get_iso_tile_half_size().y)

	return rule

func get_iso_asset_alignment_scale(asset_key: String) -> float:
	var rule: Dictionary = get_iso_asset_alignment_rule(asset_key)
	var scale_value: float = float(rule.get("scale", 1.0))
	return maxf(scale_value, 0.01)

func get_iso_asset_alignment_expected_size(asset_key: String) -> Vector2:
	var rule: Dictionary = get_iso_asset_alignment_rule(asset_key)
	return Vector2(rule.get("expected_size", Vector2(96, 96)))

func get_iso_asset_alignment_anchor_offset(anchor: String, size: Vector2) -> Vector2:
	match anchor:
		"center", "wall_mount_center", "door_insert_center":
			return Vector2(size.x * 0.5, size.y * 0.5)
		"bottom_center", "wall_cell_base":
			return Vector2(size.x * 0.5, size.y)
		_:
			return Vector2(size.x * 0.5, size.y * 0.5)

func get_iso_texture_draw_position_from_center(center: Vector2, texture: Texture2D) -> Vector2:
	var size: Vector2 = texture.get_size()
	return center - Vector2(size.x * 0.5, size.y * 0.75)

func get_iso_texture_draw_rect_for_asset_key_with_size(asset_key: String, center: Vector2, source_size: Vector2) -> Rect2:
	var rule: Dictionary = get_iso_asset_alignment_rule(asset_key)
	var anchor: String = str(rule.get("anchor", "center"))
	var scale_value: float = get_iso_asset_alignment_scale(asset_key)
	var destination_size: Vector2 = source_size * scale_value

	if asset_key.begins_with("floor_") or asset_key.begins_with("object_") or is_iso_object_png_asset_key(asset_key):
		destination_size = get_iso_asset_alignment_expected_size(asset_key) * scale_value

	var offset: Vector2 = Vector2(rule.get("offset", Vector2.ZERO))
	var anchor_offset: Vector2 = get_iso_asset_alignment_anchor_offset(anchor, destination_size)
	var destination_position: Vector2 = center - anchor_offset + offset

	return Rect2(destination_position, destination_size)
		
func get_iso_texture_draw_rect_for_asset_key(asset_key: String, center: Vector2, texture: Texture2D) -> Rect2:
	if texture == null:
		return get_iso_texture_draw_rect_for_asset_key_with_size(asset_key, center, get_iso_asset_alignment_expected_size(asset_key))

	return get_iso_texture_draw_rect_for_asset_key_with_size(asset_key, center, texture.get_size())
	
func get_iso_texture_draw_position_for_asset_key(asset_key: String, center: Vector2, texture: Texture2D) -> Vector2:
	return get_iso_texture_draw_rect_for_asset_key(asset_key, center, texture).position

func get_iso_texture_draw_position(cell: Vector2i, texture: Texture2D) -> Vector2:
	return get_iso_texture_draw_position_from_center(grid_to_iso(cell), texture)

func should_draw_iso_asset_with_rect(asset_key: String) -> bool:
	var rule: Dictionary = get_iso_asset_alignment_rule(asset_key)
	var scale_value: float = get_iso_asset_alignment_scale(asset_key)
	var offset: Vector2 = Vector2(rule.get("offset", Vector2.ZERO))
	var anchor: String = str(rule.get("anchor", "center"))
	if not is_equal_approx(scale_value, 1.0):
		return true
	if offset != Vector2.ZERO:
		return true
	return anchor != "center"


func draw_iso_asset_alignment_overlay(asset_key: String, anchor_position: Vector2, actual_rect: Rect2) -> void:
	if not show_asset_alignment_overlay and not show_object_grounding_overlay:
		return
	var expected_size: Vector2 = get_iso_asset_alignment_expected_size(asset_key) * get_iso_asset_alignment_scale(asset_key)
	var rule: Dictionary = get_iso_asset_alignment_rule(asset_key)
	var expected_anchor_offset: Vector2 = get_iso_asset_alignment_anchor_offset(str(rule.get("anchor", "center")), expected_size)
	var expected_rect: Rect2 = Rect2(anchor_position - expected_anchor_offset + Vector2(rule.get("offset", Vector2.ZERO)), expected_size)
	_draw_overlay_commands(RuntimeDebugOverlayRendererRef.build_asset_alignment_commands({
		"asset_key": asset_key,
		"anchor_position": anchor_position,
		"expected_rect": expected_rect,
		"actual_rect": actual_rect,
	}))

func draw_iso_texture_with_alignment(texture: Texture2D, asset_key: String, center: Vector2) -> void:
	var destination_rect: Rect2 = get_iso_texture_draw_rect_for_asset_key(asset_key, center, texture)
	if should_draw_iso_asset_with_rect(asset_key):
		draw_texture_rect(texture, destination_rect, false)
	else:
		draw_texture(texture, destination_rect.position)
	draw_iso_asset_alignment_overlay(asset_key, center, destination_rect)

func draw_iso_texture_asset(cell: Vector2i, asset_key: String, visual_center_override: Vector2 = Vector2.INF) -> bool:
	# Asset hooks are optional. Procedural fallback remains the default path.
	if not should_use_iso_tile_asset_hook_visuals():
		return false
	if asset_key.is_empty():
		return false
	var texture: Texture2D = get_iso_texture_for_asset_key(asset_key)
	if texture == null:
		return false
	var visual_center: Vector2 = grid_to_iso(cell)
	if visual_center_override != Vector2.INF:
		visual_center = visual_center_override
	draw_iso_texture_with_alignment(texture, asset_key, visual_center)
	return true

func draw_iso_object_png_texture_asset(cell: Vector2i, asset_key: String, visual_center_override: Vector2 = Vector2.INF, object_data: Dictionary = {}) -> bool:
	if not should_use_iso_tile_asset_hook_visuals():
		return false
	var normalized_asset_key: String = asset_key.strip_edges().to_lower()
	var local_object_data: Dictionary = object_data.duplicate(true)
	var visual_state_descriptor: Dictionary = {}
	if VisualStateAssetServiceRef.object_uses_visual_states(local_object_data):
		visual_state_descriptor = VisualStateAssetServiceRef.resolve_visual_asset_descriptor(local_object_data).duplicate(true)
		normalized_asset_key = str(visual_state_descriptor.get("asset_id", normalized_asset_key))
	var path_descriptor: Dictionary = visual_state_descriptor.duplicate(true) if not visual_state_descriptor.is_empty() else local_object_data.duplicate(true)
	if not path_descriptor.has("visual_id"):
		path_descriptor["visual_id"] = normalized_asset_key
	if not path_descriptor.has("visual_asset_id"):
		path_descriptor["visual_asset_id"] = normalized_asset_key
	if not is_iso_object_png_asset_key(normalized_asset_key):
		return false
	var texture_path: String = get_iso_object_png_asset_path(normalized_asset_key, path_descriptor)
	if not texture_path.is_empty():
		path_descriptor["texture_path"] = texture_path
		path_descriptor["path"] = texture_path
	if VisualAssetRenderContractServiceRef.is_pulsar_overlay(texture_path):
		return true
	var visual_center: Vector2 = grid_to_iso(cell)
	if visual_center_override != Vector2.INF:
		visual_center = visual_center_override
	local_object_data = enrich_iso_object_surface_context_for_cell(local_object_data, cell)
	if is_wall_procedural_routed_object(local_object_data):
		return draw_wall_procedural_routed_object(cell, local_object_data, visual_center)
	var texture: Texture2D = get_iso_object_png_texture_for_resolved_path(normalized_asset_key, texture_path)
	if texture == null:
		push_warning("[IsoObjectPNG] drawing missing fallback for visual_id=%s path=%s object_id=%s object_type=%s map_constructor_prefab_id=%s" % [normalized_asset_key, texture_path, str(local_object_data.get("id", local_object_data.get("object_id", ""))), str(local_object_data.get("object_type", local_object_data.get("type", ""))), str(local_object_data.get("map_constructor_prefab_id", ""))])
		var fallback_rect: Rect2 = get_iso_texture_draw_rect_for_asset_key_with_size(normalized_asset_key, visual_center, get_iso_asset_alignment_expected_size(normalized_asset_key))
		draw_missing_iso_asset_debug_fallback(cell, normalized_asset_key, fallback_rect)
		return true
	var render_contract: String = VisualAssetRenderContractServiceRef.get_render_contract(texture_path)
	var descriptor: Dictionary = build_iso_object_visual_descriptor_for_contract(local_object_data, normalized_asset_key, texture_path, render_contract, visual_center, texture).duplicate(true)
	if bool(visual_state_descriptor.get("mirror_x", false)):
		descriptor["mirror_h"] = true
		descriptor["mirror_x"] = true
	draw_iso_object_png_texture_with_descriptor(texture, descriptor)
	draw_visual_state_overlays_for_descriptor(local_object_data, descriptor)
	return true

func draw_optional_visual_texture_asset(asset_id: String, cell: Vector2i, _fallback_callable_name: String = "", options: Dictionary = {}) -> bool:
	var normalized_asset_id: String = asset_id.strip_edges()
	if normalized_asset_id.is_empty():
		return false
	var mission_manager: Node = get_mission_manager_ref()
	if mission_manager == null or not mission_manager.has_method("resolve_visual_texture_asset"):
		return false
	var resolved: Dictionary = Dictionary(mission_manager.call("resolve_visual_texture_asset", normalized_asset_id))
	if not bool(resolved.get("ok", false)):
		push_warning("[VisualAsset] unknown texture_asset_id: %s" % normalized_asset_id)
		return false
	if not bool(resolved.get("has_texture", false)):
		return false
	var texture_path: String = str(resolved.get("texture_path", "")).strip_edges()
	if texture_path.is_empty():
		return false
	if should_skip_placeholder_object_texture_path_in_gray_test(texture_path):
		return false
	var loaded: Resource = load(texture_path)
	if loaded == null or not (loaded is Texture2D):
		push_warning("[VisualAsset] failed to load texture_path for %s: %s" % [normalized_asset_id, texture_path])
		return false
	var texture: Texture2D = loaded as Texture2D
	var center: Vector2 = grid_to_iso(cell)
	if options.has("visual_center"):
		center = Vector2(options.get("visual_center", center))
	var alignment_asset_key: String = str(resolved.get("placeholder_asset_key", normalized_asset_id))
	var atlas_region: Rect2i = Rect2i(resolved.get("atlas_region", Rect2i(0, 0, 0, 0)))
	if atlas_region.size.x > 0 and atlas_region.size.y > 0:
		var atlas_size: Vector2 = Vector2(float(atlas_region.size.x), float(atlas_region.size.y))
		var destination_rect: Rect2 = get_iso_texture_draw_rect_for_asset_key_with_size(alignment_asset_key, center, atlas_size)
		draw_texture_rect_region(texture, destination_rect, Rect2(atlas_region.position, atlas_region.size))
		draw_iso_asset_alignment_overlay(alignment_asset_key, center, destination_rect)
		return true
	draw_iso_texture_with_alignment(texture, alignment_asset_key, center)
	return true

func can_draw_optional_visual_texture_asset(asset_id: String) -> bool:
	var normalized_asset_id: String = asset_id.strip_edges()
	if normalized_asset_id.is_empty():
		return false
	var mission_manager: Node = get_mission_manager_ref()
	if mission_manager == null or not mission_manager.has_method("resolve_visual_texture_asset"):
		return false
	var resolved: Dictionary = Dictionary(mission_manager.call("resolve_visual_texture_asset", normalized_asset_id))
	if not bool(resolved.get("ok", false)):
		return false
	if not bool(resolved.get("has_texture", false)):
		return false
	var texture_path: String = str(resolved.get("texture_path", "")).strip_edges()
	if texture_path.is_empty():
		return false
	if should_skip_placeholder_object_texture_path_in_gray_test(texture_path):
		return false
	var loaded: Resource = load(texture_path)
	return loaded != null and (loaded is Texture2D)

func has_drawable_iso_wall_texture(material_override: Dictionary, _material_row: Dictionary, wall_profile_key: String) -> bool:
	var wall_asset_key: String = get_production_wall_asset_key(material_override, Vector2i.ZERO, wall_profile_key)
	if use_gray_room_visual_test_assets:
		wall_asset_key = get_test_wall_height_asset_key(material_override, Vector2i.ZERO)
	return get_iso_wall_texture_for_profile(wall_asset_key) != null

func draw_iso_wall_texture_for_cell(cell: Vector2i, material_override: Dictionary, _material_row: Dictionary, wall_profile_key: String) -> bool:
	var wall_asset_key: String = get_production_wall_asset_key(material_override, cell, wall_profile_key, get_iso_wall_depth_bounds())
	if use_gray_room_visual_test_assets:
		wall_asset_key = get_test_wall_height_asset_key(material_override, cell, get_iso_wall_depth_bounds())
	return draw_iso_wall_asset_texture_for_cell(cell, wall_asset_key, get_wall_render_topology(cell))

func get_wall_prototype_colors(cell: Vector2i) -> Dictionary:
	var profile_key: String = get_wall_visual_profile_key_for_cell(cell)
	var profile: Dictionary = get_wall_visual_profile(profile_key)
	var parity: int = (cell.x + cell.y) % 2
	var top_color: Color = _get_color_from_dict(profile, "top", Color.WHITE)
	var left_color: Color = _get_color_from_dict(profile, "left", Color.WHITE)
	var right_color: Color = _get_color_from_dict(profile, "right", Color.WHITE)
	if parity != 0:
		top_color = top_color.lightened(0.06)
		left_color = left_color.lightened(0.05)
		right_color = right_color.lightened(0.045)

	var colors: Dictionary = {
		"top": top_color,
		"left": left_color,
		"right": right_color,
		"outline": _get_color_from_dict(profile, "outline", Color(0.24, 0.31, 0.36, 0.9)),
		"accent": _get_color_from_dict(profile, "accent", Color(0.29, 0.35, 0.4, 0.5))
	}
	var material_override: Dictionary = _get_wall_material_override_for_cell(cell)
	if bool(material_override.get("ok", false)):
		var material_row: Dictionary = Dictionary(material_override.get("material", {}))
		var tint_color: Color = Color(material_row.get("fallback_color", Color(1, 1, 1, 1)))
		var edge_color: Color = Color(material_row.get("edge_color", colors.get("outline", Color.WHITE)))
		colors["top"] = _blend_color(Color(colors.get("top", Color.WHITE)), tint_color, 0.45)
		colors["left"] = _blend_color(Color(colors.get("left", Color.WHITE)), tint_color.darkened(0.05), 0.5)
		colors["right"] = _blend_color(Color(colors.get("right", Color.WHITE)), tint_color.darkened(0.1), 0.5)
		colors["outline"] = _blend_color(Color(colors.get("outline", Color.WHITE)), edge_color, 0.72)
		colors["accent"] = _blend_color(Color(colors.get("accent", Color.WHITE)), edge_color.lightened(0.12), 0.68)
		colors["wall_material_style"] = str(material_row.get("style", "default"))
	return colors

func _blend_color(base_color: Color, tint_color: Color, amount: float) -> Color:
	var safe_amount: float = clampf(amount, 0.0, 1.0)
	return base_color.lerp(tint_color, safe_amount)

func _get_wall_material_override_for_cell(cell: Vector2i) -> Dictionary:
	var mission_manager: Node = get_mission_manager_ref()
	if mission_manager == null:
		return {"ok": false}
	if mission_manager.has_method("get_map_constructor_wall_material_for_wall_cell"):
		var wall_cell_result: Dictionary = Dictionary(mission_manager.call("get_map_constructor_wall_material_for_wall_cell", cell))
		if bool(wall_cell_result.get("ok", false)):
			return wall_cell_result
	if not mission_manager.has_method("get_map_constructor_wall_material"):
		return {"ok": false}
	var side_order: Array[String] = ["north", "east", "south", "west"]
	var chosen_override: Dictionary = {}
	for side_id in side_order:
		var override_result: Dictionary = Dictionary(mission_manager.call("get_map_constructor_wall_material", cell, side_id))
		if bool(override_result.get("ok", false)):
			chosen_override = Dictionary(override_result.get("override", {}))
			break
	if chosen_override.is_empty():
		return {"ok": false}
	var material_id: String = str(chosen_override.get("material_id", "")).to_lower()
	if material_id.is_empty() or not mission_manager.has_method("get_map_constructor_wall_material_catalog"):
		return {"ok": false}
	var catalog: Dictionary = Dictionary(mission_manager.call("get_map_constructor_wall_material_catalog"))
	for material_variant in Array(catalog.get("materials", [])):
		var material_row: Dictionary = Dictionary(material_variant)
		if str(material_row.get("id", "")).to_lower() == material_id:
			return {"ok": true, "override": chosen_override, "material": material_row}
	return {"ok": false}

func get_default_wall_visual_profile_key() -> String:
	return WallRendererRef.get_default_visual_profile_key()

func normalize_wall_visual_profile_key(profile_key: String) -> String:
	return WallRendererRef.normalize_visual_profile_key(profile_key)

func get_wall_visual_profiles() -> Dictionary:
	return WallRendererRef.get_visual_profiles()

func get_wall_visual_profile(profile_key: String) -> Dictionary:
	return WallRendererRef.get_visual_profile(profile_key)

func get_wall_visual_profile_key_for_cell(cell: Vector2i) -> String:
	return WallRendererRef.get_visual_profile_key_for_cell(_grid_manager, cell, get_wall_metadata_for_cell(cell))

func get_wall_metadata_for_cell(cell: Vector2i) -> Dictionary:
	var mission_manager: Node = get_mission_manager_ref()
	if mission_manager == null:
		return {}
	if not mission_manager.has_method("get_world_object_at_cell"):
		return {}
	var metadata_variant: Variant = mission_manager.call("get_world_object_at_cell", cell)
	if metadata_variant is Dictionary:
		return Dictionary(metadata_variant)
	return {}

func _get_iso_world_object_metadata_for_cell(cell: Vector2i) -> Dictionary:
	var fallback: Dictionary = {"ok": false, "object_id": "", "object_type": "", "data": {}}
	var mission_manager: Node = get_mission_manager_ref()
	if mission_manager == null:
		return fallback
	if not mission_manager.has_method("get_world_object_at_cell"):
		return fallback
	var metadata_variant: Variant = mission_manager.call("get_world_object_at_cell", cell, true)
	if not (metadata_variant is Dictionary):
		metadata_variant = mission_manager.call("get_world_object_at_cell", cell)
	if not (metadata_variant is Dictionary):
		return fallback
	var metadata: Dictionary = Dictionary(metadata_variant)
	var nested_data: Dictionary = Dictionary(metadata.get("data", {}))
	var object_id: String = str(metadata.get("object_id", metadata.get("id", ""))).strip_edges()
	if object_id.is_empty():
		object_id = str(nested_data.get("id", nested_data.get("object_id", ""))).strip_edges()
	var object_type: String = str(metadata.get("object_type", metadata.get("type", ""))).strip_edges()
	if object_type.is_empty():
		object_type = str(nested_data.get("object_type", nested_data.get("type", ""))).strip_edges()
	if object_id.is_empty():
		return fallback
	if nested_data.is_empty():
		nested_data = metadata
	return {"ok": true, "object_id": object_id, "object_type": object_type, "data": nested_data}

func get_wall_object_type_for_cell(cell: Vector2i) -> String:
	return WallRendererRef.get_object_type_for_metadata(get_wall_metadata_for_cell(cell))

func get_wall_profile_from_tags(tags_variant: Variant) -> String:
	return WallRendererRef.get_profile_from_tags(tags_variant)

func map_wall_metadata_value_to_profile(raw_value: String) -> String:
	return WallRendererRef.map_metadata_value_to_profile(raw_value)

func get_mission_manager_ref() -> Node:
	var current: Node = self
	while current != null:
		if current.has_node("MissionManager"):
			return current.get_node("MissionManager")
		current = current.get_parent()
	return null

func is_outer_border_cell(cell: Vector2i) -> bool:
	return WallRendererRef.is_outer_border_cell(_grid_manager, cell)

func get_iso_wall_top_points(cell: Vector2i) -> PackedVector2Array:
	var base_points: PackedVector2Array = get_iso_wall_base_points(cell)
	var top_points: PackedVector2Array = PackedVector2Array()
	var safe_wall_height: float = maxf(iso_wall_height, 1.0)
	for point in base_points:
		top_points.append(point + Vector2(0.0, -safe_wall_height))
	return top_points

func _is_wall_cell(cell: Vector2i) -> bool:
	return WallRendererRef.is_wall_cell(_grid_manager, cell)

func _is_wall_in_bounds(cell: Vector2i) -> bool:
	return WallRendererRef.is_in_bounds(_grid_manager, cell)

func _get_wall_neighbor_mask(cell: Vector2i) -> Dictionary:
	return WallRendererRef.get_neighbor_mask(_grid_manager, cell)

func _is_door_like_tile(tile_type: int) -> bool:
	return WallRendererRef.is_door_like_tile(tile_type)

func _is_wall_mount_neighbor_visible(tile_type: int) -> bool:
	return WallRendererRef.is_mount_neighbor_visible(tile_type)

func _get_wall_side_delta(side: String) -> Vector2i:
	return WallRendererRef.get_side_delta(side)

func get_visible_wall_sides(cell: Vector2i) -> Array[String]:
	return WallRendererRef.get_visible_sides(_grid_manager, cell)

func get_wall_mounted_anchor_zones(cell: Vector2i) -> Array[Dictionary]:
	return WallRendererRef.get_mounted_anchor_zones(_grid_manager, cell, iso_origin, get_iso_tile_half_size())

func is_wall_adjacent_to_door(cell: Vector2i) -> bool:
	if _grid_manager == null:
		return false
	for delta in [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]:
		var neighbor: Vector2i = cell + delta
		if not _is_wall_in_bounds(neighbor):
			continue
		if _is_door_like_tile(_grid_manager.get_tile(neighbor)):
			return true
	return false

func get_wall_render_topology(cell: Vector2i) -> Dictionary:
	return WallRendererRef.get_render_topology(_grid_manager, cell)

func classify_wall_topology(cell: Vector2i) -> String:
	if not _is_wall_in_bounds(cell) or not _is_wall_cell(cell):
		return "unknown"
	# Border walls must use the same topology-derived geometry as interior walls.
	# Treating every outer-border cell as a special boundary shape made edge
	# segments render with a different profile than matching center-map walls.
	if is_wall_adjacent_to_door(cell):
		return "door_adjacent"
	var topology: Dictionary = get_wall_render_topology(cell)
	return str(topology.get("shape", "isolated"))

func get_iso_architectural_wall_profile(topology: String, visual_material: Dictionary) -> Dictionary:
	var fallback_colors: Dictionary = get_wall_prototype_colors(Vector2i.ZERO)
	var material_id: String = str(visual_material.get("id", visual_material.get("material_id", "default_wall"))).strip_edges()
	var base_color: Color = Color(visual_material.get("fallback_color", fallback_colors.get("top", Color(0.2, 0.2, 0.24, 1.0))))
	var edge_color: Color = Color(visual_material.get("edge_color", fallback_colors.get("outline", Color(0.3, 0.3, 0.35, 1.0))))
	var safe_topology: String = topology if not topology.is_empty() else "isolated"
	var corner: bool = safe_topology.contains("corner_")
	return {
		"base_color": base_color.darkened(0.2),
		"side_color": base_color.darkened(0.33),
		"top_color": base_color.lightened(0.08),
		"edge_color": edge_color,
		"shadow_color": Color(0.03, 0.04, 0.05, 0.36),
		"height_px": maxi(int(iso_wall_height), 18),
		"cap_enabled": true,
		"corner_emphasis": 1.25 if corner else 1.0,
		"damage_overlay_strength": 0.45 if material_id.find("damaged") >= 0 else 0.0,
		"wall_mass_ratio": WALL_MASS_RATIO,
		"mount_band_ratio": WALL_MOUNT_BAND_RATIO,
		"mount_band_color": base_color.lightened(0.12),
		"mount_band_edge_color": edge_color.lightened(0.12),
		"mount_band_enabled": true,
		"material_id": material_id,
		"topology": safe_topology
	}

func draw_iso_wall_block(cell: Vector2i) -> void:
	if should_skip_full_wall_for_door_opening(cell):
		return
	var render_topology: Dictionary = get_wall_render_topology(cell)
	var base_points: PackedVector2Array = get_iso_wall_connected_base_points(cell, render_topology)
	if base_points.size() < 4:
		return
	var top_points: PackedVector2Array = get_iso_wall_top_points(cell)
	if top_points.size() < 4:
		return

	var colors: Dictionary = get_wall_prototype_colors(cell)
	var topology: String = classify_wall_topology(cell)
	var material_override: Dictionary = _get_wall_material_override_for_cell(cell)
	var material_row: Dictionary = Dictionary(material_override.get("material", {}))
	var arch: Dictionary = get_iso_architectural_wall_profile(topology, material_row)
	var wall_profile_key: String = get_wall_visual_profile_key_for_cell(cell)
	var top_face: PackedVector2Array = PackedVector2Array([top_points[0], top_points[1], top_points[2], top_points[3]])
	var left_face: PackedVector2Array = PackedVector2Array([top_points[3], top_points[2], base_points[2], base_points[3]])
	var right_face: PackedVector2Array = PackedVector2Array([top_points[2], top_points[1], base_points[1], base_points[2]])
	var floor_shadow: PackedVector2Array = PackedVector2Array([base_points[2], base_points[3], base_points[3] + Vector2(0.0, 8.0), base_points[2] + Vector2(0.0, 8.0)])
	var accent_color: Color = _get_color_from_dict(colors, "accent", Color.WHITE)

	var wall_asset_key: String = get_production_wall_asset_key(material_override, cell, wall_profile_key, get_iso_wall_depth_bounds())
	if use_gray_room_visual_test_assets:
		wall_asset_key = get_test_wall_height_asset_key(material_override, cell, get_iso_wall_depth_bounds())
	if draw_iso_wall_asset_texture_for_cell(cell, wall_asset_key, render_topology):
		draw_breachable_wall_overlay_for_cell(cell, material_override, wall_asset_key, render_topology)
		draw_iso_wall_debug_and_mount_overlays(cell, arch, topology)
		return

	var alpha_mult: float = 1.0
	if iso_wall_cutaway_enabled and is_wall_adjacent_to_door(cell):
		alpha_mult = 0.65

	var left_color: Color = Color(arch.get("base_color", _get_color_from_dict(colors, "left", Color.WHITE)))
	var right_color: Color = Color(arch.get("side_color", _get_color_from_dict(colors, "right", Color.WHITE)))
	var top_color: Color = Color(arch.get("top_color", _get_color_from_dict(colors, "top", Color.WHITE)))
	var outline_color: Color = Color(arch.get("edge_color", _get_color_from_dict(colors, "outline", Color.WHITE)))
	left_color.a *= alpha_mult
	right_color.a *= alpha_mult
	top_color.a *= alpha_mult

	draw_colored_polygon(left_face, left_color)
	draw_colored_polygon(right_face, right_color)
	if bool(arch.get("cap_enabled", true)) or topology.find("corner_") >= 0 or topology.begins_with("straight_") or topology == "t_junction" or topology == "cross":
		draw_colored_polygon(top_face, top_color)
	draw_colored_polygon(floor_shadow, Color(arch.get("shadow_color", Color(0.0, 0.0, 0.0, 0.25))))

	if debug_draw_iso_wall_outlines:
		for top_edge_idx in range(top_face.size()):
			var top_next_idx: int = (top_edge_idx + 1) % top_face.size()
			draw_line(top_face[top_edge_idx], top_face[top_next_idx], outline_color, 1.0)

		for left_edge_idx in range(left_face.size()):
			var left_next_idx: int = (left_edge_idx + 1) % left_face.size()
			draw_line(left_face[left_edge_idx], left_face[left_next_idx], outline_color, 1.0)

		for right_edge_idx in range(right_face.size()):
			var right_next_idx: int = (right_edge_idx + 1) % right_face.size()
			draw_line(right_face[right_edge_idx], right_face[right_next_idx], outline_color, 1.0)

	var accent_start: Vector2 = top_points[3].lerp(top_points[0], 0.4)
	var accent_end: Vector2 = top_points[0].lerp(top_points[1], 0.45)
	draw_line(accent_start, accent_end, accent_color, 1.2)
	draw_iso_wall_surface_accent(left_face, right_face, top_face, wall_profile_key, accent_color)
	draw_iso_breachable_wall_overlay(cell)
	draw_iso_wall_debug_and_mount_overlays(cell, arch, topology)
func _get_mission_runtime_manager() -> Variant:
	var parent_node: Node = get_parent()
	if parent_node != null and parent_node.has_method("get_world_object_at_cell"):
		return parent_node

	var scene_root: Node = get_tree().current_scene
	if scene_root != null and scene_root.has_method("get_mission_manager_runtime"):
		return scene_root.call("get_mission_manager_runtime")

	if scene_root != null and scene_root.has_node("MissionManager"):
		return scene_root.get_node("MissionManager")

	return null
	
func _get_breachable_wall_data_for_cell(cell: Vector2i) -> Dictionary:
	var runtime_manager: Variant = _get_mission_runtime_manager()
	if runtime_manager == null or not runtime_manager.has_method("get_world_object_at_cell"):
		return {}
	var object_data: Dictionary = Dictionary(runtime_manager.call("get_world_object_at_cell", cell))
	if object_data.is_empty() and runtime_manager.has_method("get_breachable_wall_action_target_at_cell"):
		object_data = Dictionary(runtime_manager.call("get_breachable_wall_action_target_at_cell", cell))
	if object_data.has("data") and object_data.get("data") is Dictionary:
		var nested_data: Dictionary = Dictionary(object_data.get("data", {}))
		if not nested_data.is_empty():
			object_data = nested_data

	if not BreachableWallServiceRef.is_active_breachable_wall_data(object_data):
		return {}
	return object_data

func draw_iso_breachable_wall_overlay(cell: Vector2i) -> void:
	var object_data: Dictionary = _get_breachable_wall_data_for_cell(cell)
	if object_data.is_empty():
		return
	var descriptor: Dictionary = BreachableWallServiceRef.get_crack_visual_descriptor(cell, object_data, iso_wall_height, get_iso_tile_half_size())
	if not bool(descriptor.get("visible", false)):
		return
	var crack_center: Vector2 = grid_to_iso(cell) + Vector2(descriptor.get("center_offset", Vector2.ZERO))
	var crack_scale: float = float(descriptor.get("scale", 1.0))
	var crack_color: Color = Color(0.06, 0.045, 0.035, 0.92)
	var glow_color: Color = Color(1.0, 0.72, 0.24, 0.34)
	draw_circle(crack_center, 8.0 * crack_scale, glow_color)
	draw_line(crack_center + Vector2(-2.0, -12.0) * crack_scale, crack_center + Vector2(1.0, -3.0) * crack_scale, crack_color, 2.0 * crack_scale)
	draw_line(crack_center + Vector2(1.0, -3.0) * crack_scale, crack_center + Vector2(-5.0, 5.0) * crack_scale, crack_color, 2.0 * crack_scale)
	draw_line(crack_center + Vector2(1.0, -3.0) * crack_scale, crack_center + Vector2(7.0, 7.0) * crack_scale, crack_color, 2.0 * crack_scale)
	draw_line(crack_center + Vector2(-5.0, 5.0) * crack_scale, crack_center + Vector2(-1.0, 13.0) * crack_scale, crack_color, 1.4 * crack_scale)
	draw_line(crack_center + Vector2(7.0, 7.0) * crack_scale, crack_center + Vector2(3.0, 14.0) * crack_scale, crack_color, 1.4 * crack_scale)


func draw_iso_wall_debug_and_mount_overlays(cell: Vector2i, arch: Dictionary, topology: String) -> void:
	var context: Dictionary = {
		"show_topology": show_wall_topology_overlay,
		"topology": topology,
		"topology_position": grid_to_iso(cell) + Vector2(-20.0, -float(arch.get("height_px", 24)) - 4.0),
		"mount_zones": [],
	}
	if show_wall_mount_zones_overlay and bool(arch.get("mount_band_enabled", true)):
		var mount_zones: Array[Dictionary] = []
		for zone_variant in get_wall_mounted_anchor_zones(cell):
			var zone: Dictionary = Dictionary(zone_variant)
			if not bool(zone.get("mountable", false)):
				continue
			var mount_poly: PackedVector2Array = PackedVector2Array(zone.get("mount_zone_polygon", PackedVector2Array()))
			if mount_poly.size() < 3:
				continue
			var mount_zone_context: Dictionary = {
				"points": mount_poly,
				"draw_outline": debug_draw_iso_wall_outlines,
			}
			if arch.has("mount_band_color"):
				mount_zone_context["fill_color"] = arch.get("mount_band_color")
			if arch.has("mount_band_edge_color"):
				mount_zone_context["edge_color"] = arch.get("mount_band_edge_color")
			mount_zones.append(mount_zone_context)
		context["mount_zones"] = mount_zones
	_draw_overlay_commands(RuntimeDebugOverlayRendererRef.build_wall_debug_commands(context))

func draw_iso_wall_surface_accent(
	left_face: PackedVector2Array,
	right_face: PackedVector2Array,
	top_face: PackedVector2Array,
	profile_key: String,
	accent_color: Color
) -> void:
	var accent_key: String = normalize_wall_visual_profile_key(profile_key)
	match accent_key:
		"brick_wall":
			draw_iso_wall_brick_accent(left_face, right_face, accent_color)
		"concrete_wall":
			draw_iso_wall_concrete_accent(left_face, right_face, top_face, accent_color)
		"steel_wall", "reinforced_steel_wall", "titanium_wall":
			draw_iso_wall_steel_accent(left_face, right_face, top_face, accent_color)
		"grate_wall":
			draw_iso_wall_grate_accent(left_face, right_face, accent_color)

func draw_iso_wall_brick_accent(left_face: PackedVector2Array, right_face: PackedVector2Array, accent_color: Color) -> void:
	var mortar_color: Color = accent_color.lightened(0.05)
	for row in [0.22, 0.45, 0.68, 0.88]:
		draw_line(left_face[0].lerp(left_face[3], row), left_face[1].lerp(left_face[2], row), mortar_color, 1.3)
		draw_line(right_face[0].lerp(right_face[3], row), right_face[1].lerp(right_face[2], row), mortar_color, 1.3)

func draw_iso_wall_concrete_accent(
	left_face: PackedVector2Array,
	right_face: PackedVector2Array,
	_top_face: PackedVector2Array,
	accent_color: Color
) -> void:
	var crack_color: Color = accent_color.darkened(0.28)
	draw_line(left_face[0].lerp(left_face[1], 0.26), left_face[2].lerp(left_face[3], 0.7), crack_color, 1.15)
	draw_line(right_face[0].lerp(right_face[1], 0.64), right_face[2].lerp(right_face[3], 0.22), crack_color, 1.15)
	var panel_color: Color = accent_color.lightened(0.04)
	draw_line(left_face[0].lerp(left_face[3], 0.52), left_face[1].lerp(left_face[2], 0.52), panel_color, 1.0)
	draw_line(right_face[0].lerp(right_face[3], 0.48), right_face[1].lerp(right_face[2], 0.48), panel_color, 1.0)

func draw_iso_wall_steel_accent(
	left_face: PackedVector2Array,
	right_face: PackedVector2Array,
	top_face: PackedVector2Array,
	accent_color: Color
) -> void:
	var seam_color: Color = accent_color.lightened(0.1)
	draw_line(left_face[0].lerp(left_face[1], 0.5), left_face[3].lerp(left_face[2], 0.5), seam_color, 1.25)
	draw_line(right_face[0].lerp(right_face[1], 0.5), right_face[3].lerp(right_face[2], 0.5), seam_color, 1.25)
	draw_line(top_face[3].lerp(top_face[0], 0.5), top_face[2].lerp(top_face[1], 0.5), seam_color, 1.1)
	var rivet_color: Color = accent_color.lightened(0.3)
	for side_point in [left_face[1], left_face[2], right_face[1], right_face[2]]:
		draw_circle(side_point.lerp(top_face[2], 0.08), 1.2, rivet_color)

func draw_iso_wall_grate_accent(left_face: PackedVector2Array, right_face: PackedVector2Array, accent_color: Color) -> void:
	var bar_color: Color = accent_color.lightened(0.2)
	var gap_color: Color = Color(0.02, 0.03, 0.04, 0.95)
	for band in [0.3, 0.7]:
		var left_gap: PackedVector2Array = PackedVector2Array([
			left_face[0].lerp(left_face[1], band - 0.08),
			left_face[0].lerp(left_face[1], band + 0.08),
			left_face[3].lerp(left_face[2], band + 0.08),
			left_face[3].lerp(left_face[2], band - 0.08)
		])
		var right_gap: PackedVector2Array = PackedVector2Array([
			right_face[0].lerp(right_face[1], band - 0.08),
			right_face[0].lerp(right_face[1], band + 0.08),
			right_face[3].lerp(right_face[2], band + 0.08),
			right_face[3].lerp(right_face[2], band - 0.08)
		])
		draw_colored_polygon(left_gap, gap_color)
		draw_colored_polygon(right_gap, gap_color)
	for column in [0.16, 0.5, 0.84]:
		draw_line(left_face[0].lerp(left_face[1], column), left_face[3].lerp(left_face[2], column), bar_color, 1.7)
		draw_line(right_face[0].lerp(right_face[1], column), right_face[3].lerp(right_face[2], column), bar_color, 1.7)

func _safe_variant_dictionary(value: Variant, should_duplicate: bool = false) -> Dictionary:
	if value is Dictionary:
		var dictionary: Dictionary = Dictionary(value)
		return dictionary.duplicate(true) if should_duplicate else dictionary
	return {}

func get_floor_atlas_cell_size() -> Vector2:
	return FloorRendererRef.get_atlas_cell_size(iso_floor_atlas_texture)

func get_floor_atlas_region(row: int, atlas_position: int) -> Rect2:
	return FloorRendererRef.get_atlas_region(iso_floor_atlas_texture, row, atlas_position)

func get_floor_state_for_cell(cell: Vector2i) -> Dictionary:
	return FloorRendererRef.get_floor_state_for_cell(_grid_manager, cell)

func get_floor_base_atlas_key(family: String) -> String:
	return FloorRendererRef.get_base_atlas_key(family)

func get_floor_overlay_atlas_key(family: String, wear: String) -> String:
	return FloorRendererRef.get_overlay_atlas_key(family, wear)

func get_floor_atlas_variant_for_cell(cell: Vector2i, requested_variant: int, max_variants: int, salt: int = 0) -> int:
	return FloorRendererRef.get_atlas_variant_for_cell(cell, requested_variant, max_variants, salt)

func get_floor_atlas_seam_safe_variant(cell: Vector2i, atlas_key: String, requested_variant: int, max_variants: int, salt: int = 0) -> int:
	return FloorRendererRef.get_atlas_seam_safe_variant(cell, atlas_key, requested_variant, max_variants, salt)

func get_floor_atlas_safe_source_rect(source_rect: Rect2) -> Rect2:
	return FloorRendererRef.get_atlas_safe_source_rect(source_rect)

func get_floor_atlas_destination_rect() -> Rect2:
	return FloorRendererRef.get_atlas_destination_rect(get_iso_tile_half_size())

func get_iso_diamond_points_with_overlap(cell: Vector2i, overlap: float) -> PackedVector2Array:
	if overlap <= 0.0:
		return get_iso_diamond_points(cell)
	var center_point: Vector2 = grid_to_iso(cell)
	var points: PackedVector2Array = PackedVector2Array()
	for point in get_iso_diamond_points(cell):
		var away_from_center: Vector2 = point - center_point
		if away_from_center.length() <= 0.0001:
			points.append(point)
		else:
			points.append(point + away_from_center.normalized() * overlap)
	return points

func draw_floor_seamless_underlay(cell: Vector2i, fill_color: Color) -> void:
	# Draw a tiny overlapping solid diamond below the atlas art.  This masks
	# transparent atlas margins and sub-pixel rasterization holes while preserving
	# the atlas details drawn above it.
	var underlay_points: PackedVector2Array = get_iso_diamond_points_with_overlap(cell, ISO_FLOOR_UNDERLAY_OVERLAP)
	draw_colored_polygon(underlay_points, fill_color)

func draw_procedural_floor_tile(cell: Vector2i, fill_color: Color, profile: Dictionary, draw_edge_borders: bool) -> void:
	# Standard floor path: one full-size procedural diamond per logical cell.
	# This deliberately avoids PNG/atlas padding, crop boxes, texture anchors, and
	# per-material footprints so adjacent cells cover the whole isometric grid.
	var diamond_points: PackedVector2Array = get_iso_diamond_points(cell)
	if diamond_points.size() < 4:
		return
	var base_color: Color = Color(fill_color.r, fill_color.g, fill_color.b, maxf(fill_color.a, 0.98))
	draw_colored_polygon(diamond_points, base_color)
	var panel_color: Color = _get_color_from_dict(profile, "panel", Color(0.18, 0.2, 0.24, 0.26))
	var seam_color: Color = _get_color_from_dict(profile, "seam", Color(0.36, 0.42, 0.48, 0.24))
	var panel_points: PackedVector2Array = get_iso_inset_diamond_points(cell, iso_floor_visual_inset + 8.0)
	if panel_points.size() >= 4:
		for panel_edge_index in range(panel_points.size()):
			var panel_next_index: int = (panel_edge_index + 1) % panel_points.size()
			draw_line(panel_points[panel_edge_index], panel_points[panel_next_index], panel_color, 0.45)
	var center_point: Vector2 = grid_to_iso(cell)
	draw_line(diamond_points[3].lerp(center_point, 0.2), diamond_points[1].lerp(center_point, 0.2), seam_color, 0.55)
	if draw_edge_borders or debug_draw_iso_cell_outlines:
		var outline_color: Color = _get_color_from_dict(profile, "outline", Color(0.21, 0.33, 0.39, 0.72))
		for side in WALL_SIDE_ORDER:
			var edge_points: Array[Vector2] = get_iso_diamond_edge_points(diamond_points, side)
			if edge_points.size() < 2:
				continue
			if debug_draw_iso_cell_outlines or should_draw_floor_edge_border(cell, side):
				draw_line(edge_points[0], edge_points[1], outline_color, 0.65)
	if debug_floor_tile_bounds:
		draw_floor_tile_bounds_debug(cell)

func draw_procedural_floor_debug_tile(cell: Vector2i, fill_color: Color) -> void:
	# Diagnostic floor renderer: uses only vector geometry with the same
	# grid_to_iso projection as floor placement. If this stitches cleanly while
	# an atlas does not, the issue is source art/sampling rather than placement.
	var profile: Dictionary = {
		"outline": Color(0.0, 1.0, 1.0, 0.95),
		"panel": Color(1.0, 1.0, 0.0, 0.38),
		"seam": Color(1.0, 0.0, 1.0, 0.55)
	}
	draw_procedural_floor_tile(cell, fill_color.lightened(0.1), profile, true)
	if not debug_floor_tile_bounds:
		draw_floor_tile_bounds_debug(cell)

func draw_floor_tile_bounds_debug(cell: Vector2i) -> void:
	var diamond_points: PackedVector2Array = get_iso_diamond_points(cell)
	if diamond_points.size() < 4:
		return
	var center_point: Vector2 = grid_to_iso(cell)
	var half_size: Vector2 = get_iso_tile_half_size()
	var destination_rect: Rect2 = Rect2(center_point - half_size, half_size * 2.0)
	var corner_color: Color = Color(1.0, 0.2, 0.2, 0.95)
	var axis_color: Color = Color(1.0, 0.92, 0.18, 0.82)
	var rect_color: Color = Color(0.2, 1.0, 0.45, 0.5)
	for edge_index in range(diamond_points.size()):
		var next_index: int = (edge_index + 1) % diamond_points.size()
		draw_line(diamond_points[edge_index], diamond_points[next_index], Color(0.0, 0.95, 1.0, 0.95), 1.5)
		draw_circle(diamond_points[edge_index], 2.4, corner_color)
	draw_rect(destination_rect, rect_color, false, 1.0)
	draw_line(center_point + Vector2(-half_size.x, 0.0), center_point + Vector2(half_size.x, 0.0), axis_color, 0.7)
	draw_line(center_point + Vector2(0.0, -half_size.y), center_point + Vector2(0.0, half_size.y), axis_color, 0.7)
	draw_circle(center_point, 2.6, Color(1.0, 1.0, 1.0, 0.95))
	draw_string(ThemeDB.fallback_font, center_point + Vector2(4.0, -4.0), "%d,%d" % [cell.x, cell.y], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, Color(1.0, 1.0, 1.0, 0.9))

func get_floor_atlas_inner_overlay_points() -> PackedVector2Array:
	return FloorRendererRef.get_atlas_inner_overlay_points(get_iso_tile_half_size())

func get_floor_atlas_uvs_for_destination_points(points: PackedVector2Array, destination_rect: Rect2, source_rect: Rect2) -> PackedVector2Array:
	return FloorRendererRef.get_atlas_uvs_for_destination_points(points, destination_rect, source_rect)

func draw_floor_atlas_overlay_layer(cell: Vector2i, source_rect: Rect2) -> void:
	# Wear/damage rows are detail overlays only.  Clip them to an inset diamond so
	# scratches and damage cannot rewrite the shared perimeter or create edge seams.
	var center: Vector2 = grid_to_iso(cell)
	var safe_source_rect: Rect2 = get_floor_atlas_safe_source_rect(source_rect)
	var destination_rect: Rect2 = get_floor_atlas_destination_rect()
	var overlay_points: PackedVector2Array = get_floor_atlas_inner_overlay_points()
	var overlay_uvs: PackedVector2Array = get_floor_atlas_uvs_for_destination_points(overlay_points, destination_rect, safe_source_rect)
	if overlay_points.size() < 4 or overlay_uvs.size() != overlay_points.size():
		return
	draw_set_transform(center.round(), 0.0, Vector2.ONE)
	draw_polygon(overlay_points, PackedColorArray([Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE]), overlay_uvs, iso_floor_atlas_texture)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func draw_floor_atlas_layer(cell: Vector2i, atlas_key: String, requested_variant: int, mirror_h: bool, mirror_v: bool) -> bool:
	if iso_floor_atlas_texture == null:
		return false
	if not ISO_FLOOR_ATLAS_LAYOUT.has(atlas_key):
		return false
	var layout: Dictionary = _safe_variant_dictionary(ISO_FLOOR_ATLAS_LAYOUT.get(atlas_key, {}))
	if layout.is_empty():
		return false
	var row: int = int(layout.get("row", 1))
	var variant_count: int = int(layout.get("variants", ISO_FLOOR_ATLAS_BASE_VARIANTS))
	var is_overlay: bool = bool(layout.get("overlay", false))
	var variant: int = get_floor_atlas_seam_safe_variant(cell, atlas_key, requested_variant, variant_count, row * 13)
	var source_rect: Rect2 = get_floor_atlas_region(row, variant)
	if source_rect.size.x <= 0.0 or source_rect.size.y <= 0.0:
		return false
	if is_overlay:
		draw_floor_atlas_overlay_layer(cell, source_rect)
		return true
	var center: Vector2 = grid_to_iso(cell)
	# Sample slightly inside each high-resolution atlas frame to avoid bleeding
	# bright pixels from neighboring frames, then overdraw by a pixel on screen to
	# cover fractional-pixel cracks between adjacent projected cells.
	var safe_source_rect: Rect2 = get_floor_atlas_safe_source_rect(source_rect)
	var destination_rect: Rect2 = get_floor_atlas_destination_rect()
	var safe_mirror_h: bool = false if ISO_FLOOR_SEAM_SAFE_BASE_VARIANTS.has(atlas_key) else mirror_h
	var safe_mirror_v: bool = false if ISO_FLOOR_SEAM_SAFE_BASE_VARIANTS.has(atlas_key) else mirror_v
	var visual_scale: Vector2 = Vector2(-1.0 if safe_mirror_h else 1.0, -1.0 if safe_mirror_v else 1.0)
	draw_set_transform(center.round(), 0.0, visual_scale)
	draw_texture_rect_region(iso_floor_atlas_texture, destination_rect, safe_source_rect, Color.WHITE, false, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	return true

func draw_iso_floor_atlas_for_cell(cell: Vector2i) -> bool:
	if iso_floor_atlas_texture == null:
		return false
	var state: Dictionary = get_floor_state_for_cell(cell)
	var family: String = str(state.get("family", "metal"))
	var wear: String = str(state.get("wear", "none"))
	var mirror_h: bool = bool(state.get("mirror_h", false))
	var mirror_v: bool = bool(state.get("mirror_v", false))
	var base_key: String = get_floor_base_atlas_key(family)
	var base_drawn: bool = draw_floor_atlas_layer(cell, base_key, int(state.get("base_variant", -1)), mirror_h, mirror_v)
	var overlay_key: String = get_floor_overlay_atlas_key(family, wear)
	if not overlay_key.is_empty():
		draw_floor_atlas_layer(cell, overlay_key, int(state.get("overlay_variant", -1)), mirror_h, mirror_v)
	return base_drawn

func draw_iso_floor_cell(cell: Vector2i, tile_type: int) -> void:
	if not is_floor_like_tile(tile_type):
		return

	var floor_asset_key: String = get_iso_floor_asset_key_for_tile(tile_type)
	var draw_cell_border: bool = should_draw_floor_cell_border(cell)
	var floor_inset: float = 0.0
	if draw_cell_border:
		floor_inset = maxf(iso_floor_visual_inset * 0.35, 0.0)
	var diamond_points: PackedVector2Array = get_iso_inset_diamond_points(cell, floor_inset)
	var profile_key: String = get_iso_floor_visual_profile_key_for_cell(cell)
	var profile: Dictionary = get_iso_floor_visual_profile(profile_key)
	var fill_color: Color = _get_color_from_dict(profile, "fill", get_floor_prototype_color(tile_type, cell))
	var mission_manager: Node = get_mission_manager_ref()
	var floor_texture_asset_id: String = ""
	var floor_material_key: String = "concrete"
	var floor_height_level: String = ""
	if mission_manager != null and mission_manager.has_method("get_map_constructor_floor_material_for_cell"):
		var floor_material_result: Dictionary = _safe_variant_dictionary(mission_manager.call("get_map_constructor_floor_material_for_cell", cell))
		if bool(floor_material_result.get("ok", false)):
			var floor_material: Dictionary = _safe_variant_dictionary(floor_material_result.get("material", {}))
			fill_color = Color(floor_material.get("fallback_color", fill_color))
			floor_texture_asset_id = str(floor_material.get("texture_asset_id", "")).strip_edges()
			floor_material_key = normalize_floor_material_key(str(floor_material.get("material", floor_material.get("id", "concrete"))))
			var floor_override: Dictionary = _safe_variant_dictionary(floor_material_result.get("override", {}))
			floor_height_level = normalize_floor_height_level(str(floor_override.get("floor_height", floor_override.get("floor_visual_height", floor_override.get("ground_height", "")))))
	if floor_height_level.is_empty() and _grid_manager != null and _grid_manager.has_method("get_floor_height_for_cell"):
		floor_height_level = normalize_floor_height_level(str(_grid_manager.call("get_floor_height_for_cell", cell)))
	if floor_texture_asset_id.begins_with("floor_"):
		floor_asset_key = floor_texture_asset_id
	else:
		floor_asset_key = get_iso_floor_asset_key_for_material_key(floor_material_key)
	var ground_asset_key: String = get_iso_ground_asset_key_for_floor_height(floor_height_level)
	var surface_y_offset: float = get_ground_surface_y_offset_for_asset_key(ground_asset_key)
	if not ground_asset_key.is_empty():
		draw_iso_ground_asset_texture_for_cell(cell, ground_asset_key)
	if use_procedural_floor_debug_tiles:
		draw_procedural_floor_debug_tile(cell, fill_color)
		return
	if draw_iso_floor_asset_texture_for_cell(cell, floor_asset_key, surface_y_offset):
		if debug_floor_tile_bounds:
			draw_floor_tile_bounds_debug(cell)
		return
	# Fallback to the procedural renderer so missing assets never leave holes.
	# The old floor atlas and legacy texture hooks remain opt-in fallbacks.
	if use_iso_floor_atlas_textures:
		draw_floor_seamless_underlay(cell, fill_color)
		if draw_iso_floor_atlas_for_cell(cell):
			if debug_floor_tile_bounds:
				draw_floor_tile_bounds_debug(cell)
			return
	if allow_legacy_floor_texture_assets:
		if not floor_texture_asset_id.is_empty() and draw_cell_border:
			var floor_asset_drawn: bool = draw_optional_visual_texture_asset(floor_texture_asset_id, cell, "", {"visual_center": grid_to_iso(cell)})
			if floor_asset_drawn:
				if debug_floor_tile_bounds:
					draw_floor_tile_bounds_debug(cell)
				return
		if draw_cell_border and draw_iso_texture_asset(cell, floor_asset_key):
			if debug_floor_tile_bounds:
				draw_floor_tile_bounds_debug(cell)
			return
	draw_procedural_floor_tile(cell, fill_color, profile, draw_cell_border)
	if diamond_points.size() >= 4:
		var seam_color: Color = _get_color_from_dict(profile, "seam", Color(0.36, 0.42, 0.48, 0.26))
		if profile_key == "floor_passage":
			draw_line(diamond_points[0].lerp(diamond_points[2], 0.32), diamond_points[0].lerp(diamond_points[2], 0.68), seam_color.lightened(0.03), 0.8)
		elif profile_key == "floor_doorway":
			draw_line(diamond_points[0].lerp(diamond_points[2], 0.42), diamond_points[0].lerp(diamond_points[2], 0.58), seam_color, 1.4)

func draw_iso_floor_prototype() -> void:
	# Compatibility wrapper: floors now also participate in the unified visual
	# queue, but debug callers can still invoke this pass directly.
	if _grid_manager == null:
		return

	var map_width: int = _grid_manager.get_map_width()
	var map_height: int = _grid_manager.get_map_height()
	if map_width <= 0 or map_height <= 0:
		return

	var floor_entries: Array[Dictionary] = build_iso_floor_draw_entries()
	floor_entries.sort_custom(sort_iso_draw_entries)
	for entry in floor_entries:
		draw_iso_draw_entry(entry)

func draw_iso_wall_prototype() -> void:
	if _grid_manager == null:
		return

	var map_width: int = _grid_manager.get_map_width()
	var map_height: int = _grid_manager.get_map_height()
	if map_width <= 0 or map_height <= 0:
		return

	var wall_cells: Array[Vector2i] = []
	for y in range(map_height):
		for x in range(map_width):
			var cell: Vector2i = Vector2i(x, y)
			var tile_type: int = _grid_manager.get_tile(cell)
			if is_wall_tile(tile_type):
				wall_cells.append(cell)

	wall_cells.sort_custom(sort_cells_by_iso_depth)
	for cell in wall_cells:
		draw_iso_wall_block(cell)

func get_iso_object_visual_profiles() -> Dictionary:
	# Visual-only object profile mapping for BIP-Visual-007.
	# Final asset rendering and gameplay metadata wiring will be added later.
	return {
		"door": {"base": Color(0.33, 0.22, 0.12, 0.96), "accent": Color(0.98, 0.74, 0.26, 0.98), "outline": Color(0.2, 0.13, 0.07, 0.94), "label": "Door", "shape": "door_panel"},
		"digital_door": {"base": Color(0.15, 0.25, 0.33, 0.95), "accent": Color(0.36, 0.73, 0.88, 0.95), "outline": Color(0.08, 0.15, 0.2, 0.92), "label": "Digital Door", "shape": "slab"},
		"powered_gate": {"base": Color(0.17, 0.22, 0.3, 0.95), "accent": Color(0.43, 0.81, 0.94, 0.95), "outline": Color(0.1, 0.15, 0.2, 0.92), "label": "Powered Gate", "shape": "slab"},
		"terminal": {"base": Color(0.14, 0.24, 0.29, 0.96), "accent": Color(0.34, 0.95, 1.0, 0.98), "outline": Color(0.07, 0.14, 0.18, 0.94), "label": "Terminal", "shape": "terminal_console"},
		"airflow_terminal": {"base": Color(0.14, 0.22, 0.28, 0.96), "accent": Color(0.5, 0.88, 0.98, 0.98), "outline": Color(0.07, 0.13, 0.17, 0.94), "label": "Airflow Terminal", "shape": "terminal_console"},
		"door_terminal": {"base": Color(0.15, 0.23, 0.28, 0.97), "accent": Color(0.4, 0.94, 1.0, 0.99), "outline": Color(0.08, 0.14, 0.18, 0.94), "label": "Door Terminal", "shape": "wall_terminal_panel"},
		"platform_terminal": {"base": Color(0.16, 0.27, 0.24, 0.97), "accent": Color(0.48, 0.98, 0.78, 0.99), "outline": Color(0.08, 0.16, 0.14, 0.94), "label": "Platform Terminal", "shape": "wall_terminal_panel"},
		"cooling_terminal": {"base": Color(0.14, 0.21, 0.29, 0.97), "accent": Color(0.58, 0.85, 1.0, 0.99), "outline": Color(0.08, 0.13, 0.18, 0.94), "label": "Cooling Terminal", "shape": "wall_terminal_panel"},
		"firewall": {"base": Color(0.32, 0.16, 0.14, 0.97), "accent": Color(1.0, 0.54, 0.2, 0.99), "outline": Color(0.22, 0.1, 0.08, 0.94), "label": "Firewall", "shape": "wall_firewall_panel"},
		"circuit_breaker": {"base": Color(0.22, 0.23, 0.24, 0.97), "accent": Color(0.95, 0.88, 0.52, 0.99), "outline": Color(0.13, 0.14, 0.15, 0.94), "label": "Circuit Breaker", "shape": "wall_breaker_box"},
		"fuse_box": {"base": Color(0.2, 0.21, 0.24, 0.97), "accent": Color(0.72, 0.82, 0.92, 0.99), "outline": Color(0.12, 0.13, 0.16, 0.94), "label": "Fuse Box", "shape": "wall_fuse_box"},
		"light_switch": {"base": Color(0.26, 0.25, 0.23, 0.97), "accent": Color(0.98, 0.94, 0.75, 0.99), "outline": Color(0.14, 0.13, 0.12, 0.94), "label": "Light Switch", "shape": "wall_light_switch"},
		"power_switcher": {"base": Color(0.26, 0.25, 0.23, 0.97), "accent": Color(0.98, 0.94, 0.75, 0.99), "outline": Color(0.14, 0.13, 0.12, 0.94), "label": "Power Switcher", "shape": "wall_light_switch"},
		"power_breaker": {"base": Color(0.22, 0.23, 0.24, 0.97), "accent": Color(0.95, 0.72, 0.30, 0.99), "outline": Color(0.13, 0.14, 0.15, 0.94), "label": "Power Breaker", "shape": "wall_breaker_box"},
		"light_switcher": {"base": Color(0.25, 0.24, 0.18, 0.97), "accent": Color(1.0, 0.96, 0.54, 0.99), "outline": Color(0.14, 0.13, 0.10, 0.94), "label": "Light Switcher", "shape": "wall_light_switch"},
		"power_socket": {"base": Color(0.21, 0.22, 0.25, 0.97), "accent": Color(0.78, 0.88, 1.0, 0.99), "outline": Color(0.11, 0.12, 0.15, 0.94), "label": "Power Socket", "shape": "wall_socket"},
		"light": {"base": Color(0.92, 0.86, 0.48, 0.97), "accent": Color(1.0, 0.96, 0.65, 0.99), "outline": Color(0.42, 0.36, 0.14, 0.94), "label": "Light", "shape": "wall_light"},
		"power_cable_reel": {"base": Color(0.2, 0.2, 0.22, 0.97), "accent": Color(0.89, 0.76, 0.47, 0.99), "outline": Color(0.11, 0.11, 0.12, 0.94), "label": "Power Cable Reel", "shape": "wall_cable_reel"},
		"exit": {"base": Color(0.14, 0.3, 0.21, 0.95), "accent": Color(0.48, 0.95, 0.69, 0.95), "outline": Color(0.07, 0.16, 0.11, 0.92), "label": "Exit", "shape": "slab"},
		"key": {"base": Color(0.31, 0.26, 0.12, 0.95), "accent": Color(0.95, 0.83, 0.35, 0.95), "outline": Color(0.2, 0.16, 0.08, 0.92), "label": "Key", "shape": "small_marker"},
		"component": {"base": Color(0.25, 0.25, 0.3, 0.95), "accent": Color(0.72, 0.72, 0.85, 0.95), "outline": Color(0.14, 0.14, 0.17, 0.92), "label": "Component", "shape": "pillar"},
		"hidden_route_node": {"base": Color(0.17, 0.18, 0.27, 0.95), "accent": Color(0.6, 0.58, 0.92, 0.95), "outline": Color(0.1, 0.1, 0.18, 0.92), "label": "Hidden Route Node", "shape": "small_marker"},
		"route_gate": {"base": Color(0.2, 0.2, 0.31, 0.95), "accent": Color(0.64, 0.62, 0.95, 0.95), "outline": Color(0.11, 0.11, 0.2, 0.92), "label": "Route Gate", "shape": "slab"},
		"hot_node": {"base": Color(0.35, 0.15, 0.11, 0.95), "accent": Color(0.96, 0.48, 0.2, 0.95), "outline": Color(0.24, 0.1, 0.08, 0.92), "label": "Hot Node", "shape": "heat_marker"},
		"fan_platform": {"base": Color(0.18, 0.24, 0.29, 0.95), "accent": Color(0.58, 0.78, 0.89, 0.95), "outline": Color(0.1, 0.14, 0.18, 0.92), "label": "Fan Platform", "shape": "slab"},
		"platform_control": {"base": Color(0.2, 0.29, 0.29, 0.95), "accent": Color(0.56, 0.92, 0.88, 0.95), "outline": Color(0.1, 0.16, 0.16, 0.92), "label": "Platform Control", "shape": "small_marker"},
		"fan_control": {"base": Color(0.19, 0.25, 0.29, 0.95), "accent": Color(0.57, 0.82, 0.93, 0.95), "outline": Color(0.1, 0.14, 0.17, 0.92), "label": "Fan Control", "shape": "small_marker"},
		"fan_speed_control": {"base": Color(0.23, 0.26, 0.3, 0.95), "accent": Color(0.77, 0.88, 0.95, 0.95), "outline": Color(0.12, 0.14, 0.18, 0.92), "label": "Fan Speed Control", "shape": "small_marker"},
		"airflow": {"base": Color(0.15, 0.21, 0.26, 0.95), "accent": Color(0.67, 0.89, 0.97, 0.95), "outline": Color(0.09, 0.13, 0.17, 0.92), "label": "Airflow", "shape": "line"},
		"cable_reel": {"base": Color(0.2, 0.2, 0.22, 0.95), "accent": Color(0.74, 0.7, 0.62, 0.95), "outline": Color(0.11, 0.11, 0.12, 0.92), "label": "Cable Reel", "shape": "small_marker"},
		"socket": {"base": Color(0.22, 0.22, 0.25, 0.95), "accent": Color(0.78, 0.85, 0.95, 0.95), "outline": Color(0.12, 0.12, 0.15, 0.92), "label": "Socket", "shape": "small_marker"},
		"power_source": {"base": Color(0.25, 0.28, 0.2, 0.97), "accent": Color(0.95, 0.88, 0.34, 0.99), "outline": Color(0.14, 0.16, 0.1, 0.94), "label": "Power Source", "shape": "slab"},
		"crate": {"base": Color(0.35, 0.23, 0.13, 0.97), "accent": Color(0.86, 0.62, 0.3, 0.99), "outline": Color(0.2, 0.12, 0.07, 0.94), "label": "Crate", "shape": "slab"},
		"barrel": {"base": Color(0.2, 0.3, 0.34, 0.97), "accent": Color(0.57, 0.84, 0.92, 0.99), "outline": Color(0.1, 0.16, 0.19, 0.94), "label": "Barrel", "shape": "pillar"},
		"vagus": {"base": Color(0.25, 0.12, 0.32, 0.97), "accent": Color(0.84, 0.38, 1.0, 0.99), "outline": Color(0.13, 0.06, 0.18, 0.94), "label": "Vagus", "shape": "pillar"},
		"bug": {"base": Color(0.12, 0.32, 0.16, 0.97), "accent": Color(0.55, 0.95, 0.38, 0.99), "outline": Color(0.06, 0.18, 0.08, 0.94), "label": "Bug", "shape": "small_marker"},
		"cable": {"base": Color(0.36, 0.04, 0.04, 0.95), "accent": Color(0.98, 0.12, 0.12, 0.99), "outline": Color(0.18, 0.02, 0.02, 0.92), "label": "Cable", "shape": "line"},
		"generic_object": {"base": Color(0.24, 0.24, 0.28, 0.95), "accent": Color(0.78, 0.8, 0.9, 0.95), "outline": Color(0.14, 0.14, 0.17, 0.92), "label": "Generic Object", "shape": "small_marker"}
	}

func get_iso_object_profile_key_for_tile(tile_type: int) -> String:
	match tile_type:
		GridManager.TILE_DOOR:
			return "door"
		GridManager.TILE_DIGITAL_DOOR:
			return "digital_door"
		GridManager.TILE_POWERED_GATE:
			return "powered_gate"
		GridManager.TILE_TERMINAL:
			return "terminal"
		GridManager.TILE_AIRFLOW_TERMINAL:
			return "airflow_terminal"
		GridManager.TILE_EXIT:
			return "exit"
		GridManager.TILE_KEY:
			return "key"
		GridManager.TILE_COMPONENT:
			return "component"
		GridManager.TILE_HIDDEN_ROUTE_NODE:
			return "hidden_route_node"
		GridManager.TILE_ROUTE_GATE:
			return "route_gate"
		GridManager.TILE_HOT_NODE:
			return "hot_node"
		GridManager.TILE_FAN_PLATFORM:
			return "fan_platform"
		GridManager.TILE_PLATFORM_CONTROL, GridManager.TILE_PLATFORM_CONTROL_LEFT, GridManager.TILE_PLATFORM_CONTROL_RIGHT:
			return "platform_control"
		GridManager.TILE_FAN_CONTROL:
			return "fan_control"
		GridManager.TILE_FAN_SPEED_UP_CONTROL, GridManager.TILE_FAN_SPEED_DOWN_CONTROL:
			return "fan_speed_control"
		GridManager.TILE_AIRFLOW:
			return "airflow"
		GridManager.TILE_CABLE_REEL:
			return "cable_reel"
		GridManager.TILE_SOCKET:
			return "socket"
		GridManager.TILE_CABLE:
			return "cable"
		GridManager.TILE_FLOOR, GridManager.TILE_WALL, GridManager.TILE_STEPPED_FLOOR:
			return ""
	return ""

func is_iso_object_tile(tile_type: int) -> bool:
	return not get_iso_object_profile_key_for_tile(tile_type).is_empty()

func get_iso_object_profile(profile_key: String) -> Dictionary:
	var profiles: Dictionary = get_iso_object_visual_profiles()
	var safe_key: String = profile_key.strip_edges().to_lower()
	if safe_key.is_empty() or not profiles.has(safe_key):
		safe_key = "generic_object"
	var profile: Dictionary = Dictionary(profiles.get(safe_key, profiles.get("generic_object", {})))
	return {
		"base": Color(profile.get("base", Color(0.24, 0.24, 0.28, 0.95))),
		"accent": Color(profile.get("accent", Color(0.78, 0.8, 0.9, 0.95))),
		"outline": Color(profile.get("outline", Color(0.14, 0.14, 0.17, 0.92))),
		"label": str(profile.get("label", "Generic Object")),
		"shape": str(profile.get("shape", "small_marker"))
	}


func _try_parse_cell_variant(cell_variant: Variant, fallback: Vector2i = Vector2i(-1, -1)) -> Vector2i:
	if cell_variant is Vector2i:
		return Vector2i(cell_variant)
	if cell_variant is Vector2:
		var cell_vec2: Vector2 = Vector2(cell_variant)
		return Vector2i(int(round(cell_vec2.x)), int(round(cell_vec2.y)))
	if cell_variant is Array:
		var values: Array = Array(cell_variant)
		if values.size() >= 2:
			return Vector2i(int(values[0]), int(values[1]))
	if cell_variant is String:
		var tokens: PackedStringArray = str(cell_variant).strip_edges().split(",", false)
		if tokens.size() == 2:
			return Vector2i(int(tokens[0]), int(tokens[1]))
	return fallback

func get_wall_mounted_visual_offset(metadata: Dictionary) -> Vector2:
	var wall_side: String = str(metadata.get("wall_side", "")).to_lower().strip_edges()
	var half_size: Vector2 = get_iso_tile_half_size()
	var x_offset: float = half_size.x * 0.34
	var y_offset: float = half_size.y * 0.2
	match wall_side:
		"north":
			return Vector2(0.0, -y_offset)
		"south":
			return Vector2(0.0, y_offset)
		"east":
			return Vector2(x_offset, 0.0)
		"west":
			return Vector2(-x_offset, 0.0)
	return Vector2.ZERO

func get_world_object_visual_position(cell: Vector2i) -> Vector2:
	var base_center: Vector2 = grid_to_iso(cell)
	var metadata: Dictionary = get_wall_metadata_for_cell(cell)
	if metadata.is_empty():
		return base_center
	var placement_mode: String = str(metadata.get("placement_mode", "")).to_lower().strip_edges()
	if placement_mode != "wall_mounted":
		return base_center
	var anchor_cell: Vector2i = _try_parse_cell_variant(metadata.get("anchor_floor_cell", cell), cell)
	var attached_wall_cell: Vector2i = _try_parse_cell_variant(metadata.get("attached_wall_cell", Vector2i(-1, -1)), Vector2i(-1, -1))
	var wall_side: String = str(metadata.get("wall_side", "")).to_lower().strip_edges()
	if wall_side.is_empty() or attached_wall_cell.x < 0 or attached_wall_cell.y < 0:
		return base_center
	if anchor_cell != cell:
		return base_center
	var mount_zones: Array[Dictionary] = get_wall_mounted_anchor_zones(attached_wall_cell)
	for zone_variant in mount_zones:
		var zone: Dictionary = Dictionary(zone_variant)
		if str(zone.get("wall_side", "")) != wall_side:
			continue
		if Vector2i(zone.get("anchor_floor_cell", Vector2i(-1, -1))) != anchor_cell:
			continue
		return Vector2(zone.get("mount_zone_center", base_center))
	return base_center + get_wall_mounted_visual_offset(metadata)

func draw_iso_object_slab(cell: Vector2i, profile: Dictionary, visual_center_override: Vector2 = Vector2.INF) -> void:
	var center: Vector2 = grid_to_iso(cell)
	if visual_center_override != Vector2.INF:
		center = visual_center_override
	var diamond: PackedVector2Array = get_iso_diamond_points(cell)
	if diamond.size() < 4:
		return
	var inset: float = 0.38
	var top_offset: float = -8.0
	var slab_points: PackedVector2Array = PackedVector2Array()
	for point in diamond:
		var offset_point: Vector2 = center + (point - center) * inset + Vector2(0.0, top_offset)
		slab_points.append(offset_point)
	var base_color: Color = _get_color_from_dict(profile, "base", Color.WHITE)
	var accent_color: Color = _get_color_from_dict(profile, "accent", Color.WHITE)
	var outline_color: Color = _get_color_from_dict(profile, "outline", Color.WHITE)
	draw_colored_polygon(slab_points, base_color)
	var accent_start: Vector2 = slab_points[3].lerp(slab_points[0], 0.5)
	var accent_end: Vector2 = slab_points[0].lerp(slab_points[1], 0.5)
	draw_line(accent_start, accent_end, accent_color, 2.0)
	if debug_draw_iso_object_outlines:
		for edge_idx in range(slab_points.size()):
			var next_idx: int = (edge_idx + 1) % slab_points.size()
			draw_line(slab_points[edge_idx], slab_points[next_idx], outline_color, 1.0)

func draw_iso_object_pillar(cell: Vector2i, profile: Dictionary, visual_center_override: Vector2 = Vector2.INF) -> void:
	var center: Vector2 = grid_to_iso(cell)
	if visual_center_override != Vector2.INF:
		center = visual_center_override
	var marker_height: float = maxf(iso_object_marker_height, 1.0)
	var half_width: float = maxf(get_iso_tile_half_size().x * 0.12, 3.0)
	var base_bottom: Vector2 = center + Vector2(0.0, -3.0)
	var base_top: Vector2 = base_bottom + Vector2(0.0, -marker_height)
	var left_bottom: Vector2 = base_bottom + Vector2(-half_width, 0.0)
	var right_bottom: Vector2 = base_bottom + Vector2(half_width, 0.0)
	var left_top: Vector2 = base_top + Vector2(-half_width, 0.0)
	var right_top: Vector2 = base_top + Vector2(half_width, 0.0)
	var body_points: PackedVector2Array = PackedVector2Array([left_top, right_top, right_bottom, left_bottom])
	var base_color: Color = _get_color_from_dict(profile, "base", Color.WHITE)
	var accent_color: Color = _get_color_from_dict(profile, "accent", Color.WHITE)
	var outline_color: Color = _get_color_from_dict(profile, "outline", Color.WHITE)
	draw_colored_polygon(body_points, base_color)
	draw_line(left_top, right_top, accent_color, 2.0)
	if debug_draw_iso_object_outlines:
		for edge_idx in range(body_points.size()):
			var next_idx: int = (edge_idx + 1) % body_points.size()
			draw_line(body_points[edge_idx], body_points[next_idx], outline_color, 1.0)

func draw_iso_object_door_panel(cell: Vector2i, profile: Dictionary, visual_center_override: Vector2 = Vector2.INF) -> void:
	var center: Vector2 = grid_to_iso(cell)
	if visual_center_override != Vector2.INF:
		center = visual_center_override
	var marker_height: float = maxf(iso_object_marker_height + 12.0, 18.0)
	var half_width: float = maxf(get_iso_tile_half_size().x * 0.11, 6.0)
	var panel_bottom: Vector2 = center + Vector2(0.0, -5.0)
	var panel_top: Vector2 = panel_bottom + Vector2(0.0, -marker_height)
	var left_bottom: Vector2 = panel_bottom + Vector2(-half_width, 0.0)
	var right_bottom: Vector2 = panel_bottom + Vector2(half_width, 0.0)
	var left_top: Vector2 = panel_top + Vector2(-half_width, 0.0)
	var right_top: Vector2 = panel_top + Vector2(half_width, 0.0)
	var body_points: PackedVector2Array = PackedVector2Array([left_top, right_top, right_bottom, left_bottom])
	var base_color: Color = _get_color_from_dict(profile, "base", Color.WHITE)
	var accent_color: Color = _get_color_from_dict(profile, "accent", Color.WHITE)
	var outline_color: Color = _get_color_from_dict(profile, "outline", Color.WHITE)
	var frame_color: Color = outline_color.lightened(0.2)
	var frame_left_top: Vector2 = panel_top + Vector2(-half_width - 3.0, -1.0)
	var frame_right_top: Vector2 = panel_top + Vector2(half_width + 3.0, -1.0)
	var frame_left_bottom: Vector2 = panel_bottom + Vector2(-half_width - 3.0, 0.0)
	var frame_right_bottom: Vector2 = panel_bottom + Vector2(half_width + 3.0, 0.0)
	var frame_points: PackedVector2Array = PackedVector2Array([frame_left_top, frame_right_top, frame_right_bottom, frame_left_bottom])
	draw_colored_polygon(frame_points, frame_color.darkened(0.15))
	draw_colored_polygon(body_points, base_color)
	draw_line(left_bottom, left_top, accent_color, 2.2)
	draw_line(right_bottom, right_top, accent_color, 2.2)
	draw_line(left_top.lerp(right_top, 0.2), left_bottom.lerp(right_bottom, 0.2), accent_color, 1.2)
	draw_line(left_top.lerp(right_top, 0.8), left_bottom.lerp(right_bottom, 0.8), accent_color, 1.2)
	if debug_draw_iso_object_outlines:
		for edge_idx in range(body_points.size()):
			var next_idx: int = (edge_idx + 1) % body_points.size()
			draw_line(body_points[edge_idx], body_points[next_idx], outline_color, 1.0)

func draw_iso_object_terminal_console(cell: Vector2i, profile: Dictionary, visual_center_override: Vector2 = Vector2.INF) -> void:
	var center: Vector2 = grid_to_iso(cell)
	if visual_center_override != Vector2.INF:
		center = visual_center_override
	var body_height: float = maxf(iso_object_marker_height + 2.0, 12.0)
	var body_half_width: float = maxf(get_iso_tile_half_size().x * 0.11, 5.0)
	var body_bottom: Vector2 = center + Vector2(0.0, -3.0)
	var body_top: Vector2 = body_bottom + Vector2(0.0, -body_height)
	var body: PackedVector2Array = PackedVector2Array([
		body_top + Vector2(-body_half_width, 0.0),
		body_top + Vector2(body_half_width, 0.0),
		body_bottom + Vector2(body_half_width, 0.0),
		body_bottom + Vector2(-body_half_width, 0.0)
	])
	var screen: Rect2 = Rect2(center + Vector2(-body_half_width + 1.0, -body_height + 2.0), Vector2(body_half_width * 2.0 - 2.0, body_height * 0.36))
	var base_color: Color = _get_color_from_dict(profile, "base", Color.WHITE)
	var accent_color: Color = _get_color_from_dict(profile, "accent", Color.WHITE)
	var outline_color: Color = _get_color_from_dict(profile, "outline", Color.WHITE)
	draw_colored_polygon(body, base_color)
	draw_rect(screen, accent_color, true)
	draw_line(screen.position + Vector2(0.0, screen.size.y), screen.position + screen.size, accent_color.lightened(0.25), 1.4)
	if debug_draw_iso_object_outlines:
		for edge_idx in range(body.size()):
			var next_idx: int = (edge_idx + 1) % body.size()
			draw_line(body[edge_idx], body[next_idx], outline_color, 1.0)
		draw_rect(screen, outline_color, false, 1.0)

func draw_iso_object_small_marker(cell: Vector2i, profile: Dictionary, visual_center_override: Vector2 = Vector2.INF) -> void:
	var center: Vector2 = grid_to_iso(cell)
	if visual_center_override != Vector2.INF:
		center = visual_center_override
	center += Vector2(0.0, -6.0)
	var radius: float = maxf(get_iso_tile_half_size().y * 0.16, 3.0)
	var base_color: Color = _get_color_from_dict(profile, "base", Color.WHITE)
	var accent_color: Color = _get_color_from_dict(profile, "accent", Color.WHITE)
	var outline_color: Color = _get_color_from_dict(profile, "outline", Color.WHITE)
	draw_circle(center, radius, base_color)
	draw_circle(center + Vector2(0.0, -radius * 0.3), radius * 0.45, accent_color)
	if debug_draw_iso_object_outlines:
		draw_arc(center, radius, 0.0, PI * 2.0, 24, outline_color, 1.0)

func draw_iso_object_line(cell: Vector2i, profile: Dictionary, visual_center_override: Vector2 = Vector2.INF) -> void:
	var center: Vector2 = grid_to_iso(cell)
	if visual_center_override != Vector2.INF:
		center = visual_center_override
	center += Vector2(0.0, -4.0)
	var half_width: float = maxf(get_iso_tile_half_size().x * 0.26, 8.0)
	var line_start: Vector2 = center + Vector2(-half_width, 0.0)
	var line_end: Vector2 = center + Vector2(half_width, 0.0)
	var base_color: Color = _get_color_from_dict(profile, "base", Color.WHITE)
	var accent_color: Color = _get_color_from_dict(profile, "accent", Color.WHITE)
	var outline_color: Color = _get_color_from_dict(profile, "outline", Color.WHITE)
	draw_line(line_start, line_end, base_color, 3.0)
	draw_line(center + Vector2(-half_width * 0.6, -2.0), center + Vector2(half_width * 0.6, -2.0), accent_color, 1.6)
	if debug_draw_iso_object_outlines:
		draw_line(line_start, line_end, outline_color, 1.0)

func _get_line_color_from_id(color_id: String, fallback: Color) -> Color:
	match color_id.strip_edges().to_lower():
		"red": return Color(1.0, 0.22, 0.18, fallback.a)
		"blue": return Color(0.22, 0.48, 1.0, fallback.a)
		"green": return Color(0.24, 0.92, 0.42, fallback.a)
		"yellow": return Color(1.0, 0.88, 0.2, fallback.a)
		"orange": return Color(1.0, 0.55, 0.18, fallback.a)
		"purple": return Color(0.72, 0.38, 1.0, fallback.a)
		"white": return Color(0.95, 0.95, 0.92, fallback.a)
	return fallback

func draw_iso_cable_topology_line(cell: Vector2i, profile: Dictionary, object_data: Dictionary, visual_center_override: Vector2 = Vector2.INF) -> void:
	var visual_center: Vector2 = grid_to_iso(cell)
	if visual_center_override != Vector2.INF:
		visual_center = visual_center_override
	var topology: Dictionary = CableTopologyServiceRef.classify_cell(cell, _get_runtime_world_objects_for_iso_render(true), object_data)
	draw_iso_cable_segment_shape(cell, topology, profile, visual_center, object_data)

func draw_iso_cable_segment_shape(cell: Vector2i, topology: Dictionary, profile: Dictionary, visual_center: Vector2, object_data: Dictionary = {}) -> void:
	var install_mode: String = get_cable_install_mode(object_data)
	var health_state: String = get_cable_health_state(object_data)
	var editor_render: bool = is_map_constructor_editor_render()
	if install_mode == "hidden" and not editor_render:
		return
	var cable_center: Vector2 = visual_center + Vector2(0.0, -4.0)
	if install_mode == "wall" and _cell_has_wall_for_iso_cable(cell):
		cable_center = _get_iso_cable_wall_center(visual_center)
		if draw_wall_cable_visual_path(cell, object_data, visual_center, profile, topology):
			if health_state in ["damaged", "broken", "cut"]:
				draw_iso_cable_damage_marker(_get_wall_cable_rail_anchor(cell, get_cable_wall_side(object_data)), health_state, profile)
			return
	var route_plan: Dictionary = RouteRendererRef.build_floor_topology_plan(topology)
	var shape: String = str(route_plan.get("shape", "isolated"))
	var object_links: Dictionary = Dictionary(topology.get("object_links", {}))
	var has_switch: bool = bool(route_plan.get("has_switch", false))
	var valid: bool = bool(route_plan.get("valid", true))
	var active_dirs: Array[String] = []
	for direction_variant in Array(route_plan.get("active_dirs", [])):
		active_dirs.append(str(direction_variant))

	var base_color: Color = _get_color_from_dict(profile, "base", Color.WHITE)
	var accent_color: Color = _get_color_from_dict(profile, "accent", Color.WHITE)
	var line_color_id: String = str(object_data.get("line_color_id", object_data.get("color_id", ""))).strip_edges()
	if not line_color_id.is_empty():
		accent_color = _get_line_color_from_id(line_color_id, accent_color)
		base_color = _get_line_color_from_id(line_color_id, base_color).darkened(0.35)
	var outline_color: Color = _get_color_from_dict(profile, "outline", Color.WHITE)
	if install_mode == "hidden":
		base_color = Color(base_color.r, base_color.g, base_color.b, 0.72)
		accent_color = Color(accent_color.r, accent_color.g, accent_color.b, 0.82)
	if install_mode == "wall":
		base_color = base_color.lightened(0.08)
		accent_color = accent_color.lightened(0.12)
	if not valid:
		base_color = Color(1.0, 0.25, 0.08, 0.98)
		accent_color = Color(1.0, 0.82, 0.15, 0.98)
		outline_color = Color(0.45, 0.04, 0.02, 0.98)
	var cable_profile: Dictionary = profile.duplicate()
	cable_profile["base"] = base_color
	cable_profile["accent"] = accent_color
	cable_profile["outline"] = outline_color
	cable_profile["install_mode"] = install_mode

	var drew_any_line: bool = false
	if active_dirs.is_empty():
		var isolated_half_width: float = maxf(get_iso_tile_half_size().x * 0.12, 7.0)
		var isolated_start: Vector2 = cable_center + Vector2(-isolated_half_width, 0.0)
		var isolated_end: Vector2 = cable_center + Vector2(isolated_half_width, 0.0)
		draw_iso_cable_mode_segment(isolated_start, isolated_end, cable_profile)
		draw_circle(cable_center, 4.5, accent_color)
		draw_arc(cable_center, 7.0, 0.0, PI * 2.0, 20, outline_color, 1.4, true)
		drew_any_line = true
	else:
		if active_dirs.size() == 2 and not shape.begins_with("junction") and not shape.begins_with("invalid"):
			if (active_dirs.has("east") and active_dirs.has("west")) or (active_dirs.has("north") and active_dirs.has("south")):
				draw_iso_cable_mode_polyline([_get_iso_cable_branch_endpoint_for_visual_center(cell, active_dirs[0], cable_center), _get_iso_cable_branch_endpoint_for_visual_center(cell, active_dirs[1], cable_center)], cable_profile)
			else:
				draw_iso_cable_elbow(cable_center, active_dirs[0], active_dirs[1], cable_profile)
		else:
			for direction in active_dirs:
				draw_iso_cable_mode_polyline([cable_center, _get_iso_cable_branch_endpoint_for_visual_center(cell, direction, cable_center)], cable_profile)
		drew_any_line = true

	draw_iso_cable_object_links(cell, object_links, cable_center, cable_profile)
	if active_dirs.size() == 1 and not has_switch:
		draw_iso_cable_endpoint_cap(_get_iso_cable_branch_endpoint_for_visual_center(cell, active_dirs[0], cable_center), active_dirs[0], accent_color)
	if not valid:
		draw_iso_cable_invalid_marker(cable_center, shape)
	elif shape.begins_with("junction") and not has_switch:
		draw_circle(cable_center, 3.6, accent_color)
	if health_state in ["damaged", "broken", "cut"] and drew_any_line:
		draw_iso_cable_damage_marker(cable_center, health_state, cable_profile)
	if debug_draw_iso_object_outlines:
		for direction in active_dirs:
			draw_line(cable_center, _get_iso_cable_branch_endpoint_for_visual_center(cell, direction, cable_center), outline_color, 1.0, true)

func get_cable_install_mode(object_data: Dictionary) -> String:
	return RouteRendererRef.normalize_install_mode(object_data)

func get_cable_health_state(object_data: Dictionary) -> String:
	return RouteRendererRef.get_health_state(object_data)

func is_map_constructor_editor_render() -> bool:
	return map_constructor_editor_render_active

func _cell_has_wall_for_iso_cable(cell: Vector2i) -> bool:
	if _grid_manager == null or not _grid_manager.has_method("get_tile"):
		return false
	if _grid_manager.has_method("is_in_bounds") and not bool(_grid_manager.call("is_in_bounds", cell)):
		return false
	return is_wall_tile(int(_grid_manager.call("get_tile", cell)))

func _get_iso_cable_wall_center(visual_center: Vector2) -> Vector2:
	return visual_center + Vector2(0.0, -maxf(iso_wall_height * 0.48, 18.0))

func draw_iso_cable_mode_polyline(points: Array[Vector2], profile: Dictionary) -> void:
	if points.size() < 2:
		return
	for index in range(points.size() - 1):
		draw_iso_cable_mode_segment(points[index], points[index + 1], profile)

func draw_iso_cable_mode_segment(start: Vector2, end: Vector2, profile: Dictionary) -> void:
	_draw_route_commands(RouteRendererRef.build_floor_mode_segment_commands(start, end, str(profile.get("install_mode", "floor"))))

func draw_iso_cable_hidden_segment(start: Vector2, end: Vector2, profile: Dictionary) -> void:
	var delta: Vector2 = end - start
	var length: float = delta.length()
	if length <= 0.1:
		return
	var dir: Vector2 = delta / length
	var dash: float = 7.0
	var gap: float = 5.0
	var cursor: float = 0.0
	while cursor < length:
		var dash_end: float = minf(cursor + dash, length)
		var a: Vector2 = start + dir * cursor
		var b: Vector2 = start + dir * dash_end
		_draw_iso_cable_polyline([a, b], profile)
		cursor += dash + gap

func draw_iso_cable_wall_segment(start: Vector2, end: Vector2, profile: Dictionary) -> void:
	_draw_iso_cable_polyline([start, end], profile)
	draw_line(start + Vector2(0.0, 2.0), end + Vector2(0.0, 2.0), Color(0.0, 0.0, 0.0, 0.18), 2.0, true)

func get_cable_bridge_network_id(object_data: Dictionary) -> String:
	for key in ["power_network_id", "cable_network_id", "network_id", "connection_id", "circuit_id", "cable_chain_id", "power_circuit_id", "chain_id", "link_group", "cable_group", "connected_circuit"]:
		var value: String = str(object_data.get(key, "")).strip_edges()
		if not value.is_empty():
			return value
	return ""

func is_power_cable_bridge_connectable_object(object_data: Dictionary) -> bool:
	if CableTopologyServiceRef.is_cable_object(object_data) and not CableTopologyServiceRef.is_circuit_switch_object(object_data):
		return false
	if CableTopologyServiceRef.is_circuit_connectable_object(object_data):
		return true
	var object_type: String = str(object_data.get("object_type", object_data.get("type", object_data.get("item_type", "")))).strip_edges().to_lower()
	return object_type in ["power_source", "power_socket", "socket", "fuse_box", "power_switcher", "light_switcher", "light", "terminal"]

func should_draw_object_cable_bridge(object_data: Dictionary, object_cell: Vector2i, cable_data: Dictionary, cable_cell: Vector2i) -> bool:
	var delta: Vector2i = cable_cell - object_cell
	if abs(delta.x) + abs(delta.y) != 1:
		return false
	if not bool(cable_data.get("has_cable", false)) and not CableTopologyServiceRef.is_cable_object(cable_data):
		return false
	if not is_power_cable_bridge_connectable_object(object_data):
		return false
	var object_network_id: String = get_cable_bridge_network_id(object_data)
	var cable_network_id: String = get_cable_bridge_network_id(cable_data)
	if cable_network_id.is_empty() and cable_data.has("objects"):
		for cable_object_variant in Array(cable_data.get("objects", [])):
			if not cable_object_variant is Dictionary:
				continue
			cable_network_id = get_cable_bridge_network_id(Dictionary(cable_object_variant))
			if not cable_network_id.is_empty():
				break
	if object_network_id.is_empty() or cable_network_id.is_empty():
		return false
	return object_network_id == cable_network_id

func get_cell_edge_bridge_points(from_cell: Vector2i, to_cell: Vector2i) -> Dictionary:
	var from_center: Vector2 = grid_to_iso(from_cell) + Vector2(0.0, -4.0)
	var to_center: Vector2 = grid_to_iso(to_cell) + Vector2(0.0, -4.0)
	var shared_edge: Vector2 = from_center.lerp(to_center, 0.5)
	return {
		"from_center": from_center,
		"from_edge_towards_to": shared_edge,
		"to_edge_towards_from": shared_edge,
		"to_center": to_center
	}

func draw_object_cable_bridge(object_data: Dictionary, object_cell: Vector2i, cable_data: Dictionary, cable_cell: Vector2i, profile: Dictionary) -> void:
	var points: Dictionary = get_cell_edge_bridge_points(object_cell, cable_cell)
	draw_iso_cable_mode_segment(Vector2(points.get("from_center", Vector2.ZERO)), Vector2(points.get("from_edge_towards_to", Vector2.ZERO)), profile)
	draw_iso_cable_mode_segment(Vector2(points.get("to_center", Vector2.ZERO)), Vector2(points.get("to_edge_towards_from", Vector2.ZERO)), profile)
	if debug_log_cable_object_bridges:
		print("[CableObjectBridge] object_id=%s object_type=%s object_cell=%s cable_id=%s cable_cell=%s same_chain=true direction=%s" % [
			str(object_data.get("id", object_data.get("object_id", ""))),
			str(object_data.get("object_type", object_data.get("type", object_data.get("item_type", "")))),
			str(object_cell),
			str(cable_data.get("id", cable_data.get("object_id", cable_data.get("circuit_id", "")))),
			str(cable_cell),
			str(cable_cell - object_cell)
		])

func draw_iso_cable_damage_marker(center: Vector2, health_state: String, _profile: Dictionary = {}) -> void:
	var state: String = health_state.strip_edges().to_lower()
	if state not in ["damaged", "broken", "cut"]:
		return

	var marker_color: Color = Color(1.0, 0.74, 0.20, 0.96)
	if state == "broken" or state == "cut":
		marker_color = Color(1.0, 0.22, 0.16, 0.96)

	draw_circle(center, 4.0, Color(0.02, 0.02, 0.025, 0.86))
	draw_line(center + Vector2(-4.0, -4.0), center + Vector2(4.0, 4.0), marker_color, 1.8, true)
	draw_line(center + Vector2(-4.0, 4.0), center + Vector2(4.0, -4.0), marker_color, 1.8, true)
	
func draw_iso_cable_object_links(_cell: Vector2i, object_links: Dictionary, cable_center: Vector2, profile: Dictionary) -> void:
	if object_links.is_empty():
		return
	var base_color: Color = _get_color_from_dict(profile, "base", Color.WHITE).lightened(0.12)
	var accent_color: Color = _get_color_from_dict(profile, "accent", Color.WHITE)
	var outline_color: Color = _get_color_from_dict(profile, "outline", Color.WHITE)
	for direction_variant in object_links.keys():
		var direction: String = str(direction_variant)
		var dir_vector: Vector2 = _get_iso_cable_screen_direction(direction).normalized()
		if dir_vector == Vector2.ZERO:
			continue
		var tile_dir_length: float = _get_iso_cable_screen_direction(direction).length()
		var link_start: Vector2 = cable_center + dir_vector * minf(tile_dir_length * 0.18, 12.0)
		var link_end: Vector2 = cable_center + dir_vector * minf(tile_dir_length * 0.34, 22.0)
		if str(profile.get("install_mode", "floor")) == "hidden":
			draw_iso_cable_hidden_segment(link_start, link_end, profile)
		else:
			draw_line(link_start + Vector2(0.0, 1.3), link_end + Vector2(0.0, 1.3), Color(0.03, 0.02, 0.02, 0.22), 4.0, true)
			draw_line(link_start, link_end, outline_color, 3.0, true)
			draw_line(link_start, link_end, base_color, 1.9, true)
		draw_circle(link_end, 2.3, accent_color)

func _draw_iso_cable_polyline(points: Array[Vector2], profile: Dictionary) -> void:
	if points.size() < 2:
		return
	var packed_points: PackedVector2Array = PackedVector2Array(points)
	var shadow_points: PackedVector2Array = PackedVector2Array()
	for point in points:
		shadow_points.append(point + Vector2(0.0, 2.0))
	var base_color: Color = _get_color_from_dict(profile, "base", Color.WHITE)
	var accent_color: Color = _get_color_from_dict(profile, "accent", Color.WHITE)
	var outline_color: Color = _get_color_from_dict(profile, "outline", Color.WHITE)
	draw_polyline(shadow_points, Color(0.03, 0.02, 0.02, 0.28), 7.0, true)
	draw_polyline(packed_points, outline_color, 6.0, true)
	draw_polyline(packed_points, base_color, 4.0, true)
	draw_polyline(packed_points, accent_color, 1.5, true)

func draw_iso_cable_endpoint_cap(center: Vector2, direction: String, color: Color) -> void:
	var dir_vector: Vector2 = _get_iso_cable_screen_direction(direction).normalized()
	var normal: Vector2 = Vector2(-dir_vector.y, dir_vector.x).normalized()
	var outline_color: Color = Color(0.1, 0.03, 0.02, 0.95)
	draw_line(center - normal * 5.0 + dir_vector * 1.0, center + normal * 5.0 + dir_vector * 1.0, outline_color, 4.4, true)
	draw_line(center - normal * 4.0 + dir_vector * 1.0, center + normal * 4.0 + dir_vector * 1.0, color, 2.2, true)
	draw_line(center, center + dir_vector * 5.0, color.lightened(0.18), 1.2, true)

func draw_iso_cable_elbow(center: Vector2, dir_a: String, dir_b: String, profile: Dictionary) -> void:
	var endpoint_a: Vector2 = center + _get_iso_cable_screen_direction(dir_a) * 0.5
	var endpoint_b: Vector2 = center + _get_iso_cable_screen_direction(dir_b) * 0.5
	draw_iso_cable_mode_polyline([endpoint_a, center, endpoint_b], profile)
	var base_color: Color = _get_color_from_dict(profile, "base", Color.WHITE)
	var accent_color: Color = _get_color_from_dict(profile, "accent", Color.WHITE)
	draw_circle(center, 2.7, base_color)
	draw_circle(center + Vector2(0.0, -0.4), 1.2, accent_color)

func draw_iso_cable_invalid_marker(center: Vector2, shape: String) -> void:
	var marker_radius: float = 7.0 if shape == "invalid_cross" else 6.0
	draw_circle(center + Vector2(0.0, -1.0), marker_radius, Color(0.44, 0.04, 0.02, 0.96))
	draw_line(center + Vector2(-marker_radius * 0.55, -marker_radius * 0.55 - 1.0), center + Vector2(marker_radius * 0.55, marker_radius * 0.55 - 1.0), Color(1.0, 0.82, 0.15, 0.98), 2.2, true)
	draw_line(center + Vector2(marker_radius * 0.55, -marker_radius * 0.55 - 1.0), center + Vector2(-marker_radius * 0.55, marker_radius * 0.55 - 1.0), Color(1.0, 0.82, 0.15, 0.98), 2.2, true)

func get_iso_cable_branch_endpoint(cell: Vector2i, direction: String) -> Vector2:
	return grid_to_iso(cell) + Vector2(0.0, -4.0) + _get_iso_cable_screen_direction(direction) * 0.5

func _get_iso_cable_branch_endpoint_for_visual_center(cell: Vector2i, direction: String, cable_center: Vector2) -> Vector2:
	# Keep preview and final cable cells on the same topology-aware drawing path while
	# preserving any grounded visual-center offset supplied by object preview code.
	var default_center: Vector2 = grid_to_iso(cell) + Vector2(0.0, -4.0)
	return cable_center + (get_iso_cable_branch_endpoint(cell, direction) - default_center)

func _get_iso_cable_screen_direction(direction: String) -> Vector2:
	match direction:
		"north":
			return grid_to_iso(Vector2i(0, -1)) - grid_to_iso(Vector2i.ZERO)
		"south":
			return grid_to_iso(Vector2i(0, 1)) - grid_to_iso(Vector2i.ZERO)
		"west":
			return grid_to_iso(Vector2i(-1, 0)) - grid_to_iso(Vector2i.ZERO)
		"east":
			return grid_to_iso(Vector2i(1, 0)) - grid_to_iso(Vector2i.ZERO)
		_:
			return Vector2.RIGHT

func draw_iso_object_heat_marker(cell: Vector2i, profile: Dictionary, visual_center_override: Vector2 = Vector2.INF) -> void:
	var center: Vector2 = grid_to_iso(cell)
	if visual_center_override != Vector2.INF:
		center = visual_center_override
	center += Vector2(0.0, -7.0)
	var radius: float = maxf(get_iso_tile_half_size().y * 0.18, 3.5)
	var base_color: Color = _get_color_from_dict(profile, "base", Color.WHITE)
	var accent_color: Color = _get_color_from_dict(profile, "accent", Color.WHITE)
	var outline_color: Color = _get_color_from_dict(profile, "outline", Color.WHITE)
	draw_circle(center, radius, base_color)
	draw_circle(center, radius * 0.58, accent_color)
	if debug_draw_iso_object_outlines:
		draw_arc(center, radius, 0.0, PI * 2.0, 24, outline_color, 1.0)


func get_wall_mounted_object_profile_key(cell: Vector2i) -> String:
	var metadata: Dictionary = get_wall_metadata_for_cell(cell)
	if metadata.is_empty():
		return ""
	if str(metadata.get("placement_mode", "")).to_lower().strip_edges() != "wall_mounted":
		return ""
	var candidates: Array[String] = [
		str(metadata.get("visual_profile", "")),
		str(metadata.get("object_type", "")),
		str(metadata.get("catalog_id", "")),
		str(metadata.get("type", "")),
		str(metadata.get("id", ""))
	]
	for candidate in candidates:
		var normalized: String = candidate.strip_edges().to_lower()
		match normalized:
			"door_terminal", "platform_terminal", "cooling_terminal", "firewall", "circuit_breaker", "fuse_box", "light_switch", "power_switcher", "power_socket", "light", "power_cable", "power_cable_reel", "external_air_duct", "external_water_pipe":
				return normalized
	return ""

func is_terminal_like_profile(profile_key: String) -> bool:
	match profile_key:
		"terminal", "airflow_terminal", "door_terminal", "platform_terminal", "cooling_terminal":
			return true
	return false

func is_door_like_profile(profile_key: String) -> bool:
	match profile_key:
		"door", "digital_door", "powered_gate":
			return true
	return false

func get_wall_mounted_attached_depth_cell(cell: Vector2i) -> Vector2i:
	var object_metadata: Dictionary = _get_iso_world_object_metadata_for_cell(cell)
	var world_object_data: Dictionary = Dictionary(object_metadata.get("data", {}))
	var attached_wall_cell: Vector2i = _try_parse_cell_variant(world_object_data.get("attached_wall_cell", Vector2i(-1, -1)), Vector2i(-1, -1))
	if attached_wall_cell.x >= 0 and attached_wall_cell.y >= 0:
		return attached_wall_cell
	var wall_metadata: Dictionary = get_wall_metadata_for_cell(cell)
	if wall_metadata.is_empty():
		return cell
	attached_wall_cell = _try_parse_cell_variant(wall_metadata.get("attached_wall_cell", Vector2i(-1, -1)), Vector2i(-1, -1))
	if attached_wall_cell.x >= 0 and attached_wall_cell.y >= 0:
		return attached_wall_cell
	return cell

func draw_iso_wall_terminal_panel(center: Vector2, profile: Dictionary, screen_tint: Color) -> void:
	var base_color: Color = _get_color_from_dict(profile, "base", Color.WHITE)
	var accent_color: Color = _get_color_from_dict(profile, "accent", Color.WHITE)
	var outline_color: Color = _get_color_from_dict(profile, "outline", Color.WHITE)
	var body: Rect2 = Rect2(center + Vector2(-8.0, -18.0), Vector2(16.0, 16.0))
	var screen: Rect2 = Rect2(body.position + Vector2(2.0, 3.0), Vector2(body.size.x - 4.0, 6.0))
	draw_rect(body, base_color, true)
	draw_rect(screen, screen_tint, true)
	draw_line(screen.position + Vector2(0.0, screen.size.y), screen.position + screen.size, accent_color, 1.2)
	if debug_draw_iso_object_outlines:
		draw_rect(body, outline_color, false, 1.0)
		draw_rect(screen, outline_color, false, 1.0)

func draw_iso_wall_door_terminal(center: Vector2, profile: Dictionary) -> void:
	draw_iso_wall_terminal_panel(center, profile, Color(0.36, 0.95, 1.0, 0.98))
	var glow_rect: Rect2 = Rect2(center + Vector2(-5.0, -8.0), Vector2(10.0, 2.0))
	draw_rect(glow_rect, Color(0.62, 1.0, 1.0, 0.94), true)
	if debug_draw_iso_object_outlines:
		draw_rect(glow_rect, _get_color_from_dict(profile, "outline", Color.WHITE), false, 1.0)

func draw_iso_wall_platform_terminal(center: Vector2, profile: Dictionary) -> void:
	draw_iso_wall_terminal_panel(center, profile, Color(1.0, 0.72, 0.24, 0.98))
	var indicator_y: float = center.y - 8.5
	draw_line(center + Vector2(-5.6, indicator_y), center + Vector2(5.6, indicator_y), Color(1.0, 0.86, 0.45, 0.92), 1.5)
	draw_circle(center + Vector2(4.8, -14.0), 1.1, Color(1.0, 0.56, 0.18, 0.95))
	if debug_draw_iso_object_outlines:
		draw_arc(center + Vector2(4.8, -14.0), 1.1, 0.0, PI * 2.0, 12, _get_color_from_dict(profile, "outline", Color.WHITE), 1.0)

func draw_iso_wall_cooling_terminal(center: Vector2, profile: Dictionary) -> void:
	draw_iso_wall_terminal_panel(center, profile, Color(0.54, 0.82, 1.0, 0.98))
	for fin_idx in range(3):
		var fin_x: float = center.x - 4.0 + float(fin_idx) * 3.8
		draw_line(Vector2(fin_x, center.y - 14.8), Vector2(fin_x, center.y - 4.8), Color(0.82, 0.94, 1.0, 0.78), 1.1)

func draw_iso_wall_firewall_panel(center: Vector2, profile: Dictionary) -> void:
	draw_iso_wall_terminal_panel(center, profile, Color(1.0, 0.26, 0.22, 0.99))
	var warning_top: Vector2 = center + Vector2(0.0, -17.0)
	draw_line(warning_top + Vector2(-5.0, 9.0), warning_top + Vector2(0.0, 0.0), Color(1.0, 0.9, 0.34, 0.98), 1.5)
	draw_line(warning_top + Vector2(0.0, 0.0), warning_top + Vector2(5.0, 9.0), Color(1.0, 0.9, 0.34, 0.98), 1.5)
	draw_line(warning_top + Vector2(5.0, 9.0), warning_top + Vector2(-5.0, 9.0), Color(1.0, 0.9, 0.34, 0.98), 1.5)

func draw_iso_wall_breaker_box(center: Vector2, profile: Dictionary) -> void:
	var base_color: Color = _get_color_from_dict(profile, "base", Color.WHITE)
	var accent_color: Color = _get_color_from_dict(profile, "accent", Color.WHITE)
	var outline_color: Color = _get_color_from_dict(profile, "outline", Color.WHITE)
	var box: Rect2 = Rect2(center + Vector2(-7.0, -16.0), Vector2(14.0, 13.0))
	draw_rect(box, base_color, true)
	var lever_pivot: Vector2 = box.position + Vector2(box.size.x * 0.35, box.size.y * 0.45)
	draw_circle(lever_pivot, 1.4, accent_color)
	draw_line(lever_pivot, lever_pivot + Vector2(4.2, -3.4), accent_color, 2.0)
	if debug_draw_iso_object_outlines:
		draw_rect(box, outline_color, false, 1.0)

func draw_iso_wall_fuse_box(center: Vector2, profile: Dictionary) -> void:
	var base_color: Color = _get_color_from_dict(profile, "base", Color.WHITE)
	var accent_color: Color = _get_color_from_dict(profile, "accent", Color.WHITE)
	var outline_color: Color = _get_color_from_dict(profile, "outline", Color.WHITE)
	var box: Rect2 = Rect2(center + Vector2(-8.0, -16.0), Vector2(16.0, 13.0))
	draw_rect(box, base_color, true)
	for slot_idx in range(3):
		var slot_x: float = box.position.x + 3.0 + float(slot_idx) * 4.2
		draw_rect(Rect2(Vector2(slot_x, box.position.y + 3.0), Vector2(2.6, 7.0)), accent_color.darkened(0.2), true)
	if debug_draw_iso_object_outlines:
		draw_rect(box, outline_color, false, 1.0)

func draw_iso_wall_light_switch(center: Vector2, profile: Dictionary) -> void:
	var base_color: Color = _get_color_from_dict(profile, "base", Color.WHITE)
	var accent_color: Color = _get_color_from_dict(profile, "accent", Color.WHITE)
	var outline_color: Color = _get_color_from_dict(profile, "outline", Color.WHITE)
	var plate: Rect2 = Rect2(center + Vector2(-4.0, -12.0), Vector2(8.0, 10.0))
	var switch_rect: Rect2 = Rect2(plate.position + Vector2(2.5, 2.2), Vector2(3.0, 4.6))
	draw_rect(plate, base_color, true)
	draw_rect(switch_rect, accent_color, true)
	if debug_draw_iso_object_outlines:
		draw_rect(plate, outline_color, false, 1.0)

func draw_iso_socket(center: Vector2, profile: Dictionary) -> void:
	var base_color: Color = _get_color_from_dict(profile, "base", Color.WHITE)
	var accent_color: Color = _get_color_from_dict(profile, "accent", Color.WHITE)
	var outline_color: Color = _get_color_from_dict(profile, "outline", Color.WHITE)
	var plate: Rect2 = Rect2(center + Vector2(-5.0, -13.0), Vector2(10.0, 9.0))
	draw_rect(plate, base_color, true)
	draw_circle(plate.position + Vector2(3.2, 4.5), 1.1, accent_color)
	draw_circle(plate.position + Vector2(6.8, 4.5), 1.1, accent_color)
	if debug_draw_iso_object_outlines:
		draw_rect(plate, outline_color, false, 1.0)

func draw_iso_light_marker(center: Vector2, profile: Dictionary) -> void:
	var base_color: Color = _get_color_from_dict(profile, "base", Color.WHITE)
	var accent_color: Color = _get_color_from_dict(profile, "accent", Color.WHITE)
	var outline_color: Color = _get_color_from_dict(profile, "outline", Color.WHITE)
	var lamp_center: Vector2 = center + Vector2(0.0, -11.0)
	draw_circle(lamp_center, 5.0, base_color)
	draw_circle(lamp_center, 2.7, accent_color)
	draw_line(lamp_center + Vector2(-5.0, 4.0), lamp_center + Vector2(5.0, 4.0), outline_color, 1.0)
	if debug_draw_iso_object_outlines:
		draw_arc(lamp_center, 5.0, 0.0, PI * 2.0, 24, outline_color, 1.0)

func draw_iso_wall_cable_reel(center: Vector2, profile: Dictionary) -> void:
	var base_color: Color = _get_color_from_dict(profile, "base", Color.WHITE)
	var accent_color: Color = _get_color_from_dict(profile, "accent", Color.WHITE)
	var outline_color: Color = _get_color_from_dict(profile, "outline", Color.WHITE)
	var reel_center: Vector2 = center + Vector2(0.0, -10.0)
	draw_circle(reel_center, 6.0, base_color)
	draw_arc(reel_center, 5.0, 0.0, PI * 1.75, 20, accent_color, 1.8)
	draw_arc(reel_center, 3.0, 0.0, PI * 1.75, 20, accent_color, 1.5)
	draw_circle(reel_center, 1.4, accent_color)
	if debug_draw_iso_object_outlines:
		draw_arc(reel_center, 6.0, 0.0, PI * 2.0, 24, outline_color, 1.0)

func draw_wall_mounted_object_shape(_cell: Vector2i, profile_key: String, profile: Dictionary, visual_center: Vector2) -> bool:
	match profile_key:
		"door_terminal":
			draw_iso_wall_door_terminal(visual_center, profile)
			return true
		"platform_terminal":
			draw_iso_wall_platform_terminal(visual_center, profile)
			return true
		"cooling_terminal":
			draw_iso_wall_cooling_terminal(visual_center, profile)
			return true
		"firewall":
			draw_iso_wall_firewall_panel(visual_center, profile)
			return true
		"circuit_breaker":
			draw_iso_wall_breaker_box(visual_center, profile)
			return true
		"fuse_box":
			draw_iso_wall_fuse_box(visual_center, profile)
			return true
		"light_switch", "power_switcher":
			draw_iso_wall_light_switch(visual_center, profile)
			return true
		"power_socket":
			draw_iso_socket(visual_center, profile)
			return true
		"light":
			draw_iso_light_marker(visual_center, profile)
			return true
		"power_cable_reel":
			draw_iso_wall_cable_reel(visual_center, profile)
			return true
	return false

func get_iso_object_grounding_profile(object_data: Dictionary, fallback_cell: Vector2i = Vector2i(-1, -1)) -> Dictionary:
	var object_id: String = str(object_data.get("id", "")).strip_edges()
	var object_type: String = str(object_data.get("object_type", object_data.get("type", ""))).to_lower().strip_edges()
	var placement_mode: String = str(object_data.get("placement_mode", "")).to_lower().strip_edges()
	var anchor_cell: Vector2i = _try_parse_cell_variant(object_data.get("anchor_floor_cell", Vector2i(-1, -1)), Vector2i(-1, -1))
	var attached_wall_cell: Vector2i = _try_parse_cell_variant(object_data.get("attached_wall_cell", Vector2i(-1, -1)), Vector2i(-1, -1))
	var wall_side: String = str(object_data.get("wall_side", "")).to_lower().strip_edges()
	if anchor_cell.x < 0 or anchor_cell.y < 0:
		anchor_cell = _try_parse_cell_variant(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
	if anchor_cell.x < 0 or anchor_cell.y < 0:
		anchor_cell = fallback_cell
	if anchor_cell.x < 0 or anchor_cell.y < 0:
		anchor_cell = Vector2i(0, 0)
	var center: Vector2 = grid_to_iso(anchor_cell)
	if is_wall_mounted_runtime_object(object_data):
		center = get_wall_mounted_visual_center(object_data, fallback_cell)
	var grounding_type: String = "floor_standing"
	if object_data.is_empty():
		grounding_type = "unknown"
	if is_wall_mounted_runtime_object(object_data):
		grounding_type = "wall_mounted"
	elif object_type.contains("door") or object_type.contains("gate"):
		grounding_type = "door_insert"
	elif object_type.contains("key") or object_type.contains("kit") or object_type.contains("card") or object_type.contains("code"):
		grounding_type = "floor_pickup"
	elif object_type.contains("cable"):
		grounding_type = "cable_like"
	var diamond: PackedVector2Array = get_iso_inset_diamond_points(anchor_cell, 20.0)
	var footprint: PackedVector2Array = PackedVector2Array()
	for point in diamond:
		footprint.append(center + (point - grid_to_iso(anchor_cell)) * 0.35 + Vector2(0.0, -3.0))
	var shadow: PackedVector2Array = PackedVector2Array()
	for point in footprint:
		shadow.append(point + Vector2(0.0, 3.0))
	var shape_scale: float = 1.0
	if grounding_type == "floor_pickup":
		shape_scale = 0.65
	return {
		"object_id": object_id, "object_type": object_type, "placement_mode": placement_mode, "grounding_type": grounding_type,
		"anchor_cell": anchor_cell, "attached_wall_cell": attached_wall_cell, "wall_side": wall_side,
		"visual_center": center, "footprint_polygon": footprint, "shadow_polygon": shadow,
		"base_color": Color(0.28, 0.31, 0.37, 0.55), "edge_color": Color(0.13, 0.15, 0.19, 0.72), "accent_color": Color(0.56, 0.81, 0.93, 0.95),
		"height_px": 18, "scale": shape_scale, "badge_enabled": true
	}


func _draw_grounding_overlay(profile: Dictionary) -> void:
	_draw_overlay_commands(RuntimeDebugOverlayRendererRef.build_grounding_commands(profile))

func _get_door_axis_vectors(orientation: String) -> Dictionary:
	if orientation == "axis_y":
		return {"along": Vector2(0.78, 0.39).normalized(), "up": Vector2(0.0, -1.0)}
	return {"along": Vector2(0.78, -0.39).normalized(), "up": Vector2(0.0, -1.0)}

func draw_iso_door_insert(cell: Vector2i, _tile_type: int, object_data: Dictionary = {}) -> void:
	var context: Dictionary = get_door_opening_context(cell)
	if not bool(context.get("ok", false)):
		return
	var profile: Dictionary = get_iso_door_opening_visual_profile(cell, object_data)
	var orientation: String = str(context.get("orientation", "unknown"))
	var door_insert_center: Vector2 = Vector2(context.get("door_insert_center", grid_to_iso(cell)))
	var threshold_polygon: PackedVector2Array = PackedVector2Array(context.get("threshold_polygon", PackedVector2Array()))
	var frame_polygon: PackedVector2Array = PackedVector2Array(context.get("door_frame_polygon", PackedVector2Array()))
	var base_color: Color = Color(profile.get("base_color", Color(0.25, 0.25, 0.28, 0.96)))
	var frame_color: Color = Color(profile.get("frame_color", Color(0.1, 0.12, 0.14, 0.98)))
	var accent_color: Color = Color(profile.get("accent_color", Color(0.8, 0.8, 0.72, 0.98)))
	var warning_color: Color = Color(profile.get("warning_color", Color(1.0, 0.28, 0.2, 0.98)))
	var threshold_color: Color = Color(profile.get("threshold_color", Color(0.14, 0.16, 0.18, 0.82)))
	var alpha: float = float(profile.get("alpha", 0.96))
	base_color.a *= alpha
	accent_color.a *= maxf(alpha, 0.55)
	if bool(profile.get("threshold_enabled", true)):
		if draw_iso_texture_asset(cell, "floor_door_underlay"):
			pass
		elif threshold_polygon.size() >= 3:
			draw_colored_polygon(threshold_polygon, threshold_color)
			for threshold_index in range(threshold_polygon.size()):
				var threshold_next_index: int = (threshold_index + 1) % threshold_polygon.size()
				draw_line(threshold_polygon[threshold_index], threshold_polygon[threshold_next_index], accent_color.darkened(0.25), 1.0)
	if bool(profile.get("frame_enabled", true)) and frame_polygon.size() >= 4:
		draw_colored_polygon(frame_polygon, Color(frame_color.r, frame_color.g, frame_color.b, 0.72))
		for frame_index in range(frame_polygon.size()):
			var frame_next_index: int = (frame_index + 1) % frame_polygon.size()
			draw_line(frame_polygon[frame_index], frame_polygon[frame_next_index], frame_color.lightened(0.18), 2.0)
		var left_jamb_cell: Vector2i = Vector2i(context.get("left_jamb_cell", Vector2i(-1, -1)))
		var right_jamb_cell: Vector2i = Vector2i(context.get("right_jamb_cell", Vector2i(-1, -1)))
		var jamb_cells: Array[Vector2i] = [left_jamb_cell, right_jamb_cell]
		for jamb_cell in jamb_cells:
			if jamb_cell.x < 0 or jamb_cell.y < 0:
				continue
			if not is_cell_in_bounds(jamb_cell):
				continue
			if not is_wall_tile(_grid_manager.get_tile(jamb_cell)):
				continue
			var jamb_center: Vector2 = grid_to_iso(jamb_cell) + Vector2(0.0, -iso_wall_height * 0.4)
			draw_line(jamb_center + Vector2(0.0, -10.0), jamb_center + Vector2(0.0, 13.0), frame_color.lightened(0.24), 3.0)
	var door_kind: String = str(profile.get("door_kind", "mechanical_door"))
	var door_state: String = str(profile.get("door_state", "closed"))
	var door_visual_data: Dictionary = object_data.duplicate(true)
	if not door_visual_data.has("visual_family") and not door_visual_data.has("visual_asset_family"):
		door_visual_data["visual_family"] = "door"
	if not door_visual_data.has("object_type") and not door_visual_data.has("type"):
		door_visual_data["object_type"] = "door"
	var used_texture_asset: bool = draw_iso_object_png_texture_asset(cell, "door", door_insert_center, door_visual_data)
	if not used_texture_asset:
		var axis_data: Dictionary = _get_door_axis_vectors(orientation)
		var along_axis: Vector2 = Vector2(axis_data.get("along", Vector2(1.0, 0.0)))
		var up_axis: Vector2 = Vector2(axis_data.get("up", Vector2(0.0, -1.0)))
		var half_width: float = get_iso_tile_half_size().x * 0.24
		var panel_height: float = iso_wall_height * 0.58
		var panel_bottom: Vector2 = door_insert_center + Vector2(0.0, 12.0)
		var panel_top: Vector2 = panel_bottom + up_axis * panel_height
		var panel_points: PackedVector2Array = PackedVector2Array([
			panel_top - along_axis * half_width,
			panel_top + along_axis * half_width,
			panel_bottom + along_axis * half_width,
			panel_bottom - along_axis * half_width
		])
		if door_state == "open":
			var split_offset: Vector2 = along_axis * half_width * 0.58
			var left_panel: PackedVector2Array = PackedVector2Array([panel_points[0] - split_offset, panel_points[0], panel_points[3], panel_points[3] - split_offset])
			var right_panel: PackedVector2Array = PackedVector2Array([panel_points[1], panel_points[1] + split_offset, panel_points[2] + split_offset, panel_points[2]])
			draw_colored_polygon(left_panel, base_color)
			draw_colored_polygon(right_panel, base_color)
		else:
			draw_colored_polygon(panel_points, base_color)
		if door_kind == "digital_door":
			var strip_start: Vector2 = panel_top + along_axis * half_width * 0.58
			var strip_end: Vector2 = panel_bottom + along_axis * half_width * 0.58
			draw_line(strip_start, strip_end, accent_color, 3.2)
			draw_circle(strip_start.lerp(strip_end, 0.35), 2.8, accent_color.lightened(0.2))
		elif door_kind == "powered_gate":
			for bar_index in range(4):
				var bar_t: float = 0.2 + float(bar_index) * 0.2
				var bar_center: Vector2 = panel_top.lerp(panel_bottom, bar_t)
				draw_line(bar_center - along_axis * half_width * 0.84, bar_center + along_axis * half_width * 0.84, accent_color, 1.8)
				draw_circle(bar_center, 1.6, accent_color.lightened(0.18))
		else:
			draw_line(panel_points[0].lerp(panel_points[3], 0.5), panel_points[1].lerp(panel_points[2], 0.5), accent_color, 1.6)
		if debug_draw_iso_object_outlines:
			for panel_index in range(panel_points.size()):
				var panel_next_index: int = (panel_index + 1) % panel_points.size()
				draw_line(panel_points[panel_index], panel_points[panel_next_index], frame_color.lightened(0.28), 1.0)
	else:
		if door_kind == "digital_door":
			draw_line(door_insert_center + Vector2(10.0, -43.0), door_insert_center + Vector2(10.0, -13.0), accent_color, 2.6)
			draw_circle(door_insert_center + Vector2(10.0, -28.0), 2.4, accent_color.lightened(0.2))
		elif door_kind == "powered_gate":
			for texture_bar_index in range(3):
				var texture_bar_y: float = -38.0 + float(texture_bar_index) * 10.0
				draw_line(door_insert_center + Vector2(-13.0, texture_bar_y), door_insert_center + Vector2(13.0, texture_bar_y), accent_color, 1.8)
		else:
			draw_line(door_insert_center + Vector2(-9.0, -24.0), door_insert_center + Vector2(9.0, -24.0), accent_color, 2.0)
		draw_circle(door_insert_center + Vector2(0.0, -31.0), 2.5, accent_color)
	if bool(profile.get("state_badge_enabled", false)):
		var badge_center: Vector2 = door_insert_center + Vector2(18.0, -22.0)
		var badge_color: Color = accent_color
		if door_state == "locked":
			badge_color = warning_color
		elif door_state == "damaged":
			badge_color = warning_color
		draw_circle(badge_center, 4.2, badge_color)
		if door_state == "locked":
			draw_line(badge_center + Vector2(-2.0, -1.0), badge_center + Vector2(2.0, -1.0), frame_color, 1.2)
		elif door_state == "unpowered":
			draw_line(badge_center + Vector2(-2.8, 2.0), badge_center + Vector2(2.8, -2.0), frame_color, 1.4)
	if bool(profile.get("damage_overlay_enabled", false)):
		draw_line(door_insert_center + Vector2(-12.0, -36.0), door_insert_center + Vector2(-2.0, -23.0), warning_color, 1.8)
		draw_line(door_insert_center + Vector2(-2.0, -23.0), door_insert_center + Vector2(-8.0, -14.0), warning_color, 1.4)
	if show_door_opening_overlay:
		draw_door_opening_overlay_for_context(context)


func draw_door_opening_overlay_for_context(context: Dictionary) -> void:
	var cell: Vector2i = Vector2i(context.get("cell", Vector2i(-1, -1)))
	if cell.x < 0 or cell.y < 0:
		return
	var adjacent_wall_centers: Array[Vector2] = []
	for wall_cell_variant in Array(context.get("adjacent_wall_cells", [])):
		var wall_cell: Vector2i = Vector2i(wall_cell_variant)
		adjacent_wall_centers.append(grid_to_iso(wall_cell) + Vector2(0.0, -iso_wall_height * 0.35))
	_draw_overlay_commands(RuntimeDebugOverlayRendererRef.build_door_opening_commands({
		"threshold_polygon": PackedVector2Array(context.get("threshold_polygon", PackedVector2Array())),
		"insert_center": Vector2(context.get("door_insert_center", grid_to_iso(cell))),
		"adjacent_wall_centers": adjacent_wall_centers,
		"orientation": str(context.get("orientation", "unknown")),
	}))

func draw_iso_object_marker(cell: Vector2i, tile_type: int, override_object_data: Dictionary = {}) -> void:
	var object_meta: Dictionary = _get_iso_world_object_metadata_for_cell(cell)
	if not override_object_data.is_empty():
		object_meta = {"ok": true, "object_id": str(override_object_data.get("id", "")), "object_type": str(override_object_data.get("object_type", override_object_data.get("item_type", ""))), "data": override_object_data}
	var object_data: Dictionary = Dictionary(object_meta.get("data", {}))
	var object_id: String = str(object_meta.get("object_id", ""))
	var is_wall_mounted_object_visual: bool = is_wall_mounted_runtime_object(object_data)
	var is_wall_routed_object_visual: bool = is_wall_procedural_routed_object(object_data)
	var is_wall_visual: bool = is_wall_mounted_object_visual or is_wall_routed_object_visual
	var profile_data: Dictionary = get_iso_object_grounding_profile(object_data, cell)
	var visual_center: Vector2 = Vector2(profile_data.get("visual_center", get_world_object_visual_position(cell)))
	if is_wall_visual:
		visual_center = get_wall_mounted_visual_center(object_data, cell)
	var is_door_floor_object_visual: bool = is_door_like_object_data(object_data) or (is_door_like_tile(tile_type) and not object_data.is_empty())
	if is_door_floor_object_visual and not is_wall_visual:
		var door_visual_data: Dictionary = object_data.duplicate(true)
		if not door_visual_data.has("visual_family") and not door_visual_data.has("visual_asset_family"):
			door_visual_data["visual_family"] = "door"
		if not door_visual_data.has("object_type") and not door_visual_data.has("type"):
			door_visual_data["object_type"] = "door"
		var door_profile_data: Dictionary = get_iso_object_grounding_profile(door_visual_data, cell)
		var door_visual_center: Vector2 = Vector2(door_profile_data.get("visual_center", visual_center))
		var used_door_texture_asset: bool = draw_iso_object_png_texture_asset(cell, "door", door_visual_center, door_visual_data)
		if show_object_grounding_overlay:
			_draw_grounding_overlay(door_profile_data)
		if used_door_texture_asset:
			return
		return
	if not is_wall_visual:
		var shadow_polygon: PackedVector2Array = PackedVector2Array(profile_data.get("shadow_polygon", PackedVector2Array()))
		if shadow_polygon.size() >= 3:
			draw_colored_polygon(shadow_polygon, Color(0.03, 0.05, 0.08, 0.26))
		var footprint_polygon: PackedVector2Array = PackedVector2Array(profile_data.get("footprint_polygon", PackedVector2Array()))
		if footprint_polygon.size() >= 3:
			draw_colored_polygon(footprint_polygon, Color(0.2, 0.24, 0.28, 0.2))
	if PlatformTypesRef.is_platform_data(object_data):
		return
	var profile_key: String = get_iso_object_profile_key_for_tile(tile_type)
	if not override_object_data.is_empty() or profile_key.is_empty():
		profile_key = get_iso_object_profile_key_for_object_data(object_data, profile_key)
	var object_asset_key: String = get_iso_object_asset_key_for_object_data(object_data, profile_key)
	var mission_manager: Node = get_mission_manager_ref()
	var has_door_visual: bool = false
	var door_visual: Dictionary = {}
	var has_terminal_visual: bool = false
	var terminal_visual: Dictionary = {}
	if not object_id.is_empty() and mission_manager != null:
		if mission_manager.has_method("get_map_constructor_door_visual_state"):
			door_visual = Dictionary(mission_manager.call("get_map_constructor_door_visual_state", object_id))
			has_door_visual = bool(door_visual.get("ok", false))
		if mission_manager.has_method("get_map_constructor_terminal_visual_state"):
			terminal_visual = Dictionary(mission_manager.call("get_map_constructor_terminal_visual_state", object_id))
			has_terminal_visual = bool(terminal_visual.get("ok", false))
	var wall_mounted_profile_key: String = get_wall_mounted_object_profile_key(cell)
	if is_wall_mounted_object_visual and wall_mounted_profile_key.is_empty():
		wall_mounted_profile_key = profile_key
	if not wall_mounted_profile_key.is_empty():
		profile_key = wall_mounted_profile_key
		object_asset_key = get_iso_object_asset_key_for_object_data(object_data, profile_key)
	log_iso_object_asset_resolution(object_data, profile_key, object_asset_key)
	var profile: Dictionary = get_iso_object_profile(profile_key)
	if CableTopologyServiceRef.is_circuit_switch_object(object_data):
		var switch_topology: Dictionary = CableTopologyServiceRef.classify_cell(cell, _get_runtime_world_objects_for_iso_render(true), object_data)
		if int(switch_topology.get("neighbor_count", 0)) > 0:
			draw_iso_cable_topology_line(cell, get_iso_object_profile("cable"), object_data, visual_center)
	if has_door_visual:
		profile["base"] = _blend_color(_get_color_from_dict(profile, "base", Color.WHITE), Color(door_visual.get("tint", Color.WHITE)), 0.45)
		profile["accent"] = Color(door_visual.get("accent", _get_color_from_dict(profile, "accent", Color.WHITE)))
	if has_terminal_visual:
		profile["base"] = _blend_color(_get_color_from_dict(profile, "base", Color.WHITE), Color(terminal_visual.get("tint", Color.WHITE)), 0.45)
		profile["accent"] = Color(terminal_visual.get("accent", _get_color_from_dict(profile, "accent", Color.WHITE)))
	var active_switcher_color_id: String = str(object_data.get("line_color_id", "")).strip_edges()
	if active_switcher_color_id.is_empty() and str(object_data.get("object_type", "")).strip_edges().to_lower() == "power_switcher":
		var active_line_id: String = str(object_data.get("active_line_id", "")).strip_edges()
		for line_variant in Array(object_data.get("switcher_lines", [])):
			if line_variant is Dictionary and str(Dictionary(line_variant).get("line_id", "")) == active_line_id:
				active_switcher_color_id = str(Dictionary(line_variant).get("color_id", ""))
	if not active_switcher_color_id.is_empty():
		profile["accent"] = _get_line_color_from_id(active_switcher_color_id, _get_color_from_dict(profile, "accent", Color(0.72, 0.78, 0.86, 0.95)))
	var overlay_accent: Color = _get_color_from_dict(profile, "accent", Color(0.72, 0.78, 0.86, 0.95))
	if draw_wall_routed_procedural_visual(object_data, profile, cell):
		return
	draw_wall_mounted_cable_tap(object_data, visual_center, get_iso_object_profile("cable"), has_terminal_visual)
	# Topology-aware cable cells are rendered procedurally below so placed and preview
	# cables share one continuous visual language instead of falling back to the old
	# per-cell cable icon/marker texture.
	var used_texture_asset: bool = false
	var is_case_visual: bool = VisualStateAssetServiceRef.is_loot_case_object(object_data)
	if is_case_visual:
		used_texture_asset = draw_iso_object_png_texture_asset(cell, VisualStateAssetServiceRef.resolve_visual_asset_id(object_data), visual_center, object_data)
	elif profile_key != "cable":
		if is_iso_object_png_asset_key(object_asset_key):
			used_texture_asset = draw_iso_object_png_texture_asset(cell, object_asset_key, visual_center, object_data)
		else:
			used_texture_asset = draw_optional_visual_texture_asset(object_asset_key, cell, "draw_iso_object_marker", {"visual_center": visual_center})
			if not used_texture_asset:
				used_texture_asset = draw_iso_texture_asset(cell, object_asset_key, visual_center)
	if not used_texture_asset and has_door_visual:
		used_texture_asset = draw_optional_visual_texture_asset(str(door_visual.get("texture_asset_id", "")), cell, "draw_iso_object_marker", {"visual_center": visual_center})
	if not used_texture_asset and has_terminal_visual:
		used_texture_asset = draw_optional_visual_texture_asset(str(terminal_visual.get("texture_asset_id", "")), cell, "draw_iso_object_marker", {"visual_center": visual_center})
	if used_texture_asset:
		if is_case_visual:
			return
		draw_circle(visual_center + Vector2(0.0, -iso_object_marker_height - 8.0), 2.4, overlay_accent)
		draw_line(
			visual_center + Vector2(-4.0, -iso_object_marker_height - 3.0),
			visual_center + Vector2(4.0, -iso_object_marker_height - 3.0),
			overlay_accent,
			1.5
		)
		return
	if draw_wall_mounted_object_shape(cell, profile_key, profile, visual_center):
		return
	var shape: String = str(profile.get("shape", "small_marker"))
	var door_profile_key: String = get_iso_door_visual_profile_key_for_tile(tile_type)
	if not door_profile_key.is_empty():
		if door_profile_key == "door_mechanical":
			profile["base"] = Color(0.3, 0.21, 0.13, 0.96)
			profile["accent"] = Color(0.96, 0.7, 0.28, 0.98)
			profile["outline"] = Color(0.2, 0.13, 0.08, 0.94)
		elif door_profile_key == "door_digital":
			profile["base"] = Color(0.13, 0.22, 0.31, 0.96)
			profile["accent"] = Color(0.38, 0.83, 0.97, 0.99)
			profile["outline"] = Color(0.08, 0.16, 0.22, 0.94)
		elif door_profile_key == "door_powered_gate":
			profile["base"] = Color(0.12, 0.18, 0.26, 0.96)
			profile["accent"] = Color(0.5, 0.9, 1.0, 0.99)
			profile["outline"] = Color(0.07, 0.14, 0.2, 0.94)
	if shape == "slab":
		draw_iso_object_slab(cell, profile, visual_center)
	elif shape == "door_panel":
		draw_iso_object_door_panel(cell, profile, visual_center)
	elif shape == "pillar":
		draw_iso_object_pillar(cell, profile, visual_center)
	elif shape == "terminal_console":
		draw_iso_object_terminal_console(cell, profile, visual_center)
	elif shape == "line":
		if profile_key == "cable":
			draw_iso_cable_topology_line(cell, profile, object_data, visual_center)
		else:
			draw_iso_object_line(cell, profile, visual_center)
	elif shape == "heat_marker":
		draw_iso_object_heat_marker(cell, profile, visual_center)
	else:
		draw_iso_object_small_marker(cell, profile, visual_center)
	if show_object_grounding_overlay:
		_draw_grounding_overlay(profile_data)

func build_iso_floor_draw_entries() -> Array[Dictionary]:
	return FloorRendererRef.build_draw_entries(
		_grid_manager,
		Callable(self, "get_ground_asset_key_for_cell"),
		iso_origin,
		get_iso_tile_half_size()
	)

func build_iso_wall_draw_entries() -> Array[Dictionary]:
	return WallRendererRef.build_draw_entries(_grid_manager, iso_origin, get_iso_tile_half_size(), iso_wall_visual_inset)

func build_iso_platform_surface_draw_entries() -> Array[Dictionary]:
	if _grid_manager == null:
		return []
	var map_width: int = _grid_manager.get_map_width()
	var map_height: int = _grid_manager.get_map_height()
	if map_width <= 0 or map_height <= 0:
		return []

	var platform_entries: Array[Dictionary] = []
	for y in range(map_height):
		for x in range(map_width):
			var cell: Vector2i = Vector2i(x, y)
			var platform_data: Dictionary = _get_platform_data_for_cell(cell)
			if platform_data.is_empty():
				continue
			platform_entries.append(IsoDrawEntryContractRef.make_entry(
				cell,
				"platform_surface",
				"platform_surface",
				get_iso_floor_depth_key(cell),
				ISO_DRAW_SUB_ORDER_PLATFORM_SURFACE,
				{"platform_data": platform_data}
			))
	return platform_entries

func _get_runtime_items_for_cell(cell: Vector2i) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var mission_manager: Node = get_mission_manager_ref()
	if mission_manager == null or not mission_manager.has_method("get_items_at_cell"):
		return result
	var items_variant: Variant = mission_manager.call("get_items_at_cell", cell)
	if not (items_variant is Array):
		return result
	for item_variant in Array(items_variant):
		if item_variant is Dictionary:
			result.append(Dictionary(item_variant))
	return result

func _is_hidden_cable_visual(object_data: Dictionary) -> bool:
	var object_type: String = str(object_data.get("object_type", "")).to_lower()
	if not object_type.contains("cable") and not object_type.contains("wire"):
		return false
	return get_cable_install_mode(object_data) == "hidden"

func _get_runtime_world_objects_for_iso_render(include_hidden_cables: bool = true) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var mission_manager: Node = get_mission_manager_ref()
	if mission_manager == null:
		return result
	for object_variant in Array(mission_manager.get("mission_world_objects")):
		if not (object_variant is Dictionary):
			continue
		var object_data: Dictionary = Dictionary(object_variant)
		if not include_hidden_cables and _is_hidden_cable_visual(object_data):
			continue
		result.append(object_data)
		if str(object_data.get("object_type", "")).to_lower().contains("cable"):
			for path_cell_variant in Array(object_data.get("cable_path_cells", [])):
				var path_cell: Vector2i = _try_parse_cell_variant(path_cell_variant)
				if path_cell.x < 0 or path_cell.y < 0 or path_cell == _try_parse_cell_variant(object_data.get("position", Vector2i(-1, -1))):
					continue
				var path_segment: Dictionary = object_data.duplicate(true)
				path_segment["position"] = path_cell
				result.append(path_segment)
	return result

func get_iso_object_sub_order(layer_name: String, profile_key: String) -> float:
	return ObjectRendererRef.get_sub_order(layer_name, profile_key)

func get_wall_mounted_render_layer(object_data: Dictionary) -> int:
	return ObjectRendererRef.get_wall_mounted_render_layer(object_data, is_wall_routing_utility_object(object_data))

func make_iso_object_draw_entry(cell: Vector2i, layer_name: String, _layer_bias: float, object_index: float, payload: Dictionary) -> Dictionary:
	return ObjectRendererRef.make_draw_entry(
		cell,
		layer_name,
		object_index,
		payload,
		get_iso_object_depth_key_for_payload(payload),
		is_wall_routing_utility_object(Dictionary(payload.get("object_data", {})))
	)

func build_iso_object_draw_entries() -> Array[Dictionary]:
	# Runtime objects are rendered from their real dictionaries so visuals and
	# interaction lookup stay aligned even when an object occupies a floor tile.
	if _grid_manager == null:
		return []
	var map_width: int = _grid_manager.get_map_width()
	var map_height: int = _grid_manager.get_map_height()
	if map_width <= 0 or map_height <= 0:
		return []
	var runtime_objects_by_cell: Dictionary = {}
	for object_data in _get_runtime_world_objects_for_iso_render(is_map_constructor_editor_render()):
		var object_cell: Vector2i = _try_parse_cell_variant(object_data.get("position", Vector2i(-1, -1)))
		if is_wall_mounted_runtime_object(object_data) or is_wall_procedural_routed_object(object_data):
			object_cell = _try_parse_cell_variant(object_data.get("attached_wall_cell", object_cell), object_cell)
		if object_cell.x < 0 or object_cell.y < 0:
			continue
		var cell_objects: Array = Array(runtime_objects_by_cell.get(object_cell, []))
		cell_objects.append(object_data)
		runtime_objects_by_cell[object_cell] = cell_objects
	var draw_entries: Array[Dictionary] = []
	for y in range(map_height):
		for x in range(map_width):
			var cell: Vector2i = Vector2i(x, y)
			var tile_type: int = _grid_manager.get_tile(cell)
			var runtime_items: Array[Dictionary] = _get_runtime_items_for_cell(cell)
			for item_index in range(runtime_items.size()):
				var item_data: Dictionary = runtime_items[item_index]
				var item_payload: Dictionary = {"object_cell":cell, "tile_type":tile_type, "profile_key":get_iso_object_profile_key_for_object_data(item_data, "key"), "object_data":item_data}
				draw_entries.append(make_iso_object_draw_entry(cell, "item", ISO_LAYER_BIAS_ITEM, float(item_index), item_payload))
			var runtime_objects: Array = Array(runtime_objects_by_cell.get(cell, []))
			var has_runtime_door_object_on_door_tile: bool = false
			for object_index in range(runtime_objects.size()):
				var object_data: Dictionary = Dictionary(runtime_objects[object_index])
				if PlatformTypesRef.is_platform_data(object_data):
					continue
				object_data = _with_platform_visual_surface_context(object_data, cell)
				var object_profile_key: String = get_iso_object_profile_key_for_object_data(object_data, "generic_object")
				var layer_name: String = "wall_mounted" if is_wall_mounted_runtime_object(object_data) or is_wall_procedural_routed_object(object_data) else ("cable" if CableTopologyServiceRef.is_cable_object(object_data) else ("terminal" if is_terminal_like_profile(object_profile_key) else "item"))
				var layer_bias: float = ISO_LAYER_BIAS_WALL_MOUNTED if layer_name == "wall_mounted" else (ISO_LAYER_BIAS_CABLE if layer_name == "cable" else (ISO_LAYER_BIAS_TERMINAL if layer_name == "terminal" else ISO_LAYER_BIAS_ITEM))
				var object_payload: Dictionary = {"object_cell":cell, "tile_type":tile_type, "profile_key":object_profile_key, "object_data":object_data}
				draw_entries.append(make_iso_object_draw_entry(cell, layer_name, layer_bias, float(object_index), object_payload))
				if is_door_like_tile(tile_type) and is_door_like_object_data(object_data):
					has_runtime_door_object_on_door_tile = true
			if not runtime_objects.is_empty():
				if not has_runtime_door_object_on_door_tile and is_iso_object_tile(tile_type):
					var tile_profile_key: String = get_iso_object_profile_key_for_tile(tile_type)
					var tile_payload: Dictionary = {"object_cell":cell, "tile_type":tile_type, "profile_key":tile_profile_key}
					draw_entries.append(make_iso_object_draw_entry(cell, "item", ISO_LAYER_BIAS_ITEM, 0.0, tile_payload))
				continue
			if not is_iso_object_tile(tile_type):
				continue
			var profile_key: String = get_iso_object_profile_key_for_tile(tile_type)
			var fallback_payload: Dictionary = {"object_cell":cell, "tile_type":tile_type, "profile_key":profile_key}
			draw_entries.append(make_iso_object_draw_entry(cell, "item", ISO_LAYER_BIAS_ITEM, 0.0, fallback_payload))
	return draw_entries

func build_iso_cable_object_bridge_draw_entries() -> Array[Dictionary]:
	var world_objects: Array[Dictionary] = _get_runtime_world_objects_for_iso_render(true)
	var cable_cells: Dictionary = CableTopologyServiceRef.build_cable_cell_map(world_objects)
	if cable_cells.is_empty():
		return []
	var draw_entries: Array[Dictionary] = []
	var emitted_pairs: Dictionary = {}
	var cardinal_deltas: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for object_data in world_objects:
		if not is_power_cable_bridge_connectable_object(object_data):
			continue
		var object_cell: Vector2i = CableTopologyServiceRef.get_object_link_cell(object_data)
		if object_cell.x < 0 or object_cell.y < 0:
			continue
		if cable_cells.has(object_cell):
			continue
		for delta in cardinal_deltas:
			var cable_cell: Vector2i = object_cell + delta
			if not cable_cells.has(cable_cell):
				continue
			var cable_data: Dictionary = Dictionary(cable_cells.get(cable_cell, {}))
			if not should_draw_object_cable_bridge(object_data, object_cell, cable_data, cable_cell):
				continue
			var pair_key: String = "%s:%s" % [str(object_data.get("id", object_data.get("object_id", object_cell))), str(cable_cell)]
			if emitted_pairs.has(pair_key):
				continue
			emitted_pairs[pair_key] = true
			var payload: Dictionary = {"object_data": object_data, "object_cell": object_cell, "cable_data": cable_data, "cable_cell": cable_cell}
			draw_entries.append(IsoDrawEntryContractRef.make_entry(
				cable_cell,
				"cable",
				"cable_bridge",
				minf(get_iso_floor_depth_key(object_cell), get_iso_floor_depth_key(cable_cell)),
				-0.5,
				payload,
				ISO_LAYER_BIAS_CABLE - 0.02
			))
	return draw_entries

func build_iso_geometry_draw_entries(include_walls: bool, include_objects: bool, include_floors: bool = false) -> Array[Dictionary]:
	var draw_entries: Array[Dictionary] = []
	if include_floors:
		draw_entries.append_array(build_iso_floor_draw_entries())
		draw_entries.append_array(build_iso_platform_surface_draw_entries())
	if include_walls:
		draw_entries.append_array(build_iso_wall_draw_entries())
	if include_objects:
		draw_entries.append_array(build_iso_cable_object_bridge_draw_entries())
		draw_entries.append_array(build_iso_object_draw_entries())
	draw_entries.sort_custom(sort_iso_draw_entries)
	return draw_entries

func draw_iso_draw_entry(entry: Dictionary) -> void:
	var kind: String = str(entry.get("kind", ""))
	if kind == "floor" or kind == "ground":
		var floor_cell: Vector2i = Vector2i(entry.get("cell", Vector2i(-1, -1)))
		if floor_cell.x < 0 or floor_cell.y < 0:
			return
		var floor_payload: Dictionary = Dictionary(entry.get("payload", {}))
		var floor_tile_type: int = int(floor_payload.get("tile_type", _grid_manager.get_tile(floor_cell)))
		draw_iso_floor_cell(floor_cell, floor_tile_type)
		return
	if kind == "platform_surface":
		var platform_cell: Vector2i = Vector2i(entry.get("cell", Vector2i(-1, -1)))
		if platform_cell.x < 0 or platform_cell.y < 0:
			return
		var platform_payload: Dictionary = Dictionary(entry.get("payload", {}))
		var ground_asset_key: String = get_ground_asset_key_for_cell(platform_cell)
		var surface_y_offset: float = get_ground_surface_y_offset_for_asset_key(ground_asset_key)
		draw_platform_floor_visual_for_cell(platform_cell, Dictionary(platform_payload.get("platform_data", {})), surface_y_offset)
		return
	if kind == "wall" or kind == "wall_body" or kind == "wall_top":
		var cell: Vector2i = Vector2i(entry.get("cell", Vector2i(-1, -1)))
		if cell.x < 0 or cell.y < 0:
			return
		# Wall textures and procedural walls are still emitted by one cell-local
		# callback so asset alignment, breach overlays, caps, and tops stay intact;
		# the command itself is sorted by wall foot/base Y with wall-body sub-order.
		draw_iso_wall_block(cell)
		return
	if kind == "cable_bridge":
		var bridge_payload: Dictionary = Dictionary(entry.get("payload", {}))
		var object_cell_for_bridge: Vector2i = Vector2i(bridge_payload.get("object_cell", Vector2i(-1, -1)))
		var cable_cell_for_bridge: Vector2i = Vector2i(bridge_payload.get("cable_cell", Vector2i(-1, -1)))
		if object_cell_for_bridge.x < 0 or object_cell_for_bridge.y < 0 or cable_cell_for_bridge.x < 0 or cable_cell_for_bridge.y < 0:
			return
		var bridge_profile: Dictionary = get_iso_object_profile("cable")
		bridge_profile["install_mode"] = "floor"
		draw_object_cable_bridge(Dictionary(bridge_payload.get("object_data", {})), object_cell_for_bridge, Dictionary(bridge_payload.get("cable_data", {})), cable_cell_for_bridge, bridge_profile)
		return
	if kind == "object" or kind == "door" or kind == "wall_mounted" or kind == "cable":
		var payload: Dictionary = Dictionary(entry.get("payload", {}))
		var object_cell: Vector2i = Vector2i(payload.get("object_cell", Vector2i(-1, -1)))
		if object_cell.x < 0 or object_cell.y < 0:
			return
		var tile_type: int = int(payload.get("tile_type", _grid_manager.get_tile(object_cell)))
		draw_iso_object_marker(object_cell, tile_type, Dictionary(payload.get("object_data", {})))

func draw_iso_geometry_prototype(include_walls: bool, include_objects: bool, include_floors: bool = false) -> void:
	if _grid_manager == null:
		return

	var draw_entries: Array[Dictionary] = build_iso_geometry_draw_entries(include_walls, include_objects, include_floors)
	for entry in draw_entries:
		draw_iso_draw_entry(entry)


func get_iso_fog_color_for_cell(cell: Vector2i) -> Color:
	# Visual-only fog overlay color sampling.
	# GridManager remains the source of truth for visibility/exploration state.
	# This pass reads fog state and never mutates it.
	if _grid_manager == null:
		return Color.TRANSPARENT

	return FogRendererRef.get_fog_color({
		"visible": _grid_manager.is_cell_visible(cell),
		"explored": _grid_manager.is_explored(cell),
		"visible_alpha": iso_fog_visible_alpha,
		"explored_alpha": iso_fog_explored_alpha,
		"unexplored_alpha": iso_fog_unexplored_alpha,
	})

func should_draw_iso_fog_for_cell(cell: Vector2i) -> bool:
	if _grid_manager == null:
		return false
	var fog_color: Color = get_iso_fog_color_for_cell(cell)
	return fog_color.a > 0.0

func draw_iso_fog_cell_overlay(cell: Vector2i) -> void:
	var fog_color: Color = get_iso_fog_color_for_cell(cell)
	if fog_color.a <= 0.0:
		return

	var diamond_points: PackedVector2Array = get_iso_inset_diamond_points(cell, iso_floor_visual_inset)
	if diamond_points.size() < 4:
		return
	_draw_overlay_commands(FogRendererRef.build_cell_overlay_commands({
		"diamond_points": diamond_points,
		"fog_color": fog_color,
		"draw_outlines": debug_draw_iso_fog_outlines,
	}))

func draw_iso_fog_wall_overlay(cell: Vector2i) -> void:
	var fog_color: Color = get_iso_fog_color_for_cell(cell)
	if fog_color.a <= 0.0:
		return

	var base_points: PackedVector2Array = get_iso_wall_base_points(cell)
	if base_points.size() < 4:
		return
	var top_points: PackedVector2Array = get_iso_wall_top_points(cell)
	if top_points.size() < 4:
		return

	var top_face: PackedVector2Array = PackedVector2Array([top_points[0], top_points[1], top_points[2], top_points[3]])
	var left_face: PackedVector2Array = PackedVector2Array([top_points[3], top_points[2], base_points[2], base_points[3]])
	var right_face: PackedVector2Array = PackedVector2Array([top_points[2], top_points[1], base_points[1], base_points[2]])

	_draw_overlay_commands(FogRendererRef.build_wall_overlay_commands({
		"left_face": left_face,
		"right_face": right_face,
		"top_face": top_face,
		"fog_color": fog_color,
		"draw_outlines": debug_draw_iso_fog_outlines,
	}))


func draw_world_overlay_markers() -> void:
	if _grid_manager == null or not _grid_manager.has_method("get_world_overlay_markers"):
		return
	var markers: Dictionary = Dictionary(_grid_manager.call("get_world_overlay_markers"))
	var rows: Array[Dictionary] = []
	for cell_variant in markers.keys():
		var cell: Vector2i = Vector2i(cell_variant)
		if _grid_manager.has_method("is_cell_visible") and not _grid_manager.is_cell_visible(cell):
			continue
		var marker: String = str(markers.get(cell_variant, ""))
		if marker.is_empty():
			continue
		rows.append({"center": grid_to_iso(cell) + Vector2(0.0, -10.0), "text": marker})
	_draw_overlay_commands(RuntimeDebugOverlayRendererRef.build_world_marker_commands(rows))

func get_projected_grid_direction(cell: Vector2i, grid_direction: Vector2i) -> Vector2:
	var direction: Vector2 = grid_to_iso(cell + grid_direction) - grid_to_iso(cell)
	if direction.length_squared() <= 0.0:
		direction = grid_to_iso(cell + Vector2i.RIGHT) - grid_to_iso(cell)
	if direction.length_squared() <= 0.0:
		return Vector2.RIGHT
	return direction.normalized()


func draw_fan_platform_marker() -> void:
	if _grid_manager == null or not _grid_manager.has_method("get_fan_platform_marker"):
		return
	var marker: Dictionary = Dictionary(_grid_manager.call("get_fan_platform_marker"))
	if not bool(marker.get("active", false)):
		return
	var cell: Vector2i = Vector2i(marker.get("position", Vector2i(-1, -1)))
	var direction_i: Vector2i = Vector2i(marker.get("direction", Vector2i.RIGHT))
	_draw_overlay_commands(RuntimeDebugOverlayRendererRef.build_fan_marker_commands({
		"center": grid_to_iso(cell) + Vector2(0.0, -8.0),
		"direction": get_projected_grid_direction(cell, direction_i),
	}))

func draw_iso_fog_overlay() -> void:
	# Visual-only fog overlay pass for isometric prototypes.
	# GridManager visibility helpers are read here; gameplay fog logic is not modified.
	if not iso_fog_draw_cell_shapes:
		return
	if _grid_manager == null:
		return

	var map_width: int = _grid_manager.get_map_width()
	var map_height: int = _grid_manager.get_map_height()
	if map_width <= 0 or map_height <= 0:
		return

	var fog_cells: Array[Vector2i] = []
	for y in range(map_height):
		for x in range(map_width):
			var cell: Vector2i = Vector2i(x, y)
			if should_draw_iso_fog_for_cell(cell):
				fog_cells.append(cell)

	fog_cells.sort_custom(sort_cells_by_iso_depth)
	for cell in fog_cells:
		var tile_type: int = _grid_manager.get_tile(cell)
		if tile_type == GridManager.TILE_WALL and should_render_iso_wall_visuals():
			draw_iso_fog_wall_overlay(cell)
		draw_iso_fog_cell_overlay(cell)


func draw_wall_mount_zones_overlay() -> void:
	if _grid_manager == null:
		return
	var rows: Array[Dictionary] = []
	for y in range(_grid_manager.get_map_height()):
		for x in range(_grid_manager.get_map_width()):
			var wall_cell: Vector2i = Vector2i(x, y)
			if _grid_manager.get_tile(wall_cell) != GridManager.TILE_WALL:
				continue
			for zone_variant in get_wall_mounted_anchor_zones(wall_cell):
				var zone: Dictionary = Dictionary(zone_variant)
				if not bool(zone.get("mountable", false)):
					continue
				rows.append({
					"center": Vector2(zone.get("mount_zone_center", grid_to_iso(wall_cell))),
					"side": str(zone.get("wall_side", "")),
				})
	_draw_overlay_commands(RuntimeDebugOverlayRendererRef.build_wall_mount_zone_commands(rows))


func draw_wall_run_overlay() -> void:
	if _grid_manager == null:
		return
	var rows: Array[Dictionary] = []
	for y in range(_grid_manager.get_map_height()):
		for x in range(_grid_manager.get_map_width()):
			var cell: Vector2i = Vector2i(x, y)
			if _grid_manager.get_tile(cell) != GridManager.TILE_WALL:
				continue
			var topology: Dictionary = get_wall_render_topology(cell)
			var edges: Array[Dictionary] = []
			var neighbors: Dictionary = Dictionary(topology.get("neighbors", {}))
			for side in WALL_SIDE_ORDER:
				var edge_points: Array[Vector2] = get_iso_diamond_edge_points(get_iso_wall_connected_base_points(cell, topology), side)
				if edge_points.size() < 2:
					continue
				edges.append({"start": edge_points[0], "end": edge_points[1], "connected": bool(neighbors.get(side, false))})
			rows.append({
				"shape": str(topology.get("shape", "unknown")),
				"run_x": bool(topology.get("run_x", false)),
				"run_y": bool(topology.get("run_y", false)),
				"has_cap": not Array(topology.get("cap_sides", [])).is_empty(),
				"label_position": grid_to_iso(cell) + Vector2(-28.0, -iso_wall_height - 10.0),
				"edges": edges,
			})
	_draw_overlay_commands(RuntimeDebugOverlayRendererRef.build_wall_run_commands(rows))


func draw_floor_join_overlay() -> void:
	if _grid_manager == null:
		return
	var rows: Array[Dictionary] = []
	for y in range(_grid_manager.get_map_height()):
		for x in range(_grid_manager.get_map_width()):
			var cell: Vector2i = Vector2i(x, y)
			var tile_type: int = _grid_manager.get_tile(cell)
			if not is_floor_like_tile(tile_type):
				continue
			var points: PackedVector2Array = get_iso_diamond_points(cell)
			for side in WALL_SIDE_ORDER:
				var edge_points: Array[Vector2] = get_iso_diamond_edge_points(points, side)
				if edge_points.size() < 2:
					continue
				rows.append({
					"start": edge_points[0],
					"end": edge_points[1],
					"shown": should_draw_floor_edge_border(cell, side),
				})
	_draw_overlay_commands(RuntimeDebugOverlayRendererRef.build_floor_join_commands(rows))

func draw_cable_reel_drag_trail() -> void:
	var mission_manager: Node = get_mission_manager_ref()
	if mission_manager == null:
		return
	var active_bipob: Node = mission_manager.get("active_bipob_ref")
	if active_bipob == null or not is_instance_valid(active_bipob) or not active_bipob.has_method("_get_held_cable_end_metadata"):
		return
	var held: Dictionary = Dictionary(active_bipob.call("_get_held_cable_end_metadata"))
	if not bool(held.get("held", false)):
		return
	if not mission_manager.has_method("get_world_object_by_id"):
		return
	var reel_id: String = str(held.get("reel_id", "")).strip_edges()
	var end_index: int = int(held.get("end_index", 0))
	if reel_id.is_empty() or end_index < 1 or end_index > 2:
		return
	var reel: Dictionary = Dictionary(mission_manager.call("get_world_object_by_id", reel_id))
	if reel.is_empty() or str(reel.get("end_%d_state" % end_index, "")).strip_edges().to_lower() != "dragging":
		return
	var points: PackedVector2Array = PackedVector2Array()
	for cell_variant in Array(reel.get("end_%d_path_cells" % end_index, [])):
		var cell: Vector2i = _try_parse_cell_variant(cell_variant)
		if cell.x < 0 or cell.y < 0:
			continue
		points.append(grid_to_iso(cell) + _get_cable_reel_trail_lane_offset(cell))
	if active_bipob.has_method("get_grid_position"):
		var actor_cell: Vector2i = active_bipob.call("get_grid_position")
		var actor_point: Vector2 = grid_to_iso(actor_cell) + _get_cable_reel_trail_lane_offset(actor_cell)
		if points.is_empty() or points[points.size() - 1].distance_to(actor_point) > 0.5:
			points.append(actor_point)
	if points.size() < 2:
		return
	var shadow_color: Color = Color(0.02, 0.03, 0.04, 0.64)
	var trail_color: Color = Color(1.0, 0.62, 0.16, 0.96)
	draw_polyline(points, shadow_color, 6.5, true)
	draw_polyline(points, trail_color, 3.4, true)
	for point in points:
		draw_circle(point, 2.6, trail_color)
	draw_circle(points[points.size() - 1], 4.0, Color(1.0, 0.88, 0.36, 0.98))


func _get_cable_reel_trail_lane_offset(_cell: Vector2i) -> Vector2:
	# Dedicated transient reel-drag lane: offset below/right of the normal power-cable centerline.
	return Vector2(0.0, iso_tile_height * 0.11)

func _process(delta: float) -> void:
	if not selected_interaction_target.is_empty():
		selected_interaction_overlay_time += delta
		queue_redraw()
	if _iso_light_overlay_animation_requested:
		queue_redraw()


func _draw() -> void:
	_iso_light_overlay_animation_requested = false
	_draw_overlay_commands(RuntimeDebugOverlayRendererRef.build_origin_commands(debug_draw_marker))

	# Isometric render pass order:
	# 1) unified floor/ground/walls/objects queue (screen-Y depth sorted)
	# 2) constructor/selection overlays intentionally outside depth queue
	# 3) fog/final overlay
	var include_floors: bool = should_render_iso_floor_visuals()
	var include_walls: bool = should_render_iso_wall_visuals()
	var include_objects: bool = should_render_iso_object_visuals()
	if include_floors or include_walls or include_objects:
		draw_iso_geometry_prototype(include_walls, include_objects, include_floors)
	if show_wall_mount_zones_overlay and include_walls:
		draw_wall_mount_zones_overlay()
	if show_wall_run_overlay and include_walls:
		draw_wall_run_overlay()
	if show_floor_join_overlay and should_render_iso_floor_visuals():
		draw_floor_join_overlay()

	draw_cable_reel_drag_trail()
	draw_iso_mouse_selection_overlay()
	draw_map_constructor_visual_overlay_passes()
	draw_selected_interaction_target_overlay()
	draw_world_overlay_markers()
	draw_fan_platform_marker()

	if should_render_iso_fog_visuals():
		draw_iso_fog_overlay()

	if debug_draw_iso_helper_preview:
		_draw_overlay_commands(RuntimeDebugOverlayRendererRef.build_helper_preview_commands(get_iso_diamond_points(Vector2i.ZERO)))

