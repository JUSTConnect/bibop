# Versioned Migration Manual Smoke Checklist

Use copied legacy fixtures or TASK TEST data. Do not modify normal mission resources.

- Load a format-0 world document containing embedded terminal, access-item, and preferred-source links; verify canonical BindingStore records are created exactly once.
- Include a physical `runtime_power_feed` binding; verify it is removed with a machine-readable warning while cable-reel endpoint/path data remains intact.
- Load a legacy reel with flat endpoint fields and `cable_path_cells`; verify nested endpoints and canonical `path_cells` are written on the next save.
- Load inventory and center-storage Parts; verify one central Details balance and no remaining `item_amounts` or center `parts` key.
- Load legacy normal/heavy crates and a passive air duct; verify movement requirements and normalized route geometry.
- Save immediately after migration; verify `format_version = 2` with `entities`, `bindings`, `inventory_state`, `center_storage`, and `details_currency` only.
- Reload that version-2 save; verify no migration steps run and the serialized document is unchanged.
- Attempt to load a newer unsupported format and malformed entity row; verify the live mission remains unchanged.
- Load a recoverable unknown logical binding role; verify draft save and TASK TEST remain available while promotion is blocked and the raw record appears in issue details.
- Load a schema-1 Map Constructor preset; verify it becomes schema 2 with `world_state_snapshot` and without `mission_world_objects`, `cell_items`, or `world_objects_by_cell`.
- Save and reload the migrated preset from `user://`; verify only schema 2 is written.
