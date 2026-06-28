# BIPOB Roadmap

**Updated:** 2026-06-28

This roadmap tracks the global development direction from prototype to release and the current ordered architecture program.

> RU note: проценты здесь примерные. Они нужны не для точной бухгалтерии, а чтобы понимать стадию проекта. Codex не должен обновлять этот файл без явного запроса.

---

## 1. Current Overall Progress

Estimated full project completion: **8%**

Current phase: **Prototype architecture and mechanics foundation**

Current implementation focus:

- canonical entity contracts and semantic validation;
- separated entity state axes;
- topology-derived power;
- canonical logical bindings;
- schema-driven runtime and Map Constructor presentation;
- controlled migration away from legacy entity fields.

Main blockers:

- entity definitions are structurally registered but not yet semantically normalized;
- legacy raw state, power, access and link fields still remain in runtime paths;
- stationary power topology and runtime cable reel semantics are not yet fully separated;
- Map Constructor readiness still needs separate Draft Save / TASK TEST / Promotion results;
- module port system is not implemented yet;
- first vertical slice missions are not built yet.

Planning note:

- issue #1173 established the declarative entity-contract foundation;
- issues #1174–#1193 define the ordered implementation and migration program;
- planning and issue updates do not increase completion percentages until code is merged and audited.

---

## 2. Milestone Update Rule

After completing a milestone, update this file manually:

```text
[ ] milestone status
[ ] completion percentage
[ ] what changed
[ ] what remains
[ ] next milestone
[ ] blockers
```

Do not require Codex to update this file unless explicitly requested.

---

## 3. Current Entity Architecture Program

### 3.1 Accepted architecture decisions

#### Entity state

Do not use one universal mutable `state` field for unrelated meanings.

Canonical axes:

```text
intent_state       = on | off
health_state       = healthy | damaged | broken
thermal_state      = normal | overheated
operational_state  = subtype-specific state
effective_state    = read-only derived result
```

Power loss does not overwrite intent, health, thermal or operational state.

#### Power source resolution

Stationary room power uses physical topology as source of truth:

```text
0 reachable sources  -> unpowered
1 reachable source   -> resolve automatically
multiple sources     -> use preferred_source_id when valid,
                        otherwise ambiguous
```

`preferred_source_id` only resolves ambiguity. It never replaces a real physical path.

#### Stationary cable and runtime cable reel

`power_cable`:

- is placed by the author in Map Constructor;
- belongs to the stationary power graph;
- is not an item;
- has no portable cable ends.

`power_cable_reel`:

- is a runtime item with two physical ends and a runtime path;
- connects a `power_socket` to a compatible target;
- inherits the socket's resolved power source;
- uses circuit `main` for the reel-fed target;
- stores physical endpoints/path as its own source of truth;
- does not duplicate the connection in BindingStore.

#### Logical bindings

Canonical logical relations belong to `WorldStateStore.BindingStore`.

Examples:

- control terminal;
- access terminal;
- access item;
- preferred power source;
- light/platform controller.

Physical cable adjacency, reel endpoints and passive route adjacency are not BindingStore records.

#### Readiness

Map Constructor readiness is split into:

```text
draft_save_allowed
task_test_allowed
promotion_allowed
```

- Draft Save is blocked only by a technical serialization/write failure.
- TASK TEST remains available for any loadable intentionally broken scenario.
- Promotion to a normal mission is blocked by critical instance or definition issues.

#### Items and Details

- normal items are single-unit and non-stackable;
- normal items do not have `amount`;
- `Details` is a separate currency with one central balance;
- Details does not occupy an inventory slot;
- legacy `parts` stacks must be migrated without duplication or loss.

#### Movable objects

- movement availability is calculated per action;
- only crates expose `weight_class = normal | heavy`;
- heavy crates require canonical actor type `engineer` or `heavy`, the required manipulator and power/module profile;
- `Juggernaut` is only a legacy/display alias for canonical type `heavy`;
- other movable objects use explicit movement requirement profiles, not crate weight.

#### Passive cooling routes

Air ducts and water pipes:

- have one mount side and exactly two route sides;
- use computed physical connectivity;
- do not store manual contour/member arrays;
- do not have device state, power, control, health or runtime test override;
- expose read-only authoring preview and diagnostics.

### 3.2 Ordered issue chain

#### Foundations

```text
[ ] #1186 Semantic contract validation
[ ] #1174 Separated entity state and normalized status snapshot
[ ] #1175 Topology-derived power and common control semantics
[ ] #1187 Canonical BindingStore in WorldStateStore
[ ] #1176 Access resolver and canonical binding usage
[ ] #1177 ActionResult, action_id ownership and notifications
[ ] #1178 Extend BipobActionViewModelService and runtime presentation
[ ] #1179 Schema-driven Map Constructor and split readiness
[ ] #1180 Strict type profiles
```

