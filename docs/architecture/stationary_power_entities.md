# Stationary power entity ownership

Issue: #1181

- `PowerControlResolver` remains the only stationary power topology resolver.
- `StationaryPowerEntityCatalog` owns canonical definitions and the read-only legacy adapter.
- `StationaryPowerActionService` owns structured player action results for lights and stationary cable repair/reconnect.
- Physical cable, fuse, switch and socket topology is not stored in `BindingStore`.
- Resolved power state, source and circuit identifiers are computed runtime fields, not Map Constructor authoring truth.
- Autonomous power recomputation never emits a player-action notification.
