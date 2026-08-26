# Verification record

Date: 2026-08-26
Host: macOS 27 beta, Apple Silicon
Toolchain: Apple Swift 6.4, Xcode 27 beta

## Deterministic checks

- `swift format lint`: clean.
- `swift test`: 15 tests executed, 0 failures.
- Debug app and CLI products compile.
- Release app and CLI products compile.
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
Flash count: 73
2.4 GHz link: inactive
```

Only query reports `0x0B`, `0x0D`, and `0x0E` were sent. No profile, lighting, button, DPI, polling, reset, pairing, or firmware command was sent during this check.

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
- No factory reset, firmware update, or receiver-pairing command was sent.

## Release hashes

These hashes are also recorded in `dist/SHA256SUMS`.

```text
9ec61445503988c27482460a58946e4589abc8ce92f331b14b4ddf74e44a5e2d  Legion M600 Manager.app/Contents/MacOS/M600 Manager
f2017295ac7916160966694278c9c36bce0eb67f2811133fac501173c4edaa6f  m600ctl
451ad9db548d1ad052f57cebf08d3b9609f36fea1b9bc3f98fe12df69bf9cdae  Legion-M600-Manager-macOS-arm64.zip
```
