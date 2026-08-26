# Milestones

## 2026-08-26 — Narrower profile-name field

- Reduced the centered profile-name field from 260 to 208 points while preserving its native
  styling and the placement of the adjacent appearance controls.
- Released the width refinement as version 0.1.21 (build 22).

## 2026-08-26 — Tighter profile appearance controls

- Moved the profile icon and color controls closer to the centered name field by removing the two
  additional fixed toolbar spacers while preserving all three controls as independent items.
- Released the spacing refinement as version 0.1.20 (build 21).

## 2026-08-26 — Custom profile icons and colors

- Added persistent local icon and RGB color metadata to every profile with backward-compatible
  defaults for existing saved profiles.
- Preserved the centered profile-name field's original native pill and placed compact, independent
  icon and color controls outside it; the selected appearance also renders in the sidebar.
- Presented the 50 symbols as an uncluttered grid and provided a compact 18-color palette plus the
  native custom-color chooser.
- Curated 50 Tahoe SF Symbols across ten usage categories and added availability, uniqueness,
  category-size, color-conversion, persistence, and legacy-decoding coverage.
- Released the feature as version 0.1.19 (build 20).

## 2026-08-26 — Timed Clear confirmation

- Changed the macro editor's destructive Clear action into a two-click confirmation: the first
  click presents a red Sure? button and only a second click within three seconds clears events.
- Added outside-click cancellation and automatic timeout restoration without affecting the macro.
- Used a monotonic deadline so an expired confirmation can never clear data even if its UI timer is
  scheduled late.
- Added deterministic confirmation, cancellation, boundary, and expiration coverage.
- Released the behavior as version 0.1.18 (build 19).

## 2026-08-26 — App-only macro recording

- Removed global event monitoring and the Accessibility trust check so macros can be recorded only
  while the manager is active, regardless of previously granted privacy permissions.
- Added an active-app guard for explicitly delivered capture events and regression coverage for the
  inactive-manager path.
- Removed the permission warning, Input Monitoring usage description, and ApplicationServices
  linkage.
- Released the behavior as version 0.1.17 (build 18).

## 2026-08-26 — Compact manual macro controls

- Consolidated each Wait, Key, and Button action into a single title, chooser, and Add row.
- Removed the redundant Duration, Key, and Button field captions plus the Add-button icons.
- Made the two wheel buttons equal-width and full-row, with matching outer and middle gaps.
- Released the layout as version 0.1.16 (build 17).

## 2026-08-26 — Recording card title cleanup

- Removed the redundant Recording heading and icon from the macro editor's recording card.
- Kept the live Ready/Recording state, event count, permission guidance, and recording controls
  unchanged.
- Released the cleanup as version 0.1.15 (build 16).

## 2026-08-26 — Native grab cursors

- Added one reusable Tahoe pointer modifier that shows an open hand over custom draggable controls
  and a closed hand while their drag is active.
- Applied the modifier to every DPI slider and macro event reorder surface, while suppressing it
  for disabled stages and during macro recording.
- Added an immediate native cursor refresh for active drags so the hand closes while the mouse
  button remains held instead of waiting for SwiftUI to refresh the cursor rect.
- Kept native resize/scroll cursors on system-managed surfaces and native link cursors on macro
  trash buttons.
- Verified a real packaged slider drag in a disposable host without loading saved profiles or
  applying anything to the mouse.
- Released the completed cursor behavior as version 0.1.14 (build 15) with all 27 tests passing.

## 2026-08-26 — Professional live macro editor

- Reorganized the macro editor into a full event-sequence workspace plus grouped recording and
  manual-action controls, and removed the unused macro-name field.
- Added immediate list synchronization and automatic following while recording.
- Added a local keyboard monitor and explicit mouse capture surface so recording works inside the
  active manager without allowing Stop, Done, or other control clicks into the macro.
- Added red hover feedback plus a pointing-hand cursor to row trash controls.
- Replaced Tahoe's accessibility-breaking native group containers with reusable custom cards.
- Added three focused recorder tests, bringing the deterministic suite to 27 passing tests.
- Visually and interactively verified build 13 in an isolated host without altering saved profiles
  or applying anything to the connected mouse.

