# Borderless full-size editor layout WIP

Date: 2026-08-26

## Goal

Remove the inset, bordered native macOS tab container around the configuration screens while
retaining the centered segmented section selector.

## Implementation plan

- Replace the native `TabView` shell with a full-size vertical editor layout.
- Keep a centered segmented picker for Performance, Buttons, Lighting, and Device.
- Render the selected screen directly below the picker without horizontal outer padding or an
  enclosing border.
- Preserve every existing editor binding, save trigger, device operation, and confirmation flow.

## Verification checklist

- [x] Swift formatting and full regression suite.
- [x] Debug and release compilation.
- [x] Packaged visual inspection at the current app window size.
- [x] Confirm all four editor sections remain selectable.
- [x] Release metadata, signature, archive, and hashes.

## Result

- Version 0.1.11 (build 12) removes the native macOS `TabView` container that produced the inset
  rectangle and its asymmetric border.
- The replacement fills all remaining space below the device header, uses no enclosing padding or
  border, and retains the centered 540-point segmented selector.
- Performance, Buttons, Lighting, and Device were each opened in the packaged app. The app was
  left on Buttons, matching the requested inspection screen.
- The 24-test suite passes, the Tahoe release metadata and signature validate, and the archive and
  recorded hashes verify. Only read-only device-status commands were sent.
