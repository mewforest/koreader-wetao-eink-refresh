# Configurable Double Refresh Delay Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Release v0.2.3 with a persistent 100–3000 ms double-refresh delay setting controlled through KOReader's SpinWidget.

**Architecture:** `main.lua` reads and clamps a millisecond setting, converts it to seconds only for `UIManager:scheduleIn`, and exposes a numeric menu item beside the beta toggle. Existing page-generation cancellation and post-paint behavior remain unchanged. Plain LuaJIT tests fake `G_reader_settings`, `SpinWidget`, and scheduler boundaries.

**Tech Stack:** LuaJIT, KOReader plugin API, SpinWidget, Android JNI adapter, Bash packaging, GitHub Actions.

## Global Constraints

- Release version is exactly `0.2.3` and tag is exactly `v0.2.3`.
- Current and default delay is 500 ms.
- Allowed delay range is 100–3000 ms.
- SpinWidget step is 50 ms and hold step is 250 ms.
- The delay setting is enabled only while `Double refresh after page turn (beta)` is enabled.
- Stored values are milliseconds; `UIManager:scheduleIn` receives seconds.
- Existing user README improvements and v0.2.2 behavior must remain intact.
- Generated trial folders, `.DS_Store`, and the safety stash must not be committed.

---

### Task 1: Configurable scheduler delay

**Files:**
- Modify: `spec/run.lua`
- Modify: `wetaoeinkrefresh.koplugin/main.lua`

**Interfaces:**
- Consumes: `G_reader_settings:readSetting("wetao_double_refresh_delay_ms", 500)`.
- Produces: a clamped delay in milliseconds and `UIManager:scheduleIn(delay_ms / 1000, callback)`.

- [ ] **Step 1: Add failing scheduler tests**

Extend the fake settings object with `readSetting`. Add tests proving 500 ms schedules as 0.5 seconds, 750 ms schedules as 0.75 seconds, 50 ms clamps to 0.1 seconds, and 5000 ms clamps to 3 seconds.

- [ ] **Step 2: Run tests to verify RED**

Run: `luajit spec/run.lua`

Expected: the custom and clamp assertions fail because production still uses the constant 0.5 seconds.

- [ ] **Step 3: Implement the clamped setting reader**

Add constants for the key, default, minimum, and maximum. Read with `readSetting`, coerce with `tonumber`, fall back to 500, clamp to 100–3000, and divide by 1000 at the scheduler call only.

- [ ] **Step 4: Run tests to verify GREEN**

Run: `luajit spec/run.lua`

Expected: all scheduler and existing behavior tests pass.

### Task 2: SpinWidget menu control

**Files:**
- Modify: `spec/run.lua`
- Modify: `wetaoeinkrefresh.koplugin/main.lua`

**Interfaces:**
- Consumes: KOReader `require("ui/widget/spinwidget")` and a touch menu instance with `updateItems()`.
- Produces: menu item `wetao_double_refresh_delay` showing `Double refresh delay: N ms` and persisting `spin.value`.

- [ ] **Step 1: Add a failing menu interaction test**

Fake `SpinWidget:new`, invoke the delay menu callback, and assert the displayed default, disabled/enabled state, title, info text, value 500, bounds 100/3000, steps 50/250, unit `ms`, default 500, and persistence/update after selecting 750.

- [ ] **Step 2: Run tests to verify RED**

Run: `luajit spec/run.lua`

Expected: the test fails because `wetao_double_refresh_delay` does not exist.

- [ ] **Step 3: Add the numeric menu item**

Create a `text_func`, `enabled_func`, `keep_menu_open = true`, and callback that opens `SpinWidget`, saves the chosen integer to `wetao_double_refresh_delay_ms`, and refreshes menu labels through `touchmenu_instance:updateItems()`.

- [ ] **Step 4: Run tests to verify GREEN**

Run: `luajit spec/run.lua`

Expected: every Lua test passes with zero failures.

### Task 3: v0.2.3 documentation and metadata

**Files:**
- Modify: `README.md`
- Modify: `README_en.md`
- Modify: `VERSION`
- Modify: `wetaoeinkrefresh.koplugin/_meta.lua`
- Add: `docs/superpowers/plans/2026-07-26-configurable-double-refresh-delay.md`

**Interfaces:**
- Consumes: tested setting behavior.
- Produces: release-ready bilingual instructions and package version `0.2.3`.

- [ ] **Step 1: Update documentation and metadata**

Document the 500 ms current/default value, 100–3000 ms range, 50 ms step, and advice to increase the delay when the beta second refresh is unstable. Set `VERSION` to `0.2.3` and mention the configurable delay in plugin metadata.

- [ ] **Step 2: Run full local verification**

Run: `git diff --check`, `luajit spec/run.lua`, and `bash spec/package.sh`.

Expected: no whitespace errors; all Lua and packaging tests pass.

- [ ] **Step 3: Build and inspect the release candidate**

Run: `bash scripts/package.sh dist 0.2.3`, `unzip -t dist/wetaoeinkrefresh.koplugin-0.2.3.zip`, and verify the generated SHA-256 file from inside `dist/`.

Expected: ZIP contains the plugin directory at archive root and checksum verification passes.

### Task 4: Commit, push, tag, and release verification

**Files:**
- Commit only the intended tracked source, tests, docs, plan, and version files.

**Interfaces:**
- Consumes: verified release candidate and GitHub authentication.
- Produces: `main` commit, annotated tag `v0.2.3`, successful CI and Release workflows, and GitHub Release assets.

- [ ] **Step 1: Audit the staged release**

Confirm `.DS_Store`, `dist-test*`, `dist/`, and stash data are absent from the index. Review `git diff --cached --check` and the staged file list.

- [ ] **Step 2: Commit the release**

Commit with message `feat: add configurable double refresh delay`.

- [ ] **Step 3: Push main and verify CI**

Run `git push origin main`, identify the workflow run for the pushed commit, and wait until it succeeds before tagging.

- [ ] **Step 4: Create and push the release tag**

Create annotated tag `v0.2.3` with message `v0.2.3`, push it, and wait for the tag-triggered Release workflow.

- [ ] **Step 5: Verify published release assets**

Confirm the GitHub Release exists and contains `wetaoeinkrefresh.koplugin-0.2.3.zip` plus its `.sha256` file. Report the release URL and workflow result.