## 2026-08-26 — Borderless full-size editor

- Replaced SwiftUI's native bordered `TabView` shell with a full-size editor container and a
  centered segmented section picker.
- Removed the 18-point horizontal inset plus the native left, right, bottom, and heavier top
  borders while preserving the existing configuration screens and bindings.
- Visually inspected the packaged Buttons layout and opened all four editor sections to confirm
  the replacement navigation works.
- Released the change as version 0.1.11 (build 12) with all 24 tests passing.

## 2026-08-26 — Dedicated key-press button action

- Added a nested `Key Press` menu using the macro editor's shared HID-key catalog and displayed
  selections as `Press <key name>` in each button row.
- Persisted key presses explicitly rather than inferring them from two-step macros, so a user-made
  key-down/key-up macro remains a macro and retains its name and editability.
- Compiled key presses to the existing M600 macro protocol without duplicating or replacing the
  binding's editable macro definition.
- Added validation, exact protocol encoding, intent-preservation, and persistence coverage,
  bringing the deterministic suite to 24 tests.
- Visually verified `Key Press → A` and the resulting `Press A` label in packaged build 11, then
  restored the temporary local test assignment without applying it to the mouse.

## 2026-08-26 — Multi-chunk macro pacing

- Reproduced the user's click-plus-`qwertz` macro as a 97-byte body split across two 57-byte
  programming chunks; the observed click-plus-`qw` cutoff aligned exactly with chunk one.
- Restored Lenovo's native 50 ms guards around the existing 100 ms HID delay so consecutive
  `0xFD` macro chunks are spaced 200 ms apart instead of 100 ms.
- Added exact two-chunk byte and timing coverage, bringing the deterministic suite to 20 tests.
- Applied the unchanged selected profile with build 10 and received device confirmation at flash
  count 686. The user then confirmed that the physical Top Button executed the complete
  click-plus-`qwertz` macro across both chunks.

## 2026-08-26 — Simplified button rows

- Removed the internal hardware-position subtitle from the Buttons screen.
- Preserved the device offsets exclusively in the protocol model, where they remain part of
  profile encoding without exposing implementation details in the user interface.

## 2026-08-26 — Physical button labels

- Replaced the inferred physical-button names with user-confirmed left/right side and
  front/back labels, without changing device offsets, default actions, or encoded bytes.
- Added deterministic coverage for all eight display names.

## 2026-08-26 — Single profile name in toolbar

- Removed the detail navigation title that duplicated the selected profile name at the leading
  edge of the window toolbar.
- Kept the normal app window title plus the centered editable profile-name field and rename control.

## 2026-08-26 — Tahoe DPI slider appearance

- Removed SwiftUI's stepped-slider presentation from the DPI controls so Tahoe no longer draws
  a dense row of tick marks beneath each track.
- Preserved the M600's required 100-DPI increments in the slider binding and numeric field.

## 2026-08-26 — Tahoe deployment target

- Raised both the SwiftPM and app-bundle minimum deployment target from macOS 14 to macOS 26.
- Rebuilt the Apple Silicon release with Xcode 27 beta and verified that the app and CLI Mach-O
  metadata both declare macOS 26 as their minimum supported system.

## 2026-08-26 — Dedicated RGB activation and verification

- Reproduced a successful full-profile commit whose saved non-Off breathing programs remained
  dark; the connected mouse reached flash count 506.
- Queried the independent hardware stealth state and confirmed it was off.
- Restored Lenovo's dedicated checksummed `0x25` lighting packet after the full profile commit.
- Split verification into staged profile, `0x05` commit, and `0x25` lighting phases so one phase's
  flash-counter change cannot mask rejection of a later phase.
- Serialized status refreshes with mutations so read-only queries cannot interleave with the
  device's timing-sensitive profile sequence.
- Added hardware stealth status to the app and read-only CLI, including a visible explanation when
  stealth mode suppresses otherwise valid RGB settings.
- Added deterministic transport-sequence and rejection-path tests, bringing coverage to 18 tests.
- Live-applied the finalized write sequence: flash count advanced from 522 to 538 and the app
  confirmed both profile and lighting application. The final packaged build was then restarted
  and read-only verified after adding the status/write serialization guard.

