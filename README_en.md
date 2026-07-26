# KOReader WeTao/DEXP E-Ink refresh

[Русская версия](README.md)

![DEXP/WeTao e-reader running KOReader with manga](assets/koreader-wetao-eink-refresh-hero.png)

A plugin for DEXP M8 Prudentia / **WeTao Book8** (Android 8.1) that runs a full E-Ink refresh on every page turn, and also adds **Full E-Ink refresh (WeTao/DEXP)** for manual use. Verified on-device.

## Install on Android

1. Download `wetaoeinkrefresh.koplugin-<version>.zip` from [Releases](../../releases/latest).
2. Close KOReader and extract the `wetaoeinkrefresh.koplugin` folder from the archive into `koreader/plugins` on the device.
3. The final path must be:

   ```text
   koreader/plugins/wetaoeinkrefresh.koplugin/main.lua
   ```

4. Start KOReader. The **Full E-Ink refresh (WeTao/DEXP)** item will appear in **More tools**; tap it to perform a full refresh.
5. To trigger it with a gesture, open **Touch and gestures → Gesture manager** and assign **Full E-Ink refresh (WeTao/DEXP)**.

To update, replace the `wetaoeinkrefresh.koplugin` folder and restart KOReader. To remove it, delete that folder.

## Automatic refresh after page turns

Three separate settings are available in **More tools**:

- **Refresh after page turn** performs a full E-Ink refresh after the new page is painted. It is enabled by default.
- **Double refresh after page turn (beta)** performs a second full refresh after the first. It is disabled by default.
- **Double refresh delay: 500 ms** controls the delay between the two refreshes. The current and default value is 500 ms; the available range is 100–3000 ms in 50 ms steps.

Double mode is experimental: actual E-Ink hardware refresh time can vary, so the second cycle is not always stable. If that happens, increase **Double refresh delay**. The mode is generally useful for the cleanest possible image with minimal ghosting, but it causes two screen flashes, slows page turns, and increases battery use. It affects automatic page-turn refreshes only; the manual action and assigned gesture always perform one refresh.

## Compatibility

| Device | Status |
| --- | --- |
| DEXP M8 Prudentia / WeTao Book8, Android 8.1 | Verified |
| Other WeTao / Flash firmware | Untested |

## How it works

The plugin sends the vendor-specific Android command `com.flash.force_epd_full` through KOReader's Android JNI bridge. The command was recovered from the stock `com.wetao.floatball` application.

MIT License · [4PDA device topic](https://4pda.to/forum/index.php?showtopic=1046269) · [KOReader](https://github.com/koreader/koreader)
