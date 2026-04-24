# AeroBeat Input Core Release Identity Refresh and Consumer Pin Update

**Date:** 2026-04-24  
**Status:** In Progress  
**Agent:** Pico 🐱‍🏍

---

## Goal

Refresh the released identity of `aerobeat-input-core` so tagged consumers no longer install old `aerobeat-core` branding, then update the assembly consumer to pin the corrected release.

---

## Overview

The recent assembly rename pass revealed that the generated addon payload under `addons/aerobeat-input-core/` still shows old-name branding like `# aerobeat-core` and `AeroBeat Core`. The source repo on `main` is already corrected — `README.md` and `plugin.cfg` now say `aerobeat-input-core` / `AeroBeat Input Core`. The mismatch exists because the assembly currently pins tag `v0.1.0`, and that tag still points to an older commit created before the input-core identity refresh landed.

So the cleanup we identified is really a release-consumer mismatch, not just a local docs typo. The truthful fix is: audit the release drift, cut a new tagged release from the corrected `aerobeat-input-core` state, update the assembly consumer to pin that new tag, regenerate addons, and verify the installed payload branding now matches reality.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Current `aerobeat-input-core` source identity on `main` | `README.md`, `plugin.cfg` |
| `REF-02` | Current installed payload in assembly showing old-name branding | `../aerobeat-assembly-community/addons/aerobeat-input-core/README.md`, `../aerobeat-assembly-community/addons/aerobeat-input-core/plugin.cfg` |
| `REF-03` | Current pinned release in assembly manifest | `../aerobeat-assembly-community/addons.jsonc` |
| `REF-04` | Current tag history in `aerobeat-input-core` | git tag / git log |
| `REF-05` | Recent assembly rename plan that identified this as upstream identity drift | `../aerobeat-assembly-community/.plans/2026-04-24-rename-assembly-core-addon-key-to-aerobeat-input-core.md` |

---

## Tasks

### Task 1: Audit release/tag identity drift between source repo and tagged consumer payload

**Bead ID:** `oc-jd6`  
**SubAgent:** `primary`  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Confirm exactly why tagged consumers still install old `aerobeat-core` branding even though `aerobeat-input-core` main is already updated. Compare current source files, the pinned tag, and the installed assembly payload, then propose the smallest truthful fix. Do not implement yet.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- `.plans/2026-04-24-refresh-input-core-release-identity-and-consumer-pin.md`

**Status:** ✅ Complete

**Results:** Confirmed exact release drift. `README.md` on `main` now starts with `# aerobeat-input-core` and `plugin.cfg` now uses `name="AeroBeat Input Core"` / `description="Shared input abstractions and provider contracts for the AeroBeat ecosystem"` (`REF-01`). The assembly consumer is still pinned to `"checkout": "v0.1.0"` in `../aerobeat-assembly-community/addons.jsonc` (`REF-03`). Tag `v0.1.0` resolves to commit `04a396d8fd5778feb939e9bed7dfcfb1a8895cb1`, which predates the identity refresh and still ships `# aerobeat-core`, `AeroBeat Core`, and the old core-focused description in both `README.md` and `plugin.cfg` (`REF-04`). A direct diff between `git show v0.1.0:README.md` / `plugin.cfg` and the installed assembly payload under `../aerobeat-assembly-community/addons/aerobeat-input-core/` was empty, confirming the installed branding drift is coming from the pinned tag payload, not from a separate assembly-side mutation (`REF-02`, `REF-03`, `REF-04`). The identity refresh already landed on source `main` in commit `fe859a9` (`Align input core identity with lane architecture`), and current source does not need another branding fix before release. Smallest truthful next step: cut a new tag from current `main` (or the exact corrected commit to release), then update the assembly consumer from `v0.1.0` to that new tag and reinstall/regenerate so the installed addon payload matches current source branding.

---

### Task 2: Cut a corrected `aerobeat-input-core` release and update the assembly pin

**Bead ID:** `oc-gt6`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Create the smallest truthful release-consumer fix: tag the corrected `aerobeat-input-core` state with a new release tag, push it, update the assembly consumer to pin that new tag, regenerate addons, and record exact evidence. Keep scope tight.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `../aerobeat-assembly-community/addons/`

**Files Created/Deleted/Modified:**
- release/tag metadata as needed
- `../aerobeat-assembly-community/addons.jsonc`
- `../aerobeat-assembly-community/.plans/2026-04-24-rename-assembly-core-addon-key-to-aerobeat-input-core.md`
- `.plans/2026-04-24-refresh-input-core-release-identity-and-consumer-pin.md`

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 3: QA/audit the refreshed installed payload branding in the assembly consumer

**Bead ID:** `oc-hl1`  
**SubAgent:** `primary`  
**Role:** `qa` / `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Independently verify that the assembly consumer now installs the refreshed `aerobeat-input-core` release, that the installed README/plugin branding matches reality, and that the project still imports cleanly. Close only if the evidence supports it.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- `.plans/2026-04-24-refresh-input-core-release-identity-and-consumer-pin.md`

**Status:** ⏳ Pending

**Results:** Pending.

---

## Final Results

**Status:** ⏳ Pending

**What We Built:** Pending.

**Reference Check:** Pending.

**Commits:**
- Pending

**Lessons Learned:** Pending.

---

*Completed on Pending*
