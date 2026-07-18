# KOReader WeTao/DEXP E-Ink refresh

![DEXP/WeTao e-reader running KOReader with manga](assets/koreader-wetao-eink-refresh-hero.png)

**RU** — Плагин для DEXP M8 Prudentia / **WeTao Book8** (Android 8.1), добавляющий действие **Full E-Ink refresh (WeTao/DEXP)**. Проверен на устройстве.

Это **не** замена встроенного действия KOReader *Full E-Ink refresh*, **не** глобальная кнопка обновления для всех Android-приложений и **не** плагин для Kindle, Kobo, Boox или других читалок.

**EN** — A plugin for DEXP M8 Prudentia / **WeTao Book8** (Android 8.1) that adds **Full E-Ink refresh (WeTao/DEXP)**. Verified on-device.

It does **not** replace KOReader's built-in *Full E-Ink refresh*, provide a global refresh button for all Android apps, or support Kindle, Kobo, Boox, and other e-readers.

## Install on Android / Установка на Android

1. Download / Скачайте `wetaoeinkrefresh.koplugin-<version>.zip` from [Releases](../../releases/latest).
2. Close KOReader and extract the ZIP into `koreader/plugins` on the device. / Закройте KOReader и распакуйте ZIP в `koreader/plugins` на устройстве.
3. The final path / Итоговый путь:

   ```text
   koreader/plugins/wetaoeinkrefresh.koplugin/main.lua
   ```

4. Start KOReader and enable **WeTao/DEXP E-Ink refresh** in **Tools → Plugin management → User plugins**. / Запустите KOReader и включите плагин в этом меню.
5. Use **Full E-Ink refresh (WeTao/DEXP)** from the tools menu, or assign it to a gesture / hotkey. / Используйте пункт меню или назначьте действие на жест / горячую клавишу.

To update, replace the `wetaoeinkrefresh.koplugin` folder and restart KOReader. To remove it, delete that folder. / Для обновления замените эту папку и перезапустите KOReader; для удаления — удалите её.

## Compatibility / Совместимость

| Device | Status |
| --- | --- |
| DEXP M8 Prudentia / WeTao Book8, Android 8.1 | Verified / Проверено |
| Other WeTao / Flash firmware | Untested / Не проверено |

## How it works / Как работает

The plugin sends the vendor-specific Android broadcast `com.flash.force_epd_full` through KOReader's Android JNI bridge. The action was recovered from the stock `com.wetao.floatball` application.

Плагин отправляет фирменный Android broadcast `com.flash.force_epd_full` через JNI-мост KOReader. Команда была найдена в заводском приложении `com.wetao.floatball`.

MIT License · [4PDA device topic](https://4pda.to/forum/index.php?showtopic=1046269) · [KOReader](https://github.com/koreader/koreader)
