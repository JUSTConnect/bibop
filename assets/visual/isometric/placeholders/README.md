# BIPOB isometric placeholder asset pack

These SVGs are **placeholder production hooks**, not final production art. They provide readable, cartoon-like sci-fi industrial stand-ins for the current 1.81:1 isometric visual pipeline while keeping gameplay data in code/resources only.

## Naming convention

Files use `iso_<category>_<variant>.svg`, and renderer/catalog keys use `<category>_<variant>`.

- Floor key `floor_default` maps to `iso_floor_default.svg`.
- Wall key `wall_steel` maps to `iso_wall_steel.svg`.
- Object key `object_terminal` maps to `iso_object_terminal.svg`.

## Intended sizes and viewBoxes

- **Floors:** designed to sit inside the runtime 128×71 diamond. Use `viewBox="0 0 128 71"` and keep the main tile diamond near `M64 4 L124 35.5 L64 67 L4 35.5 Z`.
- **Walls:** designed for a taller isometric wall mass. Use about `viewBox="0 0 128 120"`, with the footprint centered around the lower half and transparent background above/around it.
- **Objects:** designed as compact props/pickups. Use about `viewBox="0 0 96 96"` or `0 0 128 128` for larger props, with transparent background and a bottom-centered visual footprint.

All assets should stay SVG-only unless the final art pipeline intentionally replaces a hook with PNG. Do not embed raster images, link external resources, or store gameplay logic in art assets.


## Pivot and alignment convention

The renderer treats each asset key as having visual-only alignment metadata in `RoomVisualRenderer.ISO_ASSET_ALIGNMENT_RULES`. Keep the canvas, pivot, and transparent padding compatible with these anchors so final art can replace placeholders without changing gameplay logic.

- **Floor assets** use the `center` anchor. A 128×71 SVG canvas should keep the 1.81:1 diamond centered so it remains inside the projected grid cell.
- **Wall assets** use the `wall_cell_base` anchor. A 128×120 canvas should place the lower wall footprint at the bottom center of the active 128×71 footprint; the renderer offsets it upward to sit on the blocked wall cell.
- **Wall-mounted objects** such as terminals, buttons, switches, and sockets use `wall_mount_center`. A 96×96 canvas should keep the useful prop centered around the mount band, with transparent padding around it.
- **Doors/gates** use `door_insert_center`. A 96×96 canvas should keep the door panel centered in the intended wall opening rather than on the floor diamond. Keep the visible panel centered in that 96×96 canvas; transparent padding above/below matters because the renderer aligns the full canvas, not the painted pixels. Door state overlays for locked, powered, unpowered, open, and damaged states are drawn by the renderer, so replacement art should not bake those gameplay-state badges into the placeholder itself.
- **Pickups/items** such as keys, fuses, keycards, access codes, and repair kits use `bottom_center`. A 96×96 canvas should put the visual footprint at the bottom center so the item is small, readable, and grounded on the floor.
- **Larger floor props** such as cable reels, components, and generic objects also use `bottom_center`, but with a larger renderer scale than pickups.

The SVG viewBox matters because alignment is computed from the texture canvas, not from visible pixels. If replacement art has extra transparent padding, different dimensions, or a shifted drawing inside the canvas, it can appear to float, drift, overlap walls, or hide gameplay-relevant objects. Prefer matching the expected canvas sizes and moving the artwork inside that canvas before changing renderer offsets.

## Replacement guidance

To replace placeholders later:

1. Keep the same asset key in `RoomVisualRenderer.ISO_PLACEHOLDER_ASSET_PATHS` or update the corresponding catalog entry safely.
2. Replace the SVG with final SVG/PNG art that uses a compatible transparent canvas and pivot/alignment.
3. Keep gameplay behavior in scripts/resources; art files are visual-only.
4. Verify `get_visual_texture_asset_reference_diagnostics()` after changing paths.

## Asset key mapping

| Asset key | SVG file |
| --- | --- |
| `floor_default` | `iso_floor_default.svg` |
| `floor_stepped` | `iso_floor_stepped.svg` |
| `floor_clean_lab` | `iso_floor_clean_lab.svg` |
| `floor_dark_service` | `iso_floor_dark_service.svg` |
| `floor_hazard` | `iso_floor_hazard.svg` |
| `floor_power` | `iso_floor_power.svg` |
| `floor_damaged` | `iso_floor_damaged.svg` |
| `floor_reinforced` | `iso_floor_reinforced.svg` |
| `floor_diagnostic` | `iso_floor_diagnostic.svg` |
| `floor_door_underlay` | `iso_floor_door_underlay.svg` |
| `wall_default` | `iso_wall_default.svg` |
| `wall_outer` | `iso_wall_outer.svg` |
| `wall_brick` | `iso_wall_brick.svg` |
| `wall_concrete` | `iso_wall_concrete.svg` |
| `wall_grate` | `iso_wall_grate.svg` |
| `wall_damaged` | `iso_wall_damaged.svg` |
| `wall_steel` | `iso_wall_steel.svg` |
| `wall_energy` | `iso_wall_energy.svg` |
| `object_door` | `iso_object_door.svg` |
| `object_terminal` | `iso_object_terminal.svg` |
| `object_key` | `iso_object_key.svg` |
| `object_component` | `iso_object_component.svg` |
| `object_socket` | `iso_object_socket.svg` |
| `object_cable` | `iso_object_cable.svg` |
| `object_generic` | `iso_object_generic.svg` |
| `object_fuse` | `iso_object_fuse.svg` |
| `object_repair_kit` | `iso_object_repair_kit.svg` |
| `object_keycard` | `iso_object_keycard.svg` |
| `object_access_code` | `iso_object_access_code.svg` |
| `object_cable_reel` | `iso_object_cable_reel.svg` |
| `object_button` | `iso_object_button.svg` |
| `object_switch` | `iso_object_switch.svg` |
