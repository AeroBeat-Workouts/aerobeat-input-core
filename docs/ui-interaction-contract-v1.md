# AeroBeat UI Interaction Contract v1

**Status:** Implemented in `aerobeat-input-core`  
**Primary implementation commit:** `94a2e42` — `Add v1 UI interaction contract scaffolding`

This document describes the actual v1 UI interaction surface now available to downstream AeroBeat repos.

## Why downstream repos should use this

The contract gives AeroBeat UI code one normalized interaction surface instead of forcing each repo to parse raw Godot mouse, touch, hybrid 3D GUI, or future XR input on its own.

Core rules:

- one canonical lifecycle field: `phase`
- no separate canonical `action` field in the shared payload
- composition/adapters only
- touch and XR are represented now but explicitly unverified
- downstream consumers can depend on the bus/helpers instead of raw `InputEvent` classes

## Implemented files

### Core contract/data

- `src/ui/ui_interaction_event.gd`
- `src/ui/ui_interaction_types.gd`
- `src/ui/ui_verification_status.gd`

### Dispatcher

- `src/ui/ui_interaction_bus.gd`

### Adapters

- `src/ui/adapters/screen_ui_input_adapter.gd`
- `src/ui/adapters/hybrid_subviewport_input_adapter.gd`
- `src/ui/adapters/xr_ui_input_adapter.gd`

### Consumer helpers

- `src/ui/consumers/ui_interaction_listener.gd`
- `src/ui/consumers/ui_interactable.gd`

### Validation

- `.testbed/tests/unit/ui/test_ui_interaction_contract.gd`

## Canonical event shape

The shared event object is `AeroUiInteractionEvent`.

Important fields:

- `event_id`
- `pointer_id`
- `source_type`
- `source_variant`
- `surface_type`
- `surface_id`
- `phase`
- `target_path`
- `timestamp_usec`
- `screen_position`
- `surface_position`
- `surface_normalized_position`
- `world_position`
- `world_normal`
- `world_direction`
- `primary`
- `pressed`
- `button`
- `contact_count`
- `pressure`
- `delta`
- `world_delta`
- `velocity`
- `click_count`
- `modifiers`
- `is_synthetic`
- `verification_status`
- `verification_notes`
- `raw_event_class`
- `raw_metadata`

`AeroUiInteractionEvent.apply()` intentionally ignores any incoming `action` key so the shared contract stays phase-only.

## Stable taxonomy values

### Source types

- `mouse`
- `touch`
- `xr`
- `unknown`

### Source variants

- `screen_mouse`
- `screen_touch`
- `xr_ray`
- `xr_direct`
- `unknown`

### Surface types

- `screen_2d`
- `world_3d`
- `hybrid_3d_gui`

### Canonical phases

- `hover_enter`
- `hover_move`
- `hover_exit`
- `press_begin`
- `press_hold`
- `drag_begin`
- `drag_move`
- `drag_end`
- `press_end`
- `cancel`

There is deliberately no canonical `tap` phase. `tap`/`tapped` remain helper-derived ergonomics.

### Button/contact semantics

- `primary`
- `secondary`
- `tertiary`
- `contact`
- `trigger`
- `unknown`

## Verification-status truth model

Available values:

- `verified`
- `prototype`
- `unverified`
- `unsupported`

Current seeded defaults in `AeroUiInteractionBus`:

- `screen_mouse` + `screen_2d` -> `prototype`
- `screen_mouse` + `hybrid_3d_gui` -> `prototype`
- `screen_touch` + `screen_2d` -> `unverified`
- `screen_touch` + `hybrid_3d_gui` -> `unverified`
- `xr_ray` + `world_3d` -> `unverified`
- `xr_ray` + `hybrid_3d_gui` -> `unverified`
- `xr_direct` + `world_3d` -> `unverified`
- `xr_direct` + `hybrid_3d_gui` -> `unverified`

These values describe truth for the adapter/runtime path, not for a downstream widget.

## Bus API

`AeroUiInteractionBus` is the shared dispatcher.

Signals:

