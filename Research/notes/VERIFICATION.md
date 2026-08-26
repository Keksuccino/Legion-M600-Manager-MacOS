# Verification record

Date: 2026-08-26
Host: macOS 27 beta, Apple Silicon
Toolchain: Apple Swift 6.4, Xcode 27 beta

## Deterministic checks

- `swift format lint`: clean.
- `swift test`: 12 tests executed, 0 failures.
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
- No factory reset, firmware update, or receiver-pairing command was sent.

## Release hashes

These hashes are also recorded in `dist/SHA256SUMS`.

```text
c85eb46d5f34119f1d3bc4edfbcfb95be5f8b40214fe5f42714cd819df19be4a  Legion M600 Manager.app/Contents/MacOS/M600 Manager
589edb20e7ffcc19e89adc253850cd83f1be1e47763f7cf64679d44398f80d93  m600ctl
15c083a63376dd96a8cf1770f51611b36aee168663bb8f635715014b1af8091e  Legion-M600-Manager-macOS-arm64.zip
```
