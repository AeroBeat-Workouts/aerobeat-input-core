# aerobeat-core

Shared AeroBeat foundation addon for core contracts, interfaces, enums, constants, and low-level utilities.

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
- Repo-local unit tests now live under `.testbed/tests/`, while the manual workbench scene content lives under `.testbed/scenes/`.
- Downstream repos should consume tagged releases of `aerobeat-core` in `tag` mode.
