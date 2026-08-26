# Verification record

Date: 2026-08-26
Host: macOS 27 beta, Apple Silicon
Toolchain: Apple Swift 6.4, Xcode 27 beta
Deployment target: macOS 26 Tahoe, Apple Silicon

## Deterministic checks

- `swift format lint`: clean.
- `swift test`: 27 tests executed, 0 failures.
- Debug app and CLI products compile.
- Release app and CLI products compile.
- App and CLI `LC_BUILD_VERSION` records both declare macOS 26.0 as `minos`.
- Packaged build 17 presents Wait, Key, and Button as compact single-row controls with plain Add
  buttons. The equal-width Wheel Up and Wheel Down buttons fill their second row with matching
  outer and middle gaps; the user visually confirmed the packaged layout.
- Packaged build 16 removes the redundant Recording heading from the macro editor's recording
  card while preserving its live state row and all capture controls.
- The packaged build was visually inspected on the Performance screen; the DPI sliders have clean
  tracks without Tahoe's dense stepped tick-mark rows.
- Packaged build 14 applies Tahoe's native open-hand pointer to all enabled DPI sliders and switches
  to the closed hand while `Slider.onEditingChanged` reports an active drag. An isolated packaged
  host dragged Stage 1 from 800 to 8100 DPI, confirming that pointer tracking does not interfere
  with value changes. Disabled stages omit the grab cursor, and system-managed splitters, scroll
  bars, and window controls retain their more specific native cursors.
- Packaged build 15 extends the same cursor behavior to each macro event's reorder surface. The
  trash button remains a separate red link-style target, recording mode suppresses row reordering,
  and an immediate `NSCursor` refresh closes the hand as soon as the row drag becomes active rather
  than waiting for SwiftUI to recalculate its cursor rect.
- The packaged toolbar retains the normal app title on the left and shows the selected profile name
  only once, in the centered editable field.
- The packaged Buttons screen was visually inspected and shows only the eight user-confirmed
  physical button labels and action controls. Internal hardware-position subtitles are absent,
  while the underlying device offsets and existing assignments remain unchanged.
- Packaged build 11 exposes `Key Press` as a nested action menu with all keys from the shared macro
  key catalog. Selecting `A` changed the row label to `Press A`; the test row was then restored to
  its original `Disabled` action with no residual key-press usage in `profiles.json`.
- Packaged build 12 replaces the inset native tab shell with a full-size borderless editor. Visual
  inspection confirmed that the old horizontal gaps and asymmetric outer border are gone while the
  centered segmented selector remains. Performance, Buttons, Lighting, and Device all opened
  successfully, and the app was left on Buttons.
- Packaged build 13 presents the macro editor as a clear event-sequence pane with grouped recording,
  wait, keyboard, and mouse controls. The unused macro-name field is absent, row delete controls
  have red hover and pointing-hand feedback, and the full view passes macOS accessibility
  inspection after replacing Tahoe's problematic native group containers.
- In an isolated packaged-app host, starting a recording and pressing `Q` while the manager stayed
  active immediately added Q down and Q up rows. Clicking the dedicated mouse surface immediately
  added a wait plus left-button down/up rows; clicking Stop added nothing. This interactive check
  neither loaded nor changed the user's saved profiles and did not apply a profile to the mouse.
- Exact codec coverage confirms that a dedicated `Press A` action programs the macro matrix and a
  34-byte body: Lenovo's 30-byte prefix followed by A down (`02 04`) and A up (`03 04`). A separate
  two-step user macro remains explicitly classified as `Macro`.
- The persisted 97-byte click-plus-`qwertz` macro is covered byte-for-byte across both 57-byte
  programming chunks, including Lenovo's recovered inter-chunk timing.
- `plutil`: packaged `Info.plist` is valid.
- `codesign --verify --deep --strict`: packaged app is valid and satisfies its ad-hoc designated requirement.
- App executable links only system frameworks/libraries (AppKit, ApplicationServices, IOKit, Foundation, Combine, SwiftUI, and Swift runtime libraries).

## Connected-device read-only check

Command: `dist/m600ctl info`

```text
Device: Lenovo Legion M600 Wireless Gaming Mouse
VID:PID: 17EF:60E5
Configuration interface: connected
Battery: 100%
Voltage: 4224 mV
Flash count: 798
2.4 GHz link: inactive
Stealth mode: off
```

Only query reports `0x0A`, `0x0B`, `0x0D`, and `0x0E` were sent during this final
read-only check. No profile, lighting, button, DPI, polling, reset, pairing, or firmware
command was sent by the diagnostic command.

## Connected-device Apply check

- A full corrected profile write completed without an IOKit error and advanced the flash
  counter from 73 to 88.
- A second write changed zone 0 from Off to Static red and advanced the counter from 88 to
  103.
- The user observed that the physical scroll wheel changed to red while the Legion logo
  stayed off. This verifies the live profile write and identifies zone 0 as the scroll wheel;
  zone 1 is the Legion logo.
- The temporary right-button UI binding test was restored to Right Click before the final
  hardware write.
- Build 3 applied the corrected right/wheel mapping with the current default actions and
  advanced the connected mouse's flash counter to 431. A non-default physical right-button
  action still requires user confirmation because automated UI input cannot press the
  mouse's physical switch.
- Build 4 queried hardware stealth state as off, then restored Lenovo's standalone `0x25`
  lighting activation after the verified full-profile commit.
- A first build-4 application advanced the counter from 506 to 522. The build containing the
  finalized write sequence, with a pre-commit query that isolates `0x05`, advanced it from
  522 to 538.
  Each 16-count change is exactly 14 staged profile/button reports, one accepted commit,
  and one accepted lighting report.
- The live application reported `Applied profile and lighting · flash #538` for the unchanged
  selected breathing profile.
- The packaged build then added serialization between status reads and mutations, was restarted,
  and completed the final read-only device check at flash count 538.
- Build 10 applied the unchanged selected profile with the corrected multi-chunk macro pacing and
  reported `Applied profile and lighting · flash #686`. A subsequent read-only CLI query confirmed
  the same counter. The user then confirmed that pressing the physical Top Button executed the
  complete click-plus-`qwertz` macro, including the second chunk's `ertz` events.
- Build 11's dedicated key-press action was verified locally and in the packaged UI without
  clicking Apply, so this verification sent no profile or button mutation to the mouse.
- No factory reset, firmware update, or receiver-pairing command was sent.

## Release hashes

These hashes are also recorded in `dist/SHA256SUMS`.

```text
ebf30b152da6fcd9c38baa01135e222aea4ab3d857649115d31e826891c3afc8  Legion M600 Manager.app/Contents/MacOS/M600 Manager
60c63b7ac654faeb83e01c940993d76443cfddec83498d5e896a21a7d3b133ba  m600ctl
d0e6fd476931ddd8b21f4dbfa3f8504b2d7f103bdab6959576fb615a50b85b71  Legion-M600-Manager-macOS-arm64.zip
```
