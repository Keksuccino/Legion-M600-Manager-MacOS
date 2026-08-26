# Legion M600 Manager for macOS

An independent native macOS configuration app for the **Lenovo Legion M600 Wireless Gaming Mouse**.

The project was built by extracting Lenovo Legion Accessory Central 2.0.9.10231, decompiling its managed M600 module, and tracing the native `ldm_m600.dll` HID transport. It does not run or bundle Windows code.

## Features

- Local named profiles: create, rename, duplicate, and delete
- One to four DPI stages, independently configurable X/Y values, 100–16,000 DPI
- 125, 250, 500, and 1,000 Hz polling rates
- All eight programmable buttons
- Media commands and DPI cycling
- Macro editing and recording with delays, keyboard, mouse buttons, and wheel events
- Two independent RGB zones with Static, Breathing, Rainbow, Random, and Off effects
- Battery, voltage, 2.4 GHz link, hardware stealth mode, and onboard flash-counter diagnostics
- Onboard profile persistence and a confirmation-gated factory-reset flow
- A read-only `m600ctl` diagnostic command

Firmware update and receiver-pairing paths are intentionally not included. They are unrelated to everyday configuration and carry materially greater recovery risk.

## Build

Requirements:

- macOS 26 Tahoe or later
- Xcode 26 or later command-line tools (this workspace uses `/Applications/Xcode-beta.app`)

```sh
./Scripts/build-app.sh
```

Outputs:

- `dist/Legion M600 Manager.app`
- `dist/m600ctl`
- `dist/Legion-M600-Manager-macOS-arm64.zip` (packaged release archive)

The build is ad-hoc signed. Move the app to `/Applications` if desired, then open it normally. Macro recording may require enabling the app under **System Settings → Privacy & Security → Accessibility** and **Input Monitoring**. Manual macro editing does not need those permissions.

## Test

```sh
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer swift test
dist/m600ctl info
```

The CLI is deliberately query-only. Configuration changes require the explicit **Apply to Mouse** button in the app.

## Project map

- `Sources/M600Core`: profile model/codec, protocol framing, report parser, IOKit transport, and device controller
- `Sources/M600ManagerApp`: SwiftUI user interface and macro recorder
- `Sources/M600CLI`: read-only connected-device diagnostics
- `Tests/M600CoreTests`: deterministic protocol and persistence coverage
- `Docs/PROTOCOL.md`: recovered wire protocol and confidence notes
- `Research`: persisted extraction, decompilation, Ghidra project, native output, and milestone journal

## Status and caveats

Read-only communication, independently confirmed profile commits, and dedicated lighting activation were verified against a connected M600 (VID `17EF`, PID `60E5`). The live lighting check also confirmed the scroll-wheel and Legion-logo zone identities. Encoding, write ordering, and rejection paths are covered by unit tests against the recovered Windows implementation. The project never writes settings automatically during startup.

This is an independent project and is not affiliated with or endorsed by Lenovo.
