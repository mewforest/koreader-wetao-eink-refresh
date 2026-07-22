# KOReader WeTao/DEXP E-Ink refresh

[English version](README_en.md)

![DEXP/WeTao e-reader running KOReader with manga](assets/koreader-wetao-eink-refresh-hero.png)

Плагин для DEXP M8 Prudentia / **WeTao Book8** (Android 8.1): автоматически делает полное обновление E-Ink при каждом перелистывании страницы и добавляет действие **Full E-Ink refresh (WeTao/DEXP)** для ручного вызова. Проверен на устройстве.

## Установка на Android

1. Скачайте `wetaoeinkrefresh.koplugin-<версия>.zip` из [Releases](../../releases/latest).
2. Закройте KOReader и распакуйте ZIP в `koreader/plugins` на устройстве.
3. Итоговый путь должен быть таким:

   ```text
   koreader/plugins/wetaoeinkrefresh.koplugin/main.lua
   ```

4. Запустите KOReader и включите **WeTao/DEXP E-Ink refresh** в **Tools → Plugin management → User plugins**.
5. Используйте **Full E-Ink refresh (WeTao/DEXP)** в меню инструментов или назначьте действие на жест / горячую клавишу.

Для обновления замените папку `wetaoeinkrefresh.koplugin` и перезапустите KOReader. Для удаления — удалите эту папку.

## Совместимость

| Устройство | Статус |
| --- | --- |
| DEXP M8 Prudentia / WeTao Book8, Android 8.1 | Проверено |
| Другие прошивки WeTao / Flash | Не проверено |

## Как работает

Плагин отправляет фирменный Android broadcast `com.flash.force_epd_full` через JNI-мост KOReader. Команда была найдена в заводском приложении `com.wetao.floatball`.

MIT License · [Тема устройства на 4PDA](https://4pda.to/forum/index.php?showtopic=1046269) · [KOReader](https://github.com/koreader/koreader)
