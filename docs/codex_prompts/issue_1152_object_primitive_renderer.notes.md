# Issue #1152 audit notes

Current `RoomVisualRenderer` object cluster still mixes runtime orchestration, texture dispatch and deterministic procedural Canvas policy.

The next slice must extract only deterministic non-route procedural object primitives. Texture loading/cache, authored-canvas descriptor routing, door insert and route/cable rendering remain later stages.

Current coordinator cap after merged PR #1151: 6153 lines.
