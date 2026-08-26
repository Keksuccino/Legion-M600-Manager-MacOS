# Verification record

Date: 2026-08-26
Host: macOS 27 beta, Apple Silicon
Toolchain: Apple Swift 6.4, Xcode 27 beta
Deployment target: macOS 26 Tahoe, Apple Silicon

## Deterministic checks

- `swift format lint`: clean.
- `swift test`: 19 tests executed, 0 failures.
- Debug app and CLI products compile.
- Release app and CLI products compile.
- App and CLI `LC_BUILD_VERSION` records both declare macOS 26.0 as `minos`.
- The packaged build was visually inspected on the Performance screen; the DPI sliders have clean
  tracks without Tahoe's dense stepped tick-mark rows.
- The packaged toolbar retains the normal app title on the left and shows the selected profile name
  only once, in the centered editable field.
- The packaged Buttons screen was visually inspected and shows only the eight user-confirmed
  physical button labels and action controls. Internal hardware-position subtitles are absent,
  while the underlying device offsets and existing assignments remain unchanged.
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
Flash count: 647
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
- No factory reset, firmware update, or receiver-pairing command was sent.

## Release hashes

These hashes are also recorded in `dist/SHA256SUMS`.

```text
3d15b8280cc57300e1418771564b2ff7e61623f735008d99c377b4614ba737e7  Legion M600 Manager.app/Contents/MacOS/M600 Manager
db408af637a6f3cccb27d777d135623755984c1de1ffb4533c8adba7690285c5  m600ctl
1219b8cfdac20c416b9e2ffe45b627e708143076de012369028c9e8ca78d35e0  Legion-M600-Manager-macOS-arm64.zip
```
