# Grab pointer cursors — WIP checkpoint

Date: 2026-08-26
Target release: 0.1.13 (build 14)

## Requested behavior

- Show an open-hand cursor while hovering anything the app expects the user to drag.
- Show a closed-hand cursor from grab start until the drag ends.

## Surface inventory

- The four DPI sliders are the app's custom draggable controls.
- The navigation splitter, window frame, scroll bars, and native color controls are owned by
  AppKit/SwiftUI and retain their more specific resize, scroll, and control cursors.
- Macro rows retain native list move support, but packaged interaction testing did not establish
  the entire row as a reliable direct mouse-drag surface. They therefore do not advertise a grab
  cursor. The trash buttons remain clickable link-style targets rather than draggable targets.

## Implementation

- `GrabPointerStyle` centralizes Tahoe's native `.grabIdle` and `.grabActive` pointer styles.
- Each slider reports its actual editing phase through `Slider.onEditingChanged`. This gives the
  modifier exact drag state without installing a second gesture recognizer that could compete with
  the slider.
- Disabled DPI stages receive no grab cursor because the modifier also observes SwiftUI's
  environment-level enabled state.
- Macro trash buttons now use SwiftUI's native `.link` pointer style while retaining their red
  hover treatment.

## Verification checkpoint

- Swift formatting lint is clean and the full deterministic suite remains at 27 passing tests.
- A packaged isolated Performance host dragged Stage 1 from 800 DPI to 8100 DPI, confirming that
  the cursor modifier preserves the slider's actual drag behavior.
- The host never loaded the user's profile store and was removed before the final build.
- No device Apply operation was performed.
