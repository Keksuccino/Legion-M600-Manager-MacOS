# Verification record

Date: 2026-08-26
Host: macOS 27 beta, Apple Silicon
Toolchain: Apple Swift 6.4, Xcode 27 beta
Deployment target: macOS 26 Tahoe, Apple Silicon

## Deterministic checks

- `swift format lint`: clean.
- `swift test`: 37 tests executed, 0 failures.
- Debug app and CLI products compile.
- Release app and CLI products compile.
- App and CLI `LC_BUILD_VERSION` records both declare macOS 26.0 as `minos`.
- Packaged build 24 gives every local-profile row a native right-click menu with Rename, Duplicate,
  Change Icon, Change Color, and Delete; the redundant Edit item is absent. Invoking each appearance
  action on a different unselected profile dismissed the context menu, selected the targeted row,
  and presented the same complete toolbar popover: all 50 icons for Change Icon, and all 18 presets
  plus Custom Color for Change Color. Both popovers were closed without making a selection, and the
  app was returned to its unchanged Default profile without activating Delete or Apply.
- Row-targeted tests confirm that actions affect the profile that opened the menu rather than merely
  the selected profile. They cover duplication, selection preservation and fallback, last-profile
  deletion protection, rename, and persisted results using an inactive test transport that cannot
  communicate with the connected mouse. Separate profile-appearance tests retain catalog and color
  conversion coverage.
- Packaged build 22 reduces the centered profile-name field from 260 to 208 points, exactly 20%.
  Visual inspection confirmed the narrower field retains its native appearance, stays centered,
  and keeps balanced spacing to the independent icon and color controls.
- Packaged build 21 removes the two explicit fixed toolbar spacers around the profile-name field.
  Visual inspection confirmed the independent icon and color controls now sit immediately beside
  the unchanged native name pill with balanced, substantially smaller gaps.
- Packaged build 20 persists an optional SF Symbol and 24-bit RGB display color per local profile.
  Existing files without those fields decode to the mouse icon and Legion blue. The catalog test
  confirms exactly 50 unique, available Tahoe symbols with five entries in each internal usage
  category; the chooser intentionally renders one unlabeled grid. The separate color control
  provides 18 presets plus the native Custom Color chooser without a hex readout.
- The build-20 toolbar keeps the original native profile-name pill unchanged and places the icon
  and color controls in independent toolbar items outside it. An isolated profile store confirmed
  an icon selection updates the toolbar and sidebar immediately and survives packaged-app restarts;
  persistence and RGB conversion are also covered deterministically. The user confirmed the final
  separated layout and both pickers work. The temporary profile-store hook was removed before the
  final package was built.
- Packaged build 19 requires two Clear-button activations within a monotonic three-second window.
  An isolated profile verified the red Sure? state, automatic timeout, empty-area click
  cancellation, preservation after both cancellation paths, and deletion only after the timely
  second click. The temporary profile-store hook was removed before the final package was built.
- Packaged build 18 contains no global event-monitor API, Accessibility trust check,
  ApplicationServices linkage, or Input Monitoring usage description. Its recorder accepts only
  local events while the manager is active, with an explicit inactive-manager regression test.
  Visual inspection confirmed that the permission warning is absent from the packaged macro editor.
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
- App executable links only system frameworks/libraries (AppKit, IOKit, Foundation, Combine,
  SwiftUI, and Swift runtime libraries).

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
3adf83dde7ce247d45cadac3c387db62c9ae1e08671899b1c21ae9e209e31918  Legion M600 Manager.app/Contents/MacOS/M600 Manager
0c759527eb3e3703a071bdb0ab0a0e9996de79ea36dea65863f64ac62736fc43  m600ctl
3ec0dd7329d6a77f5a82d59885b35759e4386394939ce773832ab37cc5d73855  Legion-M600-Manager-macOS-arm64.zip
```
