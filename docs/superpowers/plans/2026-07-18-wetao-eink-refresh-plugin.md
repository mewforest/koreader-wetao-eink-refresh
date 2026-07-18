# WeTao/DEXP Full E-Ink Refresh Plugin Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Publish an installable KOReader Android plugin that performs the WeTao full-screen E-Ink refresh by sending the vendor broadcast `com.flash.force_epd_full` directly through JNI.

**Architecture:** `wetaoepd.lua` owns the Android JNI interaction and returns a success/error tuple. `main.lua` owns KOReader integration: menu registration, Dispatcher action registration, and user-facing errors. Plain LuaJIT tests inject a fake JNI environment, while GitHub Actions validates and packages the plugin directory as a release ZIP.

**Tech Stack:** LuaJIT, KOReader KOPLugin API, Android JNI, Bash, GitHub Actions.

## Global Constraints

- The plugin directory must be named `wetaoeinkrefresh.koplugin` so KOReader discovers it.
- The visible action must be named `Full E-Ink refresh (WeTao/DEXP)` to distinguish it from KOReader's generic refresh action.
- The Android action must be exactly `com.flash.force_epd_full`, with no extras.
- The implementation must call `Context.sendBroadcast(Intent)` through KOReader's exported JNI bridge; it must not invoke `/system/bin/am`.
- Confirmed compatibility is limited to DEXP M8 Prudentia / WeTao Book8 on Android 8.1 until other devices are reported by users.
- Non-Android KOReader builds must disable the plugin cleanly.
- Release ZIPs must contain `wetaoeinkrefresh.koplugin/` at archive root.

---

### Task 1: JNI broadcast adapter

**Files:**
- Create: `spec/run.lua`
- Create: `wetaoeinkrefresh.koplugin/wetaoepd.lua`

**Interfaces:**
- Consumes: KOReader's `require("android")`, including `android.jni`, `android.app.activity.vm`, and `android.app.activity.clazz`.
- Produces: `WetaoEPD.send() -> boolean, string|nil` and `WetaoEPD.ACTION -> string`.

- [ ] **Step 1: Write failing tests**

Add tests that fake `JNIEnv` and assert the exact Intent class, constructor signature, action string, `sendBroadcast` signature, local-reference cleanup, missing-bridge error, and Java-exception handling.

- [ ] **Step 2: Verify RED**

Run: `luajit spec/run.lua`

Expected: FAIL because `wetaoeinkrefresh.koplugin/wetaoepd.lua` does not exist.

- [ ] **Step 3: Implement the minimal adapter**

The implementation must create the same Intent as the original WeTao APK:

```lua
local intent_class = env[0].FindClass(env, "android/content/Intent")
local constructor = env[0].GetMethodID(
    env,
    intent_class,
    "<init>",
    "(Ljava/lang/String;)V"
)
local action = env[0].NewStringUTF(env, "com.flash.force_epd_full")
local intent = env[0].NewObject(env, intent_class, constructor, action)
jni:callVoidMethod(
    android.app.activity.clazz,
    "sendBroadcast",
    "(Landroid/content/Intent;)V",
    intent
)
```

Check and clear pending Java exceptions, release all local references, and return diagnostic errors without crashing KOReader.

- [ ] **Step 4: Verify GREEN**

Run: `luajit spec/run.lua`

Expected: all adapter tests PASS.

- [ ] **Step 5: Commit**

```bash
git add spec/run.lua wetaoeinkrefresh.koplugin/wetaoepd.lua
git commit -m "feat: send WeTao EPD refresh broadcast through JNI"
```

### Task 2: KOReader plugin integration

**Files:**
- Modify: `spec/run.lua`
- Create: `wetaoeinkrefresh.koplugin/main.lua`
- Create: `wetaoeinkrefresh.koplugin/_meta.lua`

**Interfaces:**
- Consumes: `WetaoEPD.send()` from Task 1 and KOReader modules `device`, `dispatcher`, `gettext`, `ui/uimanager`, `ui/widget/infomessage`, and `ui/widget/container/widgetcontainer`.
- Produces: Dispatcher action `wetao_full_eink_refresh`, event handler `onWetaoFullEinkRefresh()`, and main-menu item `wetao_eink_refresh`.

- [ ] **Step 1: Write failing integration tests**