#### Sequential migrations

```text
[ ] #1181 Stationary power entities, lights, cables and sockets
[ ] #1182 Doors, terminals, access and remote control
[ ] #1183 Interactive machines and active cooling box
[ ] #1188 Runtime power cable reel and socket-inherited source
```

#### Final migration roadmap

Umbrella: #1184

```text
[ ] #1189 Normal items and Details currency
[ ] #1190 Movable objects and crate requirements
[ ] #1191 Passive air-duct and water-pipe routes
[ ] #1192 Versioned legacy map/save migration
[ ] #1193 Remove legacy runtime paths and add CI gates
```

### 3.3 Required execution order

1. Implement semantic validation before large migrations.
2. Implement separated state before power and subtype migrations.
3. Implement topology-derived stationary power.
4. Add BindingStore before migrating doors, terminals and duplicated logical links.
5. Add unified ActionResult before replacing notification UI paths.
6. Extend the existing `BipobActionViewModelService`; do not create a parallel action resolver.
7. Split Map Constructor readiness into Draft Save, TASK TEST and Promotion.
8. Migrate stationary power before runtime cable reel inheritance.
9. Migrate doors/access before general interactive machines.
10. Migrate items, movable objects and passive routes as independent stages.
11. Run versioned save/map migration only after canonical formats are stable.
12. Remove runtime adapters and add regression gates last.

### 3.4 Cross-cutting acceptance rules

- `GridManager` remains gameplay truth.
- Renderers remain presentation only.
- Evaluators and validation are read-only unless an explicit action is executing.
- Failed or blocked previews do not mutate state.
- Power/cooling/cable recalculation is scoped and event-driven.
- Runtime and editor use the same machine-readable codes.
- UI does not infer domain state from text or raw subtype fields.
- New records use canonical formats only; legacy support is isolated to versioned loading.
- No `project.godot` changes without an explicit reason.
- Do not create Test Build files or folders.

---

## 4. Global Release Phases

| Phase | Name | Status | Estimated completion |
|---|---|---:|---:|
| 0 | Prototype base | In progress | 35% |
| 1 | Architecture stabilization | In progress | 20% |
| 2 | Visual room foundation | In progress | 30% |
| 3 | Core mechanics foundation | In progress | 25% |
| 4 | Module management foundation | Not started / partial data only | 10% |
| 5 | TASK TEST complete sandbox | In progress | 40% |
| 6 | First vertical slice | Not started | 0% |
| 7 | Extended gameplay systems | Not started | 0% |
| 8 | Content production | Not started | 0% |
| 9 | UX / save / progression | Not started / partial | 5% |
| 10 | Release polish | Not started | 0% |

---

## 5. Phase 0 — Prototype Base

Estimated completion: **35%**

Goal:

Establish a playable prototype with grid movement, room rendering, interaction flow and sandbox testing.

Done / partial:

- Godot project opens in 4.6.
- GridManager exists.
- RoomVisualRenderer exists.
- BipobController exists.
- MissionManager exists.
- TASK TEST exists.
- Some mechanics are already represented in code.

Remaining:

- reduce overloaded files;
- finish the first stable gameplay loop;
- complete the entity architecture program in section 3;
- remove or migrate old legacy mission dependencies.

---

## 6. Phase 1 — Architecture Stabilization

Estimated completion: **20%**

Goal:

Stop growth of overloaded files and make future mechanics easy to place.

Milestones:

```text
[ ] Complete entity contract and semantic validation program
[ ] Separate canonical state, computed state and presentation
[ ] Add canonical BindingStore
[ ] Complete schema-driven runtime and Map Constructor paths
[ ] Complete versioned legacy migration and cleanup
[ ] Extract remaining overloaded coordinator responsibilities
[ ] Split GameUI into smaller UI controllers
[ ] Add file-size / architecture review rule to PR workflow
```

Success criteria:

- New mechanics have clear target files.
- MissionManager stops absorbing new systems.
- GameUI becomes a shell/coordinator.
- Definitions, runtime state, bindings and presentation have different owners.
- Normal runtime contains no legacy state/link inference.

---

## 7. Phase 2 — Visual Room Foundation

Estimated completion: **30%**

Goal:

Make the isometric room coherent and stable using final `128x71` projection.

Milestones:

```text
[ ] Seamless floor surfaces
[ ] Connected wall runs
[ ] Reduced wall spill into floor cells
[ ] Door openings preserved inside wall runs
[ ] Wall-mounted anchor zones preserved
[ ] Object grounding polish
[ ] Cable visual pass after cable contracts stabilize
[ ] Platform visual states
[ ] Fog/visibility production pass
```

Success criteria:

- Floor reads as one connected surface.
- Walls read as architecture, not isolated blocks.
- Doors are inserted into walls, not floating floor objects.
- Visual layer does not change gameplay truth.
- Cable/reel/route renderers consume normalized geometry only.

