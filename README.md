# aerobeat-input-core

Shared AeroBeat input abstractions, provider contracts, and runtime coordination for the camera-first v1 product slice.

## Repo stance

AeroBeat v1 gameplay is officially **camera-first**.

This repo keeps the broader input abstraction surface so downstream packages can stay future-friendly, but the current product truth is narrower:

- **Official v1 gameplay path:** camera providers
- **Supported UI/navigation inputs:** mouse on desktop and touch on mobile
- **Future / experimental / deprioritized gameplay paths:** XR, controllers, keyboard, haptics, and other non-camera providers
- **Optional advanced capability surface:** lower-body tracking, 6DOF transforms, haptics, and other provider-specific extensions remain available in the contracts, but they are not required for v1 gameplay parity

In other words: this package preserves shared contracts for future expansion without implying that every provider type is an equal-status AeroBeat v1 gameplay target today.

## What's in this repo

- `AeroInputProvider` base contract for normalized provider lifecycle, capability reporting, and spatial queries
- `FlowInput` contract for camera-first Flow gameplay signals, with room for future provider-specific gesture interpretation
- `BoxingInput` contract for camera-first Boxing gameplay signals, with optional future-facing lower-body and advanced motion hooks
- `InputManager` runtime coordinator that prefers camera providers as the official default path
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
- Validation should keep the camera-first v1 framing intact while ensuring future-facing non-camera abstractions remain explicitly optional.
