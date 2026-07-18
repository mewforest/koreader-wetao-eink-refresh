# KOReader WeTao/DEXP E-Ink refresh

Внешний плагин KOReader для полного обновления E-Ink-экрана на DEXP M8 Prudentia / WeTao Book8. Он добавляет отдельное действие:

> **Full E-Ink refresh (WeTao/DEXP)**

Плагин не заменяет штатное действие KOReader **Full E-Ink refresh**. Он напрямую повторяет механизм заводского приложения `com.wetao.floatball`: создаёт Android `Intent` с action `com.flash.force_epd_full` и вызывает `Activity.sendBroadcast()` через JNI-мост KOReader.

Root, ADB и отдельный APK не нужны.

## Совместимость

| Устройство / прошивка | Статус |
| --- | --- |
| DEXP M8 Prudentia, Android 8.1; в Google Play определяется как **WeTao Book8** | Целевая модель. Команда подтверждена декомпиляцией заводского FloatBall APK; сам плагин ожидает первой проверки на устройстве. |
| Другие WeTao / Flash-совместимые Android-читалки | Может работать, только если прошивка обрабатывает broadcast `com.flash.force_epd_full`. |
| Kindle, Kobo, PocketBook, reMarkable, Onyx Boox и обычные Android-устройства | Поддержка не заявлена. У них другие E-Ink API или вообще нет E-Ink-контроллера. |

Плагин автоматически отключается не на Android. Наличие Android само по себе не означает совместимость: нужный broadcast является нестандартной частью конкретной прошивки.

## Установка на Android из GitHub Releases

1. Откройте страницу **Releases** этого репозитория и скачайте `wetaoeinkrefresh.koplugin-<версия>.zip` из последнего релиза. Файл `.sha256` рядом позволяет проверить целостность архива.
2. Полностью закройте KOReader.
3. Распакуйте ZIP в папку `koreader/plugins` во внутренней памяти читалки.
4. Проверьте итоговый путь. Он должен выглядеть так:

   ```text
   koreader/
   └── plugins/
       └── wetaoeinkrefresh.koplugin/
           ├── _meta.lua
           ├── main.lua
           └── wetaoepd.lua
   ```

   Частая ошибка — лишний уровень каталога вроде `plugins/repository-main/wetaoeinkrefresh.koplugin`.
5. Запустите KOReader. Откройте **Tools → Plugin management → User plugins** и убедитесь, что **WeTao/DEXP E-Ink refresh** включён. После изменения состояния перезапустите KOReader.
6. В меню инструментов выберите **Full E-Ink refresh (WeTao/DEXP)**. Экран должен выполнить полный цикл с характерным миганием.

Официальная коллекция сторонних плагинов KOReader также устанавливает плагины копированием папки `.koplugin` в `koreader/plugins`.

### Установка прямо из исходников

Скачайте репозиторий через **Code → Download ZIP**, распакуйте его и скопируйте только папку `wetaoeinkrefresh.koplugin` в `koreader/plugins`. Файлы репозитория `README.md`, `spec`, `scripts` и `.github` на устройство копировать не требуется.

### Обновление и удаление

- Для обновления замените существующую папку `wetaoeinkrefresh.koplugin` содержимым новой версии и перезапустите KOReader.
- Для удаления закройте KOReader, удалите `koreader/plugins/wetaoeinkrefresh.koplugin` и снова запустите KOReader.

## Назначение на жест или аппаратную кнопку

Плагин регистрирует действие в общем Dispatcher KOReader с идентификатором `wetao_full_eink_refresh`. Поэтому его можно выбрать в менеджере жестов/горячих клавиш как **Full E-Ink refresh (WeTao/DEXP)**. Точное расположение настройки зависит от версии KOReader и активных плагинов **Gestures** / **Hotkeys**.

Для перехвата клавиш громкости во всех Android-приложениях этот плагин не подходит: он работает только пока открыт KOReader. Глобальная кнопка потребует отдельного Android-приложения или системной службы.

## Если экран не моргает

1. Убедитесь, что выбран пункт с пометкой **(WeTao/DEXP)**, а не штатный **Full E-Ink refresh**.
2. Проверьте, что папка лежит непосредственно в `koreader/plugins` и плагин включён.
3. Если появилось сообщение `Android rejected ...`, прошивка запретила broadcast процессу KOReader. Приложите к issue версию KOReader и файл `koreader/crash.log`; при возможности полезен и `adb logcat` за момент нажатия.
4. Если сообщения нет, но экран не меняется, broadcast был отправлен, однако прошивка его не обработала. Это может означать другую action-команду либо проверку отправителя/системной подписи.

Сбой `/system/bin/am broadcast ...` с кодом 225 не доказывает, что JNI-вариант тоже не сработает: `am` обращается к Activity Manager через отдельный shell-путь, тогда как плагин вызывает Android API из Activity KOReader.

## Разработка

Требуются LuaJIT, `zip` и `unzip`:

```sh
luajit spec/run.lua
bash spec/package.sh
bash scripts/package.sh
```

Каждый push и pull request запускает эти проверки в GitHub Actions. Push тега вида `v0.1.0` собирает ZIP и SHA-256 и публикует их в GitHub Release.

## English summary

This external KOReader plugin adds **Full E-Ink refresh (WeTao/DEXP)**. It targets the DEXP M8 Prudentia, reported by Google Play as WeTao Book8, running Android 8.1. The plugin sends the vendor-specific `com.flash.force_epd_full` broadcast directly through KOReader's Android JNI bridge. Extract the release ZIP into `koreader/plugins`, restart KOReader, enable the user plugin, and invoke the new action. Other devices are supported only if their firmware implements the same vendor broadcast.

## Источники и лицензия

- [Обсуждение DEXP M8 Prudentia на 4PDA](https://4pda.to/forum/index.php?showtopic=1046269)
- [KOReader](https://github.com/koreader/koreader)
- [Коллекция сторонних плагинов KOReader](https://github.com/koreader/contrib)
- [Android LuaJIT launcher KOReader](https://github.com/koreader/android-luajit-launcher)

Код распространяется по лицензии MIT. См. [LICENSE](LICENSE).
