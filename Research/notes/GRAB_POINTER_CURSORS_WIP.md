# Grab pointer cursors — WIP checkpoint

Date: 2026-08-26
Target release: 0.1.14 (build 15)

## Requested behavior

- Show an open-hand cursor while hovering anything the app expects the user to drag.
- Show a closed-hand cursor from grab start until the drag ends.

## Surface inventory

- The DPI sliders and macro event rows are the app's custom draggable controls.
- The navigation splitter, window frame, scroll bars, and native color controls are owned by
  AppKit/SwiftUI and retain their more specific resize, scroll, and control cursors.
- The non-destructive portion of each macro row is the reorder surface. The trash button remains a
  clickable link-style target rather than a draggable target.

## Implementation

- `GrabPointerStyle` centralizes Tahoe's native `.grabIdle` and `.grabActive` pointer styles.
- The modifier immediately refreshes the matching AppKit cursor when drag state changes. This is
  required because SwiftUI can otherwise retain the open hand while the mouse button is held even
  though the view has already switched to `.grabActive`.
- Each slider reports its actual editing phase through `Slider.onEditingChanged`. This gives the
  modifier exact drag state without installing a second gesture recognizer that could compete with
  the slider.
- Disabled DPI stages receive no grab cursor because the modifier also observes SwiftUI's
  environment-level enabled state.
- Macro rows track their drag phase with a simultaneous gesture so the pointer can close without
  replacing SwiftUI's native list-move gesture. Reordering is disabled while recording, so the
  grab cursor is suppressed then as well.
- Macro trash buttons now use SwiftUI's native `.link` pointer style while retaining their red
  hover treatment.

## Verification checkpoint

- Swift formatting lint is clean and the full deterministic suite remains at 27 passing tests.
- A packaged isolated Performance host dragged Stage 1 from 800 DPI to 8100 DPI, confirming that
  the cursor modifier preserves the slider's actual drag behavior.
- A packaged isolated Macro Editor host confirmed the open-hand hit region covers each event row's
  reorder surface without covering its trash button. The active transition is driven by the row's
  simultaneous drag gesture and now forces `NSCursor.closedHand` immediately.
- The host never loaded the user's profile store and was removed before the final build.
- No device Apply operation was performed.