- `interaction_event(event: AeroUiInteractionEvent)`
- `interaction_for_surface(surface_id: StringName, event: AeroUiInteractionEvent)`
- `interaction_for_target(target_path: NodePath, event: AeroUiInteractionEvent)`

Methods:

- `publish(event_data: Variant) -> AeroUiInteractionEvent`
- `register_surface(surface_id: StringName, metadata: Dictionary = {}) -> void`
- `unregister_surface(surface_id: StringName) -> void`
- `get_surface_metadata(surface_id: StringName) -> Dictionary`
- `set_source_verification(source_variant, surface_type, status, notes = "") -> void`
- `get_source_verification(source_variant, surface_type) -> Dictionary`

## Adapter responsibilities

### `ScreenUiInputAdapter`

Use for standard screen-space UI.

It currently normalizes:

- `InputEventMouseButton`
- `InputEventMouseMotion`
- `InputEventScreenTouch`
- `InputEventScreenDrag`

It owns:

- pointer state
- press/drag threshold handling
- local surface coordinate resolution for a parent `Control`
- hover/press/drag phase publishing
- source/button normalization

### `HybridSubViewportInputAdapter`

Use when a repo already has projected world/hit data for a 2D UI rendered through a `SubViewport` or similar world-presented surface.

It does not claim to perform all 3D hit testing internally. Instead it provides a stable normalization boundary for projected surface data such as:

- `surface_normalized_position`
- `surface_position`
- `world_position`
- `world_normal`
- `world_direction`
- `target_path`

### `XrUiInputAdapter`

This is scaffolding for future XR pointer/direct interaction.

It exists so downstream repos can wire against the contract now, but its behavior should be treated as unverified until live device testing exists.

## Consumer helpers

### `AeroUiInteractionListener`

A lightweight bus subscriber that:

- filters by `surface_id`, `target_path`, and/or `pointer_id`
- re-emits phase-specific signals
- derives `tapped` without adding `tap` to the core payload

### `AeroUiInteractable`

A stateful helper that tracks:

- `is_hovered`
- `is_pressed`
- `is_dragging`
- `last_event`

and emits:

- `hovered_changed`
- `pressed_changed`
- `dragging_changed`
- `tapped`
- `canceled`

## Minimal usage examples

### 2D screen UI

```gdscript
var bus := AeroUiInteractionBus.new()
add_child(bus)

var adapter := ScreenUiInputAdapter.new()
adapter.bus_path = NodePath("../AeroUiInteractionBus")
add_child(adapter)
```

### Direct bus subscription

```gdscript
func _ready() -> void:
    var bus: AeroUiInteractionBus = $AeroUiInteractionBus
    bus.interaction_event.connect(_on_ui_interaction)

func _on_ui_interaction(event: AeroUiInteractionEvent) -> void:
    if event.phase == AeroUiInteractionTypes.PHASE_PRESS_BEGIN:
        print("Pressed via normalized contract")
```

### Listener helper

```gdscript
func _ready() -> void:
    var listener: AeroUiInteractionListener = $AeroUiInteractionListener
    listener.tapped.connect(_on_tapped)
```

## QA focus areas

QA should pay special attention to:

1. screen mouse semantics in a real scene, especially hover enter/exit and press/drag threshold behavior
2. hybrid `SubViewport` consumers receiving correct surface/world metadata from projected data
3. truthful handling of touch and XR as unverified rather than silently implied parity
4. downstream composition usage through bus/listener/interactable helpers rather than inheritance
5. whether any consumer is still forced to inspect raw Godot input classes

## Known limitations in v1

- `screen_mouse` is still seeded as `prototype`, not `verified`
- touch exists but has not been live-validated on real touch hardware
- XR exists only as future-ready scaffolding
- hybrid/world adapters assume the host repo provides projected hit/surface data where needed
- no multi-touch gesture framework, text input abstraction, or keyboard/gamepad navigation abstraction is included in this contract

## Related docs

- Proposal/source-of-truth design note: `docs/ui-interaction-contract-v1-proposal.md`
