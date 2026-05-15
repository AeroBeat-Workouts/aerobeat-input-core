# AeroBeat UI Interaction Contract v1 Proposal

**Date:** 2026-05-15  
**Status:** Proposed for Derrick review before implementation  
**Repo:** `aerobeat-input-core`

---

## Why this exists

`aerobeat-ui-kit-community` proved that Godot gives us the raw building blocks for hybrid 3D GUI input, but not the stable product-level contract we want downstream repos to consume.

The goal of this contract is:

- downstream UI code should depend on **one normalized AeroBeat interaction surface**
- adapters should hide raw differences between **mouse**, **touch**, and future **XR pointer** paths
- the architecture must be **composition/adapters**, not inherited base panel classes
- the contract must work for both **screen-space 2D UI** and **world-space / hybrid 3D UI**
- touch and XR must be **represented now** but marked **unverified/untested** until proven

This doc is a **contract proposal only**. It does **not** propose implementing production code before approval.

---

## Recommendation in one sentence

Create a small UI interaction layer in `aerobeat-input-core` built around a **normalized pointer event dictionary/object**, a **singleton dispatcher/bus**, and **surface-specific adapters** that translate raw Godot input into that normalized contract.

---

## Design principles

1. **Composition first**
   - Consumers subscribe to a dispatcher or attach a small interaction-consumer component.
   - No `BasePanel` inheritance tree.

2. **Pointer-intent first**
   - The shared contract should model UI interaction as pointer-like intent, not as device-specific Godot events.
   - Downstream code should not care whether a press came from mouse button 1, a finger tap, or an XR trigger on a ray pointer.

3. **Surface-agnostic contract**
   - 2D and 3D/hybrid paths should emit the same normalized event structure.
   - The only difference should live inside adapters.

4. **Truthful verification metadata**
   - Mouse can be marked verified first.
   - Touch and XR exist in the contract immediately, but their support status remains explicit.

5. **Stable downstream shape**
   - Future XR support should plug in as a new adapter without changing consumer APIs.

---

## Proposed v1 architecture

### Core layers

1. **Raw input source layer**
   - Native Godot `InputEvent`s
   - 3D pick hits / raycast hits / viewport coordinate mapping
   - Future XR ray/interactor events

2. **Adapter layer**
   - Converts raw source-specific data into normalized `AeroUiInteractionEvent`
   - Owns coordinate translation, device/source labeling, button/contact mapping, verification metadata attachment, and dispatch

3. **Dispatcher / bus layer**
   - Central singleton-style event router for normalized UI interaction events
   - Emits normalized events to downstream consumers
   - Optional targeting/filtering by surface ID / target path / interaction region

4. **Consumer layer**
   - UI components, controllers, and scene scripts subscribe to normalized events
   - Consumers react to `hover_enter`, `press`, `release`, `tap`, `drag_move`, etc.
   - Consumers do not parse raw mouse/touch/XR specifics

---

## Proposed normalized event model

## Canonical event object

Recommend one event payload object or dictionary shape named:

- `AeroUiInteractionEvent`

Suggested fields:

```gdscript
{
  "event_id": StringName,
  "pointer_id": StringName,
  "source_type": StringName,
  "source_variant": StringName,
  "surface_type": StringName,
  "surface_id": StringName,
  "phase": StringName,
  "target_path": NodePath,
  "timestamp_usec": int,

  "screen_position": Vector2,
  "surface_position": Vector2,
  "surface_normalized_position": Vector2,
  "world_position": Vector3,
  "world_normal": Vector3,
  "world_direction": Vector3,

  "primary": bool,
  "pressed": bool,
  "button": StringName,
  "contact_count": int,
  "pressure": float,

  "delta": Vector2,
  "world_delta": Vector3,
  "velocity": Vector2,

  "click_count": int,
  "modifiers": PackedStringArray,

  "is_synthetic": bool,
  "verification_status": StringName,
  "verification_notes": String,

  "raw_event_class": StringName,
  "raw_metadata": Dictionary
}
```

### Field intent

