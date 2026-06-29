# Passive Route Manual Smoke Checklist

Use TASK TEST / Map Constructor. Do not write normal mission resources.

- Place two neighboring external air-duct segments with matching opposite ports; verify the preview lists each segment as a compatible neighbor and shows the same computed component ID.
- Reverse `route_side_1` and `route_side_2`; verify topology and rendering do not change.
- Rotate one neighboring segment so it lacks the opposite port; verify a machine-readable `neighbor_port_mismatch` issue appears and no connection is inferred from adjacency.
- Place an air duct beside a water pipe; verify `neighbor_kind_mismatch` and separate components.
- Place inner and outer variants beside each other through legacy data loading; verify `neighbor_mode_mismatch` and no connection.
- Choose the same side twice; verify `route_side_duplicate` without editor mutation.
- Load a legacy route carrying manual contour, durability, state, connection-array, and test-override fields; verify those fields are absent after normalization while mount and both route sides remain.
- Save an intentionally invalid draft and open TASK TEST; verify draft save and test load remain available while promotion reports the route issue.
- Confirm route editing does not alter passability and does not trigger unrelated power or cooling changes.
- Confirm the renderer shows the same straight/turn geometry reported by the read-only preview.
