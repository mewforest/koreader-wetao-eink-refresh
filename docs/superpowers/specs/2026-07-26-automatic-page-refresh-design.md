# Automatic Page Refresh Design

## Goal

Add optional automatic WeTao/DEXP full-screen E-Ink refreshes after KOReader page changes, including an optional double-refresh mode for users who prioritize artifact-free rendering.

## User-visible behavior

- `Refresh after page turn` is enabled by default.
- `Double refresh after page turn` is disabled by default.
- Both settings persist globally between KOReader sessions.
- When automatic refresh is disabled, a page update sends no WeTao refresh broadcast.
- When automatic refresh is enabled and double refresh is disabled, a page update sends one broadcast.
- When both settings are enabled, a page update sends one post-paint broadcast and schedules a second broadcast 0.5 seconds later.
- The existing manual action and gesture assignment continue to send exactly one broadcast.
- The double-refresh setting affects automatic page refreshes only.
- `Double refresh delay: N ms` opens KOReader's numeric `SpinWidget` and is enabled only while double refresh is enabled.
- The delay defaults to 500 ms, accepts values from 100 through 3000 ms, changes by 50 ms per step, and changes by 250 ms on a hold action.
- The numeric control offers KOReader's standard reset-to-default action for 500 ms.

## KOReader integration

The plugin handles KOReader's `PageUpdate` event through `onPageUpdate`. The first automatic refresh preserves v0.2.1's `UIManager:tickAfterNext` behavior so it runs after the new page is painted. Double mode uses `UIManager:scheduleIn(0.5, ...)` for the second refresh. Automatic refresh is limited to an open document and ignores the close-document sentinel (`false`). The existing `WetaoEPD.send()` adapter remains the single low-level broadcast implementation.

Two separate checkable menu entries expose the automatic and double-refresh settings. A third menu entry displays the current delay and opens `ui/widget/spinwidget`. Values are stored in `G_reader_settings` under plugin-specific keys. Missing values resolve to the approved defaults: automatic refresh on, double refresh off, and a 500 ms delay.

The stored delay remains in milliseconds for a clear user-facing contract. The scheduling boundary clamps unexpected stored values to 100–3000 ms and divides the result by 1000 only when calling `UIManager:scheduleIn`.

## Error handling

Each broadcast result is checked. In double mode, the second broadcast is scheduled only if the first succeeded. The existing page-generation guard suppresses the delayed refresh if another page is requested or the document closes during the delay.

## Tests

Plain LuaJIT tests will verify:

- approved default values;
- persistence and checked state of both menu settings;
- the delay menu's displayed default, enabled state, SpinWidget bounds, steps, unit, reset value, and saved selection;
- conversion of 500 ms and a custom delay to scheduler seconds;
- clamping of unexpected stored delay values at the scheduling boundary;
- zero sends when automatic refresh is disabled;
- one send in normal automatic mode;
- a first post-paint send and a second send after exactly 0.5 seconds in double mode;
- cancellation of the delayed second send after a page change or document close;
- no send for the close-document sentinel;
- unchanged single-send behavior for the manual action;
- failure reporting without a second attempt after the first failure.

## Documentation and local trial build

Russian and English README files will explain the settings, the 500 ms default, the 100–3000 ms range, and the double mode's trade-offs: two flashes, slower page turns, and increased battery use in exchange for a cleaner image. They will recommend increasing the delay when the second refresh is unstable.

The release version is `0.2.3`. After all tests and packaging checks pass, the implementation and documentation are committed and pushed to `main`. An annotated `v0.2.3` tag is pushed only after the branch push succeeds; the existing GitHub Release workflow must then complete successfully and publish the ZIP and checksum.