- `event_id`: unique ID for tracing/debugging
- `pointer_id`: stable pointer/contact/interactor identity across phases
- `source_type`: broad taxonomy like `mouse`, `touch`, `xr`
- `source_variant`: more specific path like `screen_mouse`, `screen_touch`, `xr_ray`, `xr_direct`
- `surface_type`: where interaction is happening, like `screen_2d` or `world_3d`
- `surface_id`: stable ID for a viewport/panel/surface adapter
- `phase`: lifecycle phase in the interaction state machine and the single canonical consumer event semantic
- `target_path`: optional resolved consumer target/path when the adapter can provide one
- `screen_position`: global screen pixel position if meaningful
- `surface_position`: local pixel position in the target UI surface
- `surface_normalized_position`: local normalized `[0..1]` coordinates for surface-agnostic consumers
- `world_position`: world-space hit position for 3D/hybrid/XR cases
- `world_normal`: world-space hit normal when available
- `world_direction`: incoming ray/direction when available
- `primary`: whether this is the primary pointer/contact for the current source
- `pressed`: whether the pointer is currently in an active pressed/contact state
- `button`: normalized logical button/contact name
- `contact_count`: useful for future multitouch, though v1 consumers should generally stay single-pointer-first
- `pressure`: optional, commonly `1.0` for mouse and simple taps
- `delta`, `world_delta`, `velocity`: useful for drags and future gestures
- `click_count`: double-click/tap tracking if later needed
- `modifiers`: keyboard modifier state if present
- `is_synthetic`: whether adapter synthesized the event from another raw form
- `verification_status`: consumer-visible truth label
- `verification_notes`: human-readable honesty field for logs/docs/debug overlays
- `raw_event_class`: traceability only
- `raw_metadata`: source-specific escape hatch for debugging, not for normal downstream dependency

---

## Proposed source taxonomy

Use a two-level taxonomy: `source_type` and `source_variant`.

### `source_type` values

- `mouse`
- `touch`
- `xr`
- `unknown`

### `source_variant` values for v1

- `screen_mouse`
- `screen_touch`
- `xr_ray`
- `xr_direct`
- `unknown`

### Meaning

- `mouse` / `screen_mouse`
  - desktop pointer path
  - initially the best candidate for first verified implementation

- `touch` / `screen_touch`
  - mobile/tablet finger interaction
  - included in the contract now
  - explicitly unverified until tested in a real environment

- `xr` / `xr_ray`
  - laser/ray pointer style XR interaction mapped onto a UI surface
  - designed now so future adapters can plug in without consumer changes

- `xr` / `xr_direct`
  - near-touch / poke / direct interactor path
  - also future-facing and unverified for now

This keeps the consumer logic simple:

- if it needs only generic pointer semantics, it ignores source details entirely
- if it wants analytics/debug UI, it can still inspect source metadata safely

---

## Proposed surface taxonomy

### `surface_type` values

- `screen_2d`
- `world_3d`
- `hybrid_3d_gui`

### Meaning

- `screen_2d`
  - standard Control/UI interaction directly on the 2D screen

- `world_3d`
  - interaction against a world-space UI plane or other 3D-addressed interface

- `hybrid_3d_gui`
  - authored as 2D `Control` UI, rendered through `SubViewport`, presented in world space
  - this is the current `aerobeat-ui-kit-community` proof path

Downstream consumers should not need separate behavior for these unless they intentionally care about world metadata.

---

## Proposed phase/lifecycle taxonomy

Use a small stable phase set.

### `phase` values

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

### Canonical phase-only rule

Use `phase` as the only normalized interaction lifecycle field in v1.

There is no separate `action` field in the shared contract. If a consumer wants a higher-level semantic grouping like “tap” or “drag”, it should derive that locally from the canonical phase stream or use a small helper component that does so without changing the shared event shape.

### Lifecycle rules

#### Hover path
- entering a hittable target/surface emits `hover_enter`
- movement while not pressed emits `hover_move`
- leaving emits `hover_exit`

#### Press path
- initial down/contact emits `press_begin`
- continued active pressed state may emit `press_hold` as needed
- release emits `press_end`

#### Tap rule
- `tap` is a derived semantic event, emitted only when:
  - `press_begin` occurred
  - release happens without exceeding drag threshold
  - the release remains valid per adapter policy

#### Drag rule
- once pointer motion exceeds configured threshold while pressed:
  - emit `drag_begin`
  - then `drag_move`
  - then `drag_end` before or at release

#### Cancel rule
- emit `cancel` when interaction validity is lost:
  - source disappears
  - viewport/surface capture breaks
  - XR interactor is invalidated
  - OS/app interruption occurs

This gives AeroBeat a device-neutral state machine instead of leaking device-specific event classes.

If we later want ergonomic sugar such as `tapped` or `dragged`, that should live in optional listener/helper components rather than in the canonical shared event payload.

---

## Normalized button/contact semantics

Use a logical button/contact field so consumers avoid raw device translation.

### `button` values

- `primary`
- `secondary`
- `tertiary`
- `contact`
- `trigger`
- `unknown`

