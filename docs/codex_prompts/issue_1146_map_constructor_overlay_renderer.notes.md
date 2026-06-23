# Current-code notes for issue #1146

Verified against current `main` after merged PR #1145:

- `RoomVisualRenderer` is 6190 lines; the permanent cap is 6205.
- `draw_map_constructor_visual_overlay_passes()` still owns all deterministic Map Constructor colors, widths, radii, offsets, direction mapping, primitive ordering and direct Canvas calls.
- `_draw_wall_side_arrow()` still performs projection-adjacent direction mapping plus direct `draw_line()` / `draw_circle()` execution.
- Existing `_draw_overlay_commands()` supports `polygon`, `polyline` and `line`; this slice needs `circle` support without adding policy to the dispatcher.
- The current Map Constructor pass order is selected, hover, placement preview, room walls, room doors, room terminals, room floors, multi-select, validation, links, power, preview wall-side arrow, selected wall-side arrow.
- Current guard conditions are inconsistent by design and must be preserved during extraction: links/power check x only; preview arrow checks preview x only; selected arrow only checks non-empty side before projection.
- `OverlayRenderer` already owns normal selection and interaction-target policy and is explicitly out of scope.
- Runtime/debug overlays outside the Map Constructor function, fog, texture caches, resource lookup and object rendering remain coordinator-owned in this slice.
- The permanent Renderer Component Gate currently runs projection, floor, wall, object, route and normal overlay contracts.

The implementation source of truth is the latest repository code and issue #1146, not these notes.