Test that the plugin disables itself outside Android, registers a general Dispatcher action titled `Full E-Ink refresh (WeTao/DEXP)`, adds a More Tools menu item, invokes `WetaoEPD.send()`, stays silent on success, and displays an `InfoMessage` on failure.

- [ ] **Step 2: Verify RED**

Run: `luajit spec/run.lua`

Expected: FAIL because `main.lua` and `_meta.lua` are missing.

- [ ] **Step 3: Implement the plugin**

Register the action with:

```lua
Dispatcher:registerAction("wetao_full_eink_refresh", {
    category = "none",
    event = "WetaoFullEinkRefresh",
    title = _("Full E-Ink refresh (WeTao/DEXP)"),
    general = true,
})
```

The menu callback and Dispatcher event must share `onWetaoFullEinkRefresh()`. Do not show a success popup because the E-Ink flash itself is the success feedback.

- [ ] **Step 4: Verify GREEN**

Run: `luajit spec/run.lua`

Expected: all adapter and plugin tests PASS.

- [ ] **Step 5: Commit**

```bash
git add spec/run.lua wetaoeinkrefresh.koplugin
git commit -m "feat: add KOReader refresh action and menu item"
```

### Task 3: Documentation and reproducible releases

**Files:**
- Create: `README.md`
- Create: `LICENSE`
- Create: `.gitignore`
- Create: `VERSION`
- Create: `scripts/package.sh`
- Create: `.github/workflows/ci.yml`
- Create: `.github/workflows/release.yml`

**Interfaces:**
- Consumes: tested plugin directory from Task 2.
- Produces: `dist/wetaoeinkrefresh.koplugin-<version>.zip` and matching `.sha256`.

- [ ] **Step 1: Add a failing packaging assertion**

Create `scripts/package.sh` initially with archive validation before packaging so the script fails while required files are absent. The archive validation must require these paths:

```text
wetaoeinkrefresh.koplugin/_meta.lua
wetaoeinkrefresh.koplugin/main.lua
wetaoeinkrefresh.koplugin/wetaoepd.lua
```

- [ ] **Step 2: Document compatibility and installation**

README must document:

- confirmed device: DEXP M8 Prudentia, reported by Google Play as WeTao Book8, Android 8.1;
- possible compatibility only for Android readers whose firmware listens for `com.flash.force_epd_full`;
- explicit non-guarantee for Kindle, Kobo, PocketBook, Onyx BOOX, and unrelated Android E-Ink devices;
- GitHub Release ZIP installation into `koreader/plugins` on Android shared storage;
- restart, plugin enablement, menu location, gesture/hardware-key assignment, update, uninstall, and troubleshooting;
- source-install instructions for users who clone/download the repository.

- [ ] **Step 3: Implement packaging and CI**

`scripts/package.sh` must create a deterministic ZIP with the plugin directory at archive root, verify its entries with `unzip -Z1`, and create a SHA-256 file. CI runs `luajit spec/run.lua` and packaging on every push/PR. Tag workflow `v*` creates a GitHub Release using `gh release create` and uploads ZIP/checksum.

- [ ] **Step 4: Verify documentation and artifacts**

Run:

```bash
luajit spec/run.lua
bash scripts/package.sh dist 0.1.0
unzip -Z1 dist/wetaoeinkrefresh.koplugin-0.1.0.zip
```

Expected: tests PASS; ZIP entries start with `wetaoeinkrefresh.koplugin/`; SHA-256 file exists.

- [ ] **Step 5: Commit**

```bash
git add README.md LICENSE .gitignore VERSION scripts .github
git commit -m "docs: add Android installation and release automation"
```

### Task 4: Public repository publication

**Files:**
- Verify all tracked files.

**Interfaces:**
- Consumes: locally verified commits and GitHub CLI authentication.
- Produces: public GitHub repository and `v0.1.0` release artifact.

- [ ] **Step 1: Run final verification**

Run:

```bash
luajit spec/run.lua
bash scripts/package.sh dist 0.1.0
git status --short
git log --oneline --decorate -5
```

Expected: tests/package PASS, clean worktree, intended commits present.

- [ ] **Step 2: Create the public repository**

After `gh auth login -h github.com` succeeds:

```bash
gh repo create koreader-wetao-eink-refresh --public --source=. --remote=origin --push
```

- [ ] **Step 3: Create the first release**

```bash
git tag -a v0.1.0 -m "v0.1.0"
git push origin v0.1.0
gh run watch
```

Expected: release workflow succeeds and publishes ZIP/checksum assets.