### Mapping examples

- mouse left button -> `primary`
- mouse right button -> `secondary`
- mouse middle button -> `tertiary`
- touch press -> `contact`
- XR ray select/trigger -> `trigger` or `primary`

Recommendation: for generic consumer logic, treat `primary`, `contact`, and `trigger` as equivalent “activate/select” lanes unless a specific screen needs to distinguish them.

---

## Verification-status semantics

This is important enough to be first-class in the contract.

### `verification_status` values

- `verified`
- `prototype`
- `unverified`
- `unsupported`

### Meaning

- `verified`
  - path has been tested in a trustworthy real environment for the claimed behavior
- `prototype`
  - adapter exists and appears plausible, but parity is not fully proven
- `unverified`
  - contract recognizes this source/path, but real behavior is not yet validated
- `unsupported`
  - intentionally not provided by the current adapter/runtime

### Recommended v1 truth at proposal time

- `screen_mouse` on `screen_2d`: likely `verified` once implemented/tested
- `screen_mouse` on `hybrid_3d_gui`: likely `prototype` until direct live validation is complete
- `screen_touch` on `screen_2d`: `unverified` unless explicitly proven
- `screen_touch` on `hybrid_3d_gui`: `unverified`
- `xr_ray`: `unverified`
- `xr_direct`: `unverified`

### Important rule

`verification_status` belongs to the **adapter/runtime path**, not to the consumer.

A downstream button should not branch on raw mouse vs touch differences. It may optionally expose debug UI like “this came from an unverified XR path,” but its behavior contract remains the same.

---

## Adapter responsibilities vs consumer responsibilities

## Adapter responsibilities

Adapters own **all source-specific ugliness**.

### Adapters should do:
- detect raw source events
- map mouse/touch/XR input into normalized pointer semantics
- own `pointer_id` lifecycle
- perform hit testing or accept hit-testing input from the host surface
- translate coordinates:
  - screen -> local surface pixels
  - world hit -> surface UV -> local viewport coordinates
- track drag thresholds
- synthesize semantic events like `tap` when appropriate
- attach `verification_status`
- emit normalized events through the dispatcher
- optionally maintain per-pointer capture state

### Adapters should not do:
- business/UI behavior decisions
- panel-specific game logic
- screen-specific widget rules
- demand inheritance from UI scenes

## Consumer responsibilities

Consumers should stay small and declarative.

### Consumers should do:
- subscribe to normalized dispatcher events
- filter by target/surface as needed
- react to canonical phases
- update visuals/state (`hovered`, `pressed`, `selected`, `dragging`)
- optionally read source metadata for debugging/telemetry only

### Consumers should not do:
- inspect raw Godot event classes
- map 3D world hits to viewport coordinates
- special-case mouse vs touch vs XR for standard activate/select flow
- own verification truth tables

---

## Recommended singleton / bus / dispatcher shape

Recommend a singleton-style autoload or repo-provided dispatcher node:

- `AeroUiInteractionBus`

### Why a bus

- keeps downstream repos loosely coupled
- allows multiple adapters to publish into the same surface
- supports both 2D screens and 3D/hybrid panels uniformly
- avoids forcing direct adapter references into every UI scene

### Recommended high-level API shape

Signals:

- `interaction_event(event: Dictionary)`
- `interaction_for_surface(surface_id: StringName, event: Dictionary)`
- `interaction_for_target(target_path: NodePath, event: Dictionary)`

Methods:

- `publish(event: Dictionary) -> void`
- `register_surface(surface_id: StringName, metadata: Dictionary = {}) -> void`
- `unregister_surface(surface_id: StringName) -> void`
- `get_surface_metadata(surface_id: StringName) -> Dictionary`

Optional helper methods later:

- `capture_pointer(pointer_id, surface_id)`
- `release_pointer(pointer_id)`
- `set_source_verification(source_variant, surface_type, status, notes)`

### Recommended routing rule

Adapters should publish to the bus after normalization. Consumers should observe the bus or use a tiny wrapper component that subscribes for them.

---

## How 2D screen UI plugs in

### 2D path

Use a dedicated adapter such as:

- `ScreenUiInputAdapter`

Responsibilities:
- listen to `_input(event)` or equivalent source
- normalize mouse/touch events for standard `Control`-based UI
- resolve local target/surface coordinates directly
- emit normalized events to `AeroUiInteractionBus`

In this path:
- `surface_type = screen_2d`
- `surface_id` identifies the screen/root UI surface
- `world_position` and related fields can be empty/default