---

## 8. Phase 3 — Core Mechanics Foundation

Estimated completion: **25%**

Goal:

Stabilize the base engineering puzzle systems.

Milestones:

```text
[ ] Movement and action economy stable
[ ] Door access stable
[ ] Terminal action flow stable
[ ] Stationary power topology stable
[ ] Power socket and runtime cable reel stable
[ ] Cooling stable enough for puzzle use
[ ] Scan/diagnostic/X-Ray stable
[ ] Inventory pickup/use/drop stable
[ ] Details currency stable
[ ] Platforms stable enough for puzzle use
[ ] TASK TEST smoke checklist covers core mechanics
```

Success criteria:

- Failed actions do not mutate state.
- Preview functions do not mutate state.
- Power/cooling/cable changes are scoped.
- Systems work outside one-off mission hacks.
- One player command produces one final ActionResult.

---

## 9. Phase 4 — Module Management Foundation

Estimated completion: **10%**

Goal:

Make module configuration a real gameplay system.

Milestones:

```text
[ ] Internal module space rules
[ ] External module slot rules
[ ] Power Block port distribution
[ ] Internal Interface ports
[ ] External Interface ports
[ ] Processor requirement checks
[ ] Connector requirement checks
[ ] Installed but inactive modules
[ ] Inactive reason reporting
[ ] Box UI for module port usage
[ ] Module configuration smoke tests
```

Success criteria:

- Player cannot install/activate everything at once.
- Module choices matter before each mission.
- Power Block is port management, not battery storage.
- Battery remains energy storage.

---

## 10. Phase 5 — TASK TEST Complete Sandbox

Estimated completion: **40%**

Goal:

Use TASK TEST to validate all important mechanics before vertical slice missions.

Milestones:

```text
[ ] Read-only or snapshot/restore validation
[ ] Separate Draft Save / TASK TEST / Promotion readiness
[ ] Constructor palette completeness and semantic validation
[ ] Object overlap validation stable
[ ] Power/cable/reel/cooling scenario validation
[ ] Access and BindingStore scenario validation
[ ] Module configuration scenario validation
[ ] Visual diagnostics stable
[ ] Sandbox smoke checklist complete
```

Success criteria:

- TASK TEST can run intentionally invalid but loadable maps.
- Sandbox data does not pollute normal missions.
- Promotion blockers do not disable Draft Save or TASK TEST.
- New systems are proven here before story/tutorial use.

---

## 11. Phase 6 — First Vertical Slice

Estimated completion: **0%**

Goal:

Build 2–3 tutorial missions from sandbox-proven mechanics.

Milestones:

```text
[ ] Mission 1: movement, scan, door, terminal
[ ] Mission 2: stationary power, socket, cable reel, item use
[ ] Mission 3: modules, sensors, route choice
[ ] Tutorial UI text
[ ] Mission complete/fail flow
[ ] Basic progression loop
```

Success criteria:

- A new player understands the core loop.
- Missions use reusable systems, not one-off hacks.
- TASK TEST remains the development sandbox.

---

## 12. Phase 7 — Extended Gameplay Systems

Estimated completion: **0%**

Goal:

Add later tactical and systemic gameplay after base mechanics are stable.

Milestones:

```text
[ ] Runtime state framework built on canonical state axes
[ ] Equipment behavior framework
[ ] Automated object framework
[ ] Interaction availability framework
[ ] Recovery framework
[ ] Balance rules
[ ] TASK TEST scenarios
```

Success criteria:

- Extended systems are modular.
- They do not live inside MissionManager or BipobController.
- They are validated in TASK TEST before content production.

---

## 13. Phase 8 — Content Production

Estimated completion: **0%**

Goal:

Create real mission content and progression after systems are stable.

Milestones:

```text
[ ] Mission structure
[ ] Puzzle progression
[ ] Asset replacement plan
[ ] Final room visual pass
[ ] Module unlock pacing
[ ] Multi-Bipob progression design
```

---

## 14. Phase 9 — UX / Save / Progression

Estimated completion: **5%**

Goal:

Make the game usable as a full product experience.

Milestones:

```text
[ ] Versioned save/load runtime state
[ ] Box screen polish
[ ] Module installation UX
[ ] Mission selection UX
[ ] Inventory/storage UX
[ ] Details economy UX
[ ] Settings
[ ] Player feedback and diagnostics
```

---

## 15. Phase 10 — Release Polish

Estimated completion: **0%**

Goal:

Prepare the project for a public playable release.

Milestones:

```text
[ ] Performance pass
[ ] Bug fixing
[ ] Art consistency pass
[ ] Audio pass
[ ] Tutorial polish
[ ] Packaging/export
[ ] Demo materials
```
