# Bipob isometric asset standard — 1.81:1

BIP-Visual-020 standardizes the visual-only isometric pipeline on one production footprint. This document describes art and alignment expectations only; it does not change gameplay grid coordinates, passability, pathfinding, mission logic, inventory, or object interaction rules.

## Runtime projection

- **Runtime tile footprint:** `128x71` pixels (`Vector2(128.0, 71.0)`).
- **Runtime ratio:** approximately `1.8028:1`, referred to as the 1.81:1 visual standard.
- **High-resolution art template equivalent:** `512x283` pixels. Downsample or export from this size when preparing final floor art for the runtime footprint.
- **Production projection mode:** `standard_128x71`. Legacy `classic_128x64` exists only as an explicit visual fallback/legacy option.

## Floor assets

- Floor tiles use a **center anchor**: the center of the texture canvas should align to the projected grid cell center.
- The visible floor diamond should fill the `128x71` footprint without baking in gameplay information.
- Keep transparent padding symmetric unless a deliberate visual offset is documented in renderer alignment metadata.
- Placeholder SVGs may use a `128x71` viewBox; high-resolution production sources should use the `512x283` template and export transparent PNGs for runtime use.

## Wall assets

- Walls use a **bottom-center / wall-cell-base anchor**: the bottom center of the wall canvas or measured visible base aligns to the active `128x71` wall footprint.
- Wall sprites may be taller than the `128x71` footprint. Height represents visible wall mass above the floor diamond and must not imply a different gameplay cell size.
- Wall bases should follow the same diamond angle as the active floor footprint so straight runs and corners share the same 1.81:1 projection.
- If a wall PNG includes transparent margins, keep the visible base position stable and let renderer placement metadata describe the visual bounds.

## Transparent PNG rules

- Export PNGs with transparency preserved; do not flatten to an opaque background.
- Avoid stray semi-transparent pixels outside the intended canvas footprint unless they are intentional shadows/glow.
- Keep pivots and visual padding consistent across variants in the same asset family so swaps do not drift.

## Gameplay boundary

This standard is visual-only. It must not alter gameplay grid size, movement rules, walkability, mission resources, power/cooling/cable behavior, inventory logic, or object interaction behavior.
