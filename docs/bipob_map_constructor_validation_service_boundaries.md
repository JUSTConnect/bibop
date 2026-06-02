# Map Constructor validation/service boundaries

## Purpose and scope

This document records the Map Constructor validation/service boundary audit after the accepted GameUI split PRs (#773–#780). It is a documentation-only snapshot: it does not implement a refactor, change runtime behavior, rename APIs, or change Door/Terminal/Power/Item semantics.

The audit covered:

- `scripts/ui/game_ui.gd`;
- `scripts/ui/map_constructor/map_constructor_screen.gd`;
- `scripts/ui/map_constructor/map_constructor_inspector.gd`;
- `scripts/ui/map_constructor/map_constructor_property_controls.gd`;
- `scripts/ui/map_constructor/map_constructor_link_controls.gd`;
- `scripts/ui/map_constructor/map_constructor_validation_view.gd`;
- `scripts/game/map_constructor_service.gd`;
- `scripts/game/map_constructor_validation_service.gd`;
- `scripts/game/mission_manager.gd`.

The conclusion is intentionally conservative: the UI extraction work is real, but service extraction is incomplete. The next PRs should narrow dependencies one boundary at a time instead of moving broad blocks of logic.

## 1. Current architecture snapshot

### `GameUI`

`scripts/ui/game_ui.gd` remains the Map Constructor UI owner/coordinator. It still holds constructor mode, selected entity, selected prefab, pending placement, picker, filter, preview, autofix, cleanup, patch, history, batch, template, overlay, and overview UI state. It still coordinates refreshes after mutations, requests field visual refreshes, routes hints, focuses issues, builds overlay link/power presentation rows, and invokes MissionManager-facing APIs for constructor actions.

This is acceptable as an intermediate state, but it is not the final service boundary. Selection and refresh coordination may remain in a UI controller; semantic decisions and data mutation rules should not remain in `GameUI`.

### `scripts/ui/map_constructor` helpers

The extracted helper scripts now own meaningful presentation slices:

- `map_constructor_screen.gd` builds, refreshes, hides, and clears the Map Constructor root panel;
- `map_constructor_inspector.gd` builds the inspector shell, resolves the selected entity, preserves scroll state, mounts sections, and triggers final refresh work;
- `map_constructor_property_controls.gd` renders text, boolean, preset, schema-driven, and other property widgets;
- `map_constructor_link_controls.gd` renders link pickers and target navigation controls;
- `map_constructor_validation_view.gd` renders linked, missing, and warning groups and deduplicates displayed warning rows.

The helpers are currently presentation-oriented but not presentation-only. Several helpers call `ui.mission_manager_runtime` directly for read models and mutation APIs. In particular, property controls call property update/preset APIs, link controls still call specialized key-link reads and existing link mutation APIs while generic picker reads pass through `MapConstructorLinkReadModelService`, and the inspector calls entity lookup, type-group, visual-state, and link validation APIs.

### `MapConstructorService`

`scripts/game/map_constructor_service.gd` already owns a focused mutation slice:

- prefab placement;
- remove by entity id and remove at cell;
- move and duplicate operations;
- entity lookup by id;
- cloning constructor entity data;
- single-property update application;
- terminal/door link synchronization performed as part of property update handling.

`MissionManager` exposes forwarding methods for several of these operations. This is a useful existing service seam. Future extraction should preserve behavior while making callers depend on a stable constructor-facing API instead of expanding direct MissionManager knowledge.

### `MapConstructorValidationService`

`scripts/game/map_constructor_validation_service.gd` already owns a substantial validation slice:

- constructor palette contract validation;
- entity link validation, delegated to the read-only `MapConstructorPowerLinkValidationRules` helper;
- dependency status calculation, delegated to the read-only power/link helper;
- validation overlay aggregation;
- issue creation and constructor issue collection;
- door-opening probes and summaries;
- expected-invalid classification;
- readiness check assembly and mission readiness report generation;
- audit summary generation.

The service still calls back into `MissionManager` for runtime state, task-test audit data, and autofix recommendations. That is a valid transitional adapter, not evidence that validation extraction is complete. A future PR should avoid introducing new validation decisions in UI code or in display adapters.

### `MissionManager`

`scripts/game/mission_manager.gd` remains the runtime owner and compatibility facade. It initializes or lazily obtains `MapConstructorService` and `MapConstructorValidationService`, forwards some service APIs, and still contains important constructor responsibilities that have not been extracted, including:

- runtime constructor state and authoritative object/item collections;
- preset save/load and patch workflows;
- archetype property schema generation;
- property preset lookup/application and multi-property updates;
- link candidate generation and link mutation routing;
- cleanup and autofix preview/application/undo logic;
- change history, batch/template, pipeline, and audit integration;
- broader power/cooling recalculation hooks after mutations.

MissionManager must not be broadly rewritten during the next steps. Each follow-up PR should move or wrap one narrow boundary while retaining MissionManager as a compatibility facade until callers are migrated safely.

## 2. UI responsibilities that should remain UI

The UI/helper layer should continue to own presentation and interaction-shell concerns:

- panel construction and mounting;
- rows, buttons, labels, checkboxes, and editor controls;
- panel visibility and active-tab display;
- scroll position, inspector expand/collapse state, and display filters;
- routing user-facing hints returned from service calls;
- selected-row highlighting, focus, target navigation, and overlay display routing;
- binding button callbacks;
- calling stable service APIs and rendering their read-only results;
- requesting a targeted visual refresh after a successful mutation.

UI helpers may format presentation strings and group rows for layout. They should not decide whether a Door/Terminal/Power/Item link is semantically valid, infer repair plans from free-form messages, or normalize runtime control/access/power semantics.

## 3. Service responsibilities that should not stay in UI

The following responsibilities should eventually live outside `GameUI` and UI helpers behind narrow constructor-facing APIs:

- validation rules and severity decisions;
- fix, cleanup, repair, and autofix plan generation;
- link candidate eligibility rules and target read models;
- power/link consistency checks;
- property schema generation when presentation metadata is mixed with data rules;
- map save/load readiness checks;
- semantic normalization of control, access, and power types;
- canonical mapping between semantic link types and persisted fields;
- mutation result assembly for property and link changes;
- deciding whether a mutation requires targeted or broader runtime recalculation.

The objective is not to hide data blindly. The objective is to return explicit read-only dictionaries/results to the UI, so the UI renders a stable contract and does not duplicate semantic branches.

## 4. Current service boundary risks

### UI helpers call `mission_manager_runtime` directly

The extracted helpers are still coupled to a broad runtime owner. Inspector and property helpers query `mission_manager_runtime` methods directly. Link controls now use `MapConstructorLinkReadModelService` for generic picker reads, but specialized key-link reads and link mutation callbacks still call `mission_manager_runtime`. This makes it easy to add another semantic decision to a UI helper instead of extending a focused constructor API.

### Property controls apply mutations through the property update facade

`map_constructor_property_controls.gd` now routes property and preset callbacks through `GameUI`, which delegates mutation calls to `map_constructor_property_update_service.gd`. `GameUI` intentionally retains panel, field, and inspector refresh sequencing so this facade extraction does not alter UI behavior.

### Link picker field mapping now lives behind a read model

`map_constructor_link_read_model_service.gd` now owns the generic semantic link-type-to-persisted-field mapping and provides display-ready picker labels, current values, candidate rows, and target navigation metadata. Existing specialized key-link reads and all mutation callbacks remain in their prior paths for later narrowly scoped extraction.

### Validation display still groups rule-shaped keys

`map_constructor_validation_view.gd` is mostly a display adapter, but it knows result buckets such as `missing_links`, `broken_links`, `capacity_issues`, `validation_warnings`, and `physical_path_warnings`, and deduplicates them for presentation. This is safe to extract first as an adapter contract, but rule grouping and severity meaning must remain service-owned.

### `GameUI` still coordinates selected entity state and post-mutation refresh

`GameUI` continues to own selected entity state, picker targets, overlay state, previews, and refresh sequencing after mutations. Selected UI state and screen refresh routing may remain UI concerns. Semantic mutation policy, validation policy, and broad recalculation policy must not drift into `GameUI` while services are extracted.

### Validation and autofix are not yet one clean boundary

`MapConstructorValidationService` produces issues and readiness reports, but readiness recommendations still call back into MissionManager autofix options. MissionManager still owns cleanup/autofix preview, apply, undo, snapshots, and broad recalculation. This is a staged boundary: extract adapters and read models first, then isolate validation consistency rules without changing repair behavior.

## 5. Recommended extraction order

The order below intentionally separates read-only extraction from mutation extraction and leaves semantic behavior unchanged.

### PR-V1: Extract validation display adapters only

Status: extracted. `map_constructor_validation_adapter.gd` now owns read-only normalization and display dedupe for the inspector linked, missing, and warning rows. Validation rules, severity decisions, readiness rules, and autofix execution remain in their existing owners.

- Define a display adapter/read-model boundary for linked, missing, warning, and readiness rows.
- Keep validation rules, severity decisions, and issue generation unchanged.
- Keep `map_constructor_validation_view.gd` focused on rows, labels, buttons, grouping for display, and callbacks.
- Do not move autofix execution or alter issue semantics.

### PR-V2: Extract link candidate/read model service from MissionManager access

Status: extracted. `map_constructor_link_read_model_service.gd` now owns the generic semantic link-type-to-field mapping and builds read-only picker rows, current labels, and navigation metadata. Existing MissionManager candidate generation and link mutation behavior remain unchanged.

- Add a narrow constructor link read model for current target, candidates, labels, target cells, and navigation metadata.
- Move semantic link-type-to-field mapping out of UI code.
- Stop link UI helpers from querying broad MissionManager internals directly where the read model can answer the request.
- Preserve all Door/Terminal/Power/Item link behavior.

### PR-V3: Extract map constructor property update service wrapper

Status: extracted. `map_constructor_property_update_service.gd` now owns the narrow property and preset mutation facade used by UI callbacks. Existing MissionManager mutation APIs, property semantics, and GameUI refresh sequencing remain unchanged.

- Add a narrow property update facade used by UI callbacks.
- Preserve existing single-field and preset mutation semantics.
- Return explicit mutation results and targeted refresh hints.
- Avoid broad recalculation after every UI change unless the existing semantic path requires it.

### PR-V4: Extract power/link consistency validation rules

Status: extracted. `map_constructor_power_link_validation_rules.gd` now owns read-only entity-link validation, dependency status assembly, physical-circuit warning assembly, external-power binding checks, Door access/key/Terminal consistency checks, and Terminal/Door mirror checks. `MapConstructorValidationService` retains forwarding wrappers and issue aggregation. No simulation, active-state mutation, autofix, link mutation, or power/cooling recalculation was added.

- Consolidate power/link consistency checks behind the validation boundary.
- Keep checks read-only.
- If simulation becomes necessary, snapshot and restore runtime state explicitly.
- Do not alter Door control/access semantics, Terminal behavior, or Power network behavior.

### PR-V5: Extract save/load readiness validation boundary

- Add a readiness boundary used before save/load/promotion workflows where appropriate.
- Keep the existing save format unchanged.
- Return read-only readiness reports and actionable diagnostics.
- Keep persistence execution and compatibility routing stable until a later separately reviewed PR.

## What must NOT move yet

The following work is intentionally deferred until the narrow PR sequence above establishes stable contracts:

- broad MissionManager decomposition;
- runtime object/item ownership;
- save format or preset format changes;
- patch format changes;
- Door/Terminal synchronization behavior changes;
- cleanup/autofix apply and undo rewrites;
- broad power/cooling recalculation rewrites;
- GameUI selection-state redesign;
- property/link UI redesign;
- batch, kit, template, pipeline, or history architecture changes.

## 6. Non-goals

This audit and the follow-up boundary PRs must not introduce:

- gameplay rule changes;
- Door control/access semantic changes;
- Terminal behavior changes;
- Power network behavior changes;
- save format changes;
- property/link UI redesign;
- GDScript runtime behavior changes as part of this documentation PR;
- Russian game-facing labels.

## 7. Acceptance checklist for future service extraction PRs

Use this checklist for PR-V1 through PR-V5:

- [ ] UI remains a rendering/callback shell.
- [ ] Services return read-only dictionaries/results for display paths.
- [ ] Validation does not mutate active runtime state.
- [ ] Any required simulation snapshots and restores state explicitly.
- [ ] No broad global recalculation is added after each UI change.
- [ ] Existing Door/Terminal/Power/Item semantics remain unchanged.
- [ ] Existing save and patch formats remain unchanged unless a separately scoped PR explicitly changes them.
- [ ] Runtime labels remain English.
- [ ] `python tools/check_gdscript_safety_patterns.py` passes.
- [ ] `python tools/check_map_constructor_sections.py` passes.
- [ ] The parser gate remains green.

## Audit note

This boundary document marks the validation/service boundary audit, PR-V1 validation display adapter extraction, PR-V2 link candidate/read model service extraction, PR-V3 property update service wrapper extraction, and PR-V4 read-only power/link consistency validation rules extraction as complete. It does **not** mark link mutation extraction, autofix extraction, save/load readiness validation extraction, or the full GameUI split complete.
