# Normal Items and Details

Normal inventory items and `Details` use separate contracts.

## Normal items

A normal item represents exactly one unit. It is non-stackable and does not store `amount`, `quantity`, `stack_size`, `stack_count`, or `item_amount`.

Runtime normalization removes legacy stack fields before an item enters a pocket, manipulator, digital storage, or box storage. Consumables are removed only after the related action result reports success. Failed, blocked, and no-change actions preserve inventory.

## Details currency

`details` is the technical currency ID. The Russian display name is `Детали`.

`DetailsCurrencyService` is the only owner of the central balance and processed reward or transaction IDs. Details never occupies an inventory or center-storage slot.

A map pickup uses `object_type = details_pickup`, `currency_id = details`, `storage_type = none`, and a positive `amount`.

Map, chest, mission, and other rewards must call the same currency service with a stable reward ID. Duplicate IDs return `duplicate_reward` without changing balance or producing another notification. Spending returns stable `spent`, `insufficient`, `invalid_amount`, or `duplicate_transaction` codes.

## Persistence

Currency persists outside inventory in a versioned `details_currency` snapshot containing balance and processed IDs. Inventory snapshots contain item state only and do not expose a Details slot or canonical `item_amounts` map.

## Legacy migration

Migration recognizes legacy `parts`, `parts_small`, `parts_medium`, and `parts_large` entries in world pickups, inventory, box storage, `item_amounts`, center storage, and resource records.

Migration runs before normal item routing. World entries first become Details pickups and retain their amount; stored entries are then credited once to the central balance and removed from old slots. A stable migration reward ID makes repeated migration idempotent.

Existing `parts_*` visual/drop aliases remain compatible but no longer create inventory items.

## Runtime rules

- Preview operations are read-only.
- Failed receive, spend, pickup, drop, or use actions do not mutate state.
- One successful player command returns at most one notification event.
- UI reads machine-readable codes and the central balance instead of parsing inventory text.
