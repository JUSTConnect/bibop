# Current-code notes for issue #1143

Verified against `main` before preparing the Codex prompt:

- `scripts/field/room_visual_renderer.gd` currently preloads projection, floor, wall, object and route components, but no overlay component.
- Interaction-target rect sizing, pulse math, corner geometry, colors, widths and 16 ordered line draws are still implemented directly in `RoomVisualRenderer`.
- Mouse-selection drawing still directly owns route, selected-cell, action-cell, wall-anchor, attached-wall and selected wall-object marker policy.
- Runtime lookup of the selected wall-mounted object occurs inside the coordinator and must remain there.
- The large Map Constructor overlay block begins immediately after the normal mouse-selection overlay block and is deliberately excluded from this slice.
- Fog remains fully coordinator-owned and is deliberately excluded.
- The current architecture checker reads projection/floor/wall/object/route components and enforces a `RoomVisualRenderer` cap of 6450 lines; this slice must add `OverlayRenderer` enforcement and lower the cap based on the actual post-extraction line count.
- The permanent Renderer Component Gate currently runs projection, floor, wall, object and route contracts; add the overlay contract to the same workflow.

The implementation source of truth is still the current repository code, not these notes.