# Current-code notes for issue #1148

Verified against current `main` after merged PR #1147:

- `RoomVisualRenderer` is approximately 6149 source lines; permanent cap is 6162. Recount before implementation.
- Normal selection/interaction overlays delegate to `OverlayRenderer`.
- Map Constructor overlays delegate to `MapConstructorOverlayRenderer`.
- `_draw_overlay_commands()` supports polygon, polyline, line, and circle commands; text execution is not yet supported.
- `_draw()` currently places wall-mount zones, wall-run diagnostics, and floor-join diagnostics immediately after geometry; then cable-reel drag trail, selection, Map Constructor, interaction target, world markers, fan marker, fog, and final helper preview.
- Confirmed direct Canvas policy remains in `draw_wall_mount_zones_overlay()`, `draw_wall_run_overlay()`, `draw_floor_join_overlay()`, `draw_world_overlay_markers()`, `draw_fan_platform_marker()`, and the origin/helper-preview branches in `_draw()`.
- Additional inline diagnostic policy remains behind `show_object_grounding_overlay`, `show_asset_alignment_overlay`, `show_door_opening_overlay`, and potentially `show_wall_topology_overlay`; exact helpers and call-site placement must be audited before editing.
- Runtime/grid/mission lookup, visibility checks, projection, topology queries, font selection, and Canvas execution must stay in the coordinator.
- Cable-reel drag trail, fog, textures, resource loading, and primary object/floor/wall rendering are explicitly outside this slice.

The implementation source of truth is the latest repository code and issue #1148, not these notes.
