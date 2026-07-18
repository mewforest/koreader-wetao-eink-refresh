# KOReader WeTao/DEXP E-Ink refresh

[Русская версия](README.md)

![DEXP/WeTao e-reader running KOReader with manga](assets/koreader-wetao-eink-refresh-hero.png)

A plugin for DEXP M8 Prudentia / **WeTao Book8** (Android 8.1) that adds **Full E-Ink refresh (WeTao/DEXP)**. Verified on-device.

## Install on Android

1. Download `wetaoeinkrefresh.koplugin-<version>.zip` from [Releases](../../releases/latest).
2. Close KOReader and extract the ZIP into `koreader/plugins` on the device.
3. The final path must be:

   ```text
   koreader/plugins/wetaoeinkrefresh.koplugin/main.lua
   ```

4. Start KOReader and enable **WeTao/DEXP E-Ink refresh** in **Tools → Plugin management → User plugins**.
5. Use **Full E-Ink refresh (WeTao/DEXP)** from the tools menu, or assign it to a gesture / hotkey.

To update, replace the `wetaoeinkrefresh.koplugin` folder and restart KOReader. To remove it, delete that folder.

## Compatibility

| Device | Status |
| --- | --- |
| DEXP M8 Prudentia / WeTao Book8, Android 8.1 | Verified |
| Other WeTao / Flash firmware | Untested |

## How it works

The plugin sends the vendor-specific Android broadcast `com.flash.force_epd_full` through KOReader's Android JNI bridge. The action was recovered from the stock `com.wetao.floatball` application.

MIT License · [4PDA device topic](https://4pda.to/forum/index.php?showtopic=1046269) · [KOReader](https://github.com/koreader/koreader)