## 2026-08-26 — Right-button mapping repair

- A live user test confirmed custom actions worked on the DPI button but not on the row
  labeled Right click.
- Traced the mismatch to Lenovo's use of WPF button values: middle is `1` and right is
  `2`, while the M600 hardware offsets are right `1` and wheel click `2`.
- Corrected the physical offsets, `B1`/`B2` action meanings, profile-zero macro IDs, and
  the corresponding right/wheel macro mouse-event bytes.
- Added schema-versioned migration so existing profiles retain the actions associated with
  the UI rows the user originally edited.
- Added deterministic tests for the recovered mapping and a legacy profile with a custom
  right-button action.

## 2026-08-26 — Live Apply repair

- Reproduced the failed configuration path and found that the original transport padded
  Lenovo's three-byte `05 00 00` commit payload to 64 bytes.
- Added explicit transfer lengths so checksummed reports remain 64 bytes while short direct
  commands match the native Windows writes exactly.
- Matched Lenovo's 150 ms profile-chunk and 100 ms action/commit timing instead of sending
  later reports too quickly.
- Added fresh post-write flash-counter verification and visible success feedback.
- Live-applied the connected mouse configuration. A static-red zone-0 program changed the
  physical scroll wheel to red while the logo stayed off, confirming writes and revealing
  that zone 0 is the scroll wheel and zone 1 is the Legion logo. Corrected the UI labels.
- Confirmed through the running SwiftUI app and `profiles.json` that both lighting and
  right-button picker changes mutate and persist the selected profile.
- Expanded deterministic coverage from 10 to 12 tests, including native transfer lengths
  and exact encoded bytes for both lighting zones plus the right button.

## 2026-08-26 — Native macOS implementation

- Created a maintainable Swift package with `M600Core`, `M600ManagerApp`, `M600CLI`, and protocol tests.
- Implemented the exact 142-byte profile codec, 160-entry DPI sensor table, two lighting zones, eight visible button bindings, macros, checksum/chunk framing, and onboard commit flow.
- Implemented IOKit discovery constrained to usage page `0x01`, usage `0x00`, avoiding macOS-owned pointer/keyboard collections.
- Live read-only query verified against the connected M600: product name, battery 100%, voltage 4224 mV, flash count 25, 2.4 GHz inactive.
- Added app bundle/release build script, read-only `m600ctl`, user documentation, and full protocol notes.
- Deliberately did not perform a live profile write, factory reset, firmware update, or pairing operation during development.

## 2026-08-26 — Installer and device inventory

- Installer SHA-256: `1d63c51bdff94b8d0c5c9baa4bb9e1b03fd3324c77d972b0863b33804724fe92`
- Installer: Lenovo-modified Inno Setup 5.5.7, Legion Accessory Central 2.0.9.10231.
- Connected device: `Lenovo Legion M600 Wireless Gaming Mouse`.
- USB vendor/product: `0x17EF:0x60E5`.
- Device exposes three HID application collections and a 64-byte vendor channel.
- Windows payload extracted successfully.
- `legion_hid.exe` decompiled successfully with ILSpy 11.
- Native route-handler addresses in `ldm_m600.dll` resolved with Rizin.

## Recovered feature surface

- Onboard profile size: 142 bytes.
- The legacy managed layer models two hardware slots, while the current M600 native path sends one active onboard profile; the macOS app therefore keeps unlimited local profiles and applies the selected one.
- Eleven 5-byte button action entries per profile.
- Four independent X/Y DPI stage pairs, 100–16,000 DPI.
- DPI stage count and active stage.
- Wired report rates: 125/250/500/1000 Hz.
- Two 12-byte lighting zones with static, breathing, rainbow, random, and off records.
- Keyboard/mouse macros with delay, key press/release, mouse press/release, and wheel opcodes.
- Battery/charging state query and connection events.
- Factory restore and firmware paths identified but excluded from early live writes.

## Completed focus

The exact 64-byte HID command framing is recovered and documented. A testable
Swift core, native SwiftUI app, read-only CLI, signed release bundle, and live
read-only device verification are complete.
