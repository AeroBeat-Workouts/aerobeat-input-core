# AeroBeat Input Core Bump plugin.cfg Version and Refresh Consumer Pin

**Date:** 2026-04-24  
**Status:** In Progress  
**Agent:** Pico 🐱‍🏍

---

## Goal

Update `aerobeat-input-core/plugin.cfg` so its internal version matches the released tag, then refresh the assembly consumer pin to install that corrected release.

---

## Overview

The prior release refresh fixed the installed naming/branding drift by tagging `v0.1.1` and updating the assembly consumer to pin that tag. One small mismatch remains: the released `plugin.cfg` still reports `version="0.1.0"` even when the consumer is installing release tag `v0.1.1`.

This pass should stay narrow. We are not reopening broader runtime or naming work. The truthful fix is to bump the source `plugin.cfg` version to match the release, cut a new tag, update the assembly consumer pin, reinstall the addon, and verify the installed payload now reports the corrected internal version.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Current source plugin metadata | `plugin.cfg` |
| `REF-02` | Current release/consumer cleanup plan | `.plans/2026-04-24-refresh-input-core-release-identity-and-consumer-pin.md` |
| `REF-03` | Current assembly consumer pin | `../aerobeat-assembly-community/addons.jsonc` |
| `REF-04` | Current installed payload in assembly | `../aerobeat-assembly-community/addons/aerobeat-input-core/plugin.cfg` |

---

## Tasks

### Task 1: Audit current source/release/plugin version mismatch

**Bead ID:** `oc-bl3`  
**SubAgent:** `primary`  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`  
**Prompt:** Confirm the exact plugin version mismatch between current source, current tag, and installed consumer payload, then propose the smallest truthful fix. Do not implement yet.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- `.plans/2026-04-24-bump-plugin-cfg-version-and-refresh-consumer-pin.md`

**Status:** ✅ Complete

**Results:** Confirmed the mismatch is not between source `main` and the tagged payload contents; it is between the released tag / consumer pin and the plugin-internal version string. Current source `plugin.cfg` on `main` still reads `version="0.1.0"` (`REF-01`). Released tag `v0.1.1` also contains the same exact `plugin.cfg` payload with `version="0.1.0"` (`git show v0.1.1:plugin.cfg`; context from `REF-02`). The assembly consumer is pinned to `"checkout": "v0.1.1"` in `../aerobeat-assembly-community/addons.jsonc` (`REF-03`), and the installed payload at `../aerobeat-assembly-community/addons/aerobeat-input-core/plugin.cfg` likewise still reads `version="0.1.0"` (`REF-04`). Exact drift: release tag / consumer pin say `v0.1.1`, while source `main`, tagged payload, and installed payload all still self-report plugin version `0.1.0`. Smallest truthful fix: change only `plugin.cfg` version to `0.1.2`, create/push tag `v0.1.2`, then repin the assembly consumer to `v0.1.2` and reinstall. Do not rewrite `v0.1.1`; it already exists, so skipping to `0.1.2` keeps tag history and plugin metadata aligned truthfully. No source change beyond `plugin.cfg` is needed for this fix.

---

### Task 2: Bump plugin.cfg version, tag, repin consumer, and reinstall

**Bead ID:** `oc-ngn`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`  
**Prompt:** Implement the smallest truthful fix: update `plugin.cfg` version to the next release, create/push the new tag, update the assembly consumer pin, reinstall the addon there, and record exact validation evidence. Keep scope tight.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `../aerobeat-assembly-community/addons/`

**Files Created/Deleted/Modified:**
- `plugin.cfg`
- `../aerobeat-assembly-community/addons.jsonc`
- `.plans/2026-04-24-bump-plugin-cfg-version-and-refresh-consumer-pin.md`
- `../aerobeat-assembly-community/.plans/2026-04-24-rename-assembly-core-addon-key-to-aerobeat-input-core.md`

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 3: QA/audit the refreshed installed plugin version in the assembly consumer

**Bead ID:** `oc-76k`  
**SubAgent:** `primary`  
**Role:** `qa` / `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`  
**Prompt:** Independently verify that the assembly consumer now installs the refreshed release and that the installed `plugin.cfg` version matches the pinned tag truthfully. Close only if the evidence supports it.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- `.plans/2026-04-24-bump-plugin-cfg-version-and-refresh-consumer-pin.md`

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
