# Legion M600 Manager for macOS

A native, unofficial macOS configuration app for the **Lenovo Legion M600 Wireless Gaming Mouse**.

Lenovo provides its M600 configuration software for Windows only. This project communicates with the mouse directly over USB HID, so macOS users can configure it without Windows or bundled Lenovo software.

## Install

Requirements: Apple silicon and macOS 26 Tahoe or later.

1. Download the `.dmg` from the [latest release](https://github.com/Keksuccino/Legion-M600-Manager-MacOS/releases/latest).
2. Open it and drag **Legion M600 Manager** into **Applications**.
3. Connect the mouse and open the app.

The current release is ad-hoc signed, not Apple-notarized. If macOS blocks the first launch, allow it from **System Settings → Privacy & Security**.

## Configure the mouse

1. Select or create a profile in the sidebar.
2. Configure performance, buttons, macros, lighting, or device settings.
3. Click **Apply to Mouse**.

Nothing is written to the mouse until **Apply to Mouse** is clicked. Profile names, colors, and icons are app metadata stored on the Mac.

## Features

- 1–4 DPI stages with independent X/Y values from 100–16,000 DPI
- 125, 250, 500, and 1,000 Hz polling rates
- Remapping for all eight programmable buttons
- Key presses, media commands, DPI cycling, and multi-event macros
- Scroll-wheel and Legion-logo lighting with Static, Breathing, Rainbow, Random, and Off effects
- Local profiles with custom names, colors, and icons
- Battery, connection, voltage, stealth-mode, and onboard diagnostics
- Confirmation-gated factory reset

Firmware updates and receiver pairing are intentionally excluded because they carry greater device-recovery risk and are not needed for normal configuration.

## Build and test

Requirements: Xcode 26 or later command-line tools. The scripts expect Xcode at `/Applications/Xcode-beta.app`.

```sh
./Scripts/build-app.sh
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer swift test
```

Build outputs:

- `dist/Legion M600 Manager.app`
- `dist/Legion-M600-Manager-macOS-arm64.dmg`
- `dist/m600ctl`

`m600ctl` provides read-only diagnostics:

```sh
dist/m600ctl info
```

## Source layout

- `Sources/M600Core` — HID transport, protocol codec, packet builders, and models
- `Sources/M600ManagerApp` — SwiftUI app and macro recorder
- `Sources/M600CLI` — read-only diagnostic CLI
- `Tests` — protocol, persistence, profile, and recorder tests
- `Docs/PROTOCOL.md` — recovered M600 wire protocol and confidence notes
- `Research` — reverse-engineering notes, milestones, and analysis helpers

The project does not contain Lenovo's installer or proprietary Windows binaries. It is independent and is not affiliated with or endorsed by Lenovo.

## License

[The Unlicense](LICENSE)
