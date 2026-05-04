# aerobeat-input-core

Shared AeroBeat input abstractions, gameplay-intent contracts, and runtime coordination for the camera-first v1 product slice.

## Repo stance

AeroBeat v1 gameplay is officially **camera-first**.

This repo keeps the broader input abstraction surface so downstream packages can stay future-friendly, but the current product truth is narrower:

- **Official v1 gameplay path:** camera providers
- **Official v1 gameplay contract:** gameplay-facing intent signals, not raw pose streams
- **Supported UI/navigation inputs:** mouse on desktop and touch on mobile
- **Future / experimental / deprioritized gameplay paths:** XR, controllers, keyboard, haptics, and other non-camera providers
- **Optional advanced capability surface:** lower-body tracking, richer 3D transforms, haptics, and other provider-specific extensions remain available in the contracts, but they are not required for v1 gameplay parity

In other words: this package preserves shared contracts for future expansion without implying that every provider type is an equal-status AeroBeat v1 gameplay target today.

## Official v1 gameplay-facing contract

The main design boundary in this repo is deliberate:

- **Gameplay code consumes intents** like punches, guard, squat, lean, sidestep, and flow slices.
- **Providers may still expose observation data** like transforms, positions, confidence, velocity, or other richer signals.
- **Raw pose / observation data stays provider-side and optional.** It is useful for detectors, debugging, and future features, but it is not the primary gameplay contract for v1.

That split is what later MediaPipe detector work should emit into: stable gameplay intents first, optional observation data second.

### Boxing v1 surface

The v1 Boxing contract is intentionally authored around readable gameplay intents:

- Straight punches are `punch_left` and `punch_right`
- Hooks remain `hook_left` and `hook_right`
- Uppercuts remain `uppercut_left` and `uppercut_right`
- Defensive wording is `guard_start` / `guard_end`
- State-like motion intents use start/end pairs:
  - `squat_start` / `squat_end`
  - `lean_left_start` / `lean_left_end`
  - `lean_right_start` / `lean_right_end`
  - `sidestep_left_start` / `sidestep_left_end`
  - `sidestep_right_start` / `sidestep_right_end`
- Optional lower-body extension hooks remain separate and obviously optional:
  - `knee_left` / `knee_right`
  - `leg_lift_left_start` / `leg_lift_left_end`
  - `leg_lift_right_start` / `leg_lift_right_end`

Not part of the v1 provider contract:

- `jab` / `cross` naming for straight punches
- tracked `orthodox` / `southpaw` events
- `run_in_place` provider events in the first implementation pass, even though `run_in_place` remains a legitimate chart/gameplay beat

### Flow v1 surface

Flow detectors should emit concrete gameplay-facing motion families rather than one overly generic slice event.

The approved v1 provider-facing Flow families are:

- `swing_left(placement, direction)`
- `swing_right(placement, direction)`
- `trail_left(placement, direction)`
- `trail_right(placement, direction)`

For each family:

- `placement`: the authored **pass-through location**
- `direction`: the authored **follow-through guidance**

These are different semantics and must not be blurred.

Typical authored examples:

- `placement`: `left`, `center`, `right`
- `direction`: `left`, `right`, `up`, `down`

Authored `warn_*` / `reward_*` semantics stay above the provider layer in this first pass rather than becoming distinct detector events. `run_in_place` is also a legitimate authored Flow beat, but remains informational only and is not a tracked provider event in this first pass.

Flow also shares the same state-like movement style for obstacle/body intents:

- `squat_start` / `squat_end`
- `lean_left_start` / `lean_left_end`
- `lean_right_start` / `lean_right_end`
- `sidestep_left_start` / `sidestep_left_end`
- `sidestep_right_start` / `sidestep_right_end`

## What's in this repo

- `AeroInputProvider` base contract for normalized provider lifecycle, optional capability reporting, and optional observation/spatial queries
- `FlowInput` contract for camera-first Flow gameplay intents
- `BoxingInput` contract for camera-first Boxing gameplay intents
- `InputManager` runtime coordinator that prefers camera providers as the official default path and proxies the gameplay-facing intent surface
- Hidden `.testbed/` Godot workbench for manual inspection and GUT-based validation

## GodotEnv development flow

This repo uses the AeroBeat Phase 1 GodotEnv package/foundation convention.

- Canonical dev/test manifest: `.testbed/addons.jsonc`
- Installed dev/test addons: `.testbed/addons/`
- GodotEnv cache: `.testbed/.addons/`
- Hidden workbench project: `.testbed/project.godot`

### Restore dev/test dependencies

From the repo root:

```bash
cd .testbed
godotenv addons install
```

That installs test-only dependencies declared in `.testbed/addons.jsonc` into `.testbed/addons/`.

### Open the testbed

From the repo root:

```bash
godot --editor --path .testbed
```

The testbed uses tracked relative links so the hidden workbench can see the repo's real `src/` content plus `.testbed/tests/` and `.testbed/scenes/` without a legacy setup script.

### Validation notes

- The repo's GUT dependency is declared in `.testbed/addons.jsonc` and points at the repo's `/addons/gut` package subfolder.
- Repo-local unit tests live under `.testbed/tests/`, while the manual workbench scene content lives under `.testbed/scenes/`.
- Downstream repos should consume tagged releases of `aerobeat-input-core` in `tag` mode.
- Validation should keep the camera-first, intent-first v1 framing intact while ensuring future-facing non-camera abstractions remain explicitly optional.