Consumers in downstream repos should handle this exactly the same way they handle world-space UI, except those world fields may be unused.

---

## How 3D / hybrid UI plugs in

### Hybrid/world-space path

Use a dedicated adapter such as:

- `WorldUiInputAdapter`
- or more specifically `HybridSubViewportInputAdapter`

Responsibilities:
- receive 3D hit results from a pickable panel surface
- map hit position into surface UV
- map UV into SubViewport pixel coordinates
- translate raw mouse/touch/XR interactor input into normalized pointer events
- optionally inject forwarded raw events into the SubViewport if needed for native `Control` behavior
- publish the same normalized event object to the bus

In this path:
- `surface_type = hybrid_3d_gui` or `world_3d`
- `surface_position` and `surface_normalized_position` are required
- `world_position`, `world_normal`, and `world_direction` should be populated when available

This is the critical boundary: **world-space math stays in the adapter, never in downstream button logic.**

---

## How future XR plugs in without downstream rework

XR should be added as **another adapter**, not a new consumer contract.

### Future XR adapter

Suggested name:

- `XrUiInputAdapter`

Responsibilities:
- consume XR ray/direct interactor state
- perform world-space hit testing against UI surfaces
- map hits into the same `surface_position` and `surface_normalized_position`
- emit the same phase/action model
- label source metadata as `source_type = xr`
- set `source_variant = xr_ray` or `xr_direct`
- attach truthful `verification_status`

### Why this avoids downstream churn

If the downstream repo already reacts to:
- `press_begin`
- `press_end`
- `drag_move`
- `hover_enter`
- `hover_exit`

then XR only needs to produce those same phases.

The consumer does not need to know whether activation came from:
- mouse left-click
- touch tap
- XR trigger on a laser pointer

That is the entire portability win.

---

## Event consumption model recommendation

Recommend two official consumption patterns.

### Pattern A: direct subscription

Scene/controller scripts connect directly to `AeroUiInteractionBus.interaction_event` and filter by `surface_id`, `target_path`, or a semantic region tag.

Good for:
- screen controllers
- menu coordinators
- debug overlays
- instrumentation panels

### Pattern B: composition helper component

Provide a tiny reusable consumer node later, such as:

- `AeroUiInteractionListener`
- or `AeroUiInteractable`

This helper:
- subscribes to the bus
- filters by configured target/surface
- may optionally re-emit concise local signals like `hovered`, `pressed`, `released`, `tapped`, `dragged`

Good for:
- reusable buttons/cards/sliders
- reducing repetitive filter boilerplate

Important: this remains **composition**, not inheritance.

---

## Proposed later file/module names

These are implementation suggestions only, not part of the approval ask.

### Contracts / data
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

### Optional docs/tests
- `docs/ui-interaction-contract-v1-proposal.md`
- `.testbed/tests/ui/test_ui_interaction_contract.gd`
- `.testbed/tests/ui/test_hybrid_subviewport_input_adapter.gd`

---

## Non-goals for v1

To keep the first approved contract tight, v1 should **not** promise:

- full multi-touch gesture recognition
- full drag-drop widget framework semantics
- text input abstraction
- keyboard/gamepad UI navigation abstraction in the same contract
- guaranteed XR parity before real XR validation
- inherited universal UI base classes

Those can layer on later if needed.

---

## Concrete approval checklist for Derrick

This contract is ready to approve if Derrick agrees that v1 should:

1. expose one normalized `AeroUiInteractionEvent` contract
2. use `mouse`, `touch`, and `xr` source taxonomy now
3. use one stable canonical phase model (`hover_enter`, `hover_move`, `hover_exit`, `press_begin`, `press_hold`, `drag_begin`, `drag_move`, `drag_end`, `press_end`, `cancel`)
4. attach first-class `verification_status` metadata
5. route everything through a shared `AeroUiInteractionBus`
6. keep 2D and 3D/hybrid differences inside adapters only
7. treat future XR as a new adapter, not a new downstream API
8. keep the architecture composition-first, with optional listener/interactable helpers rather than base class inheritance

---

## Bottom line

The recommended contract is:

- **one normalized pointer-style UI event surface**
- **one canonical phase field**
- **one shared dispatcher/bus**
- **multiple source/surface adapters**
- **truthful verification metadata**
- **no downstream dependence on raw mouse/touch/XR differences**

If approved, the implementation phase can build exactly that boundary in `aerobeat-input-core` and then let `aerobeat-ui-kit-community` consume it without changing downstream semantics when XR arrives later.
