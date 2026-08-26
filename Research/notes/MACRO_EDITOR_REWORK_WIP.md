# Macro editor rework — WIP checkpoint

Date: 2026-08-26
Target release: 0.1.12 (build 13)

## Requested behavior

- Replace the crowded bottom toolbar with a clear, professional editing layout.
- Remove the unused macro-name input.
- Show captured events in the sequence while recording, not only after Stop.
- Record keyboard and mouse input without requiring the user to leave the manager.
- Give every trash button a red hover treatment and pointing-hand cursor.

## Implemented structure

- The modal is split into a large event-sequence pane and a 320-point control sidebar.
- The header contains only the physical button context, a short explanation, and Done.
- Recording, wait, keyboard, and mouse actions are grouped into reusable custom control cards.
- Each event row has an index, semantic icon, description, and dedicated delete control.
- The list follows newly recorded events while recording.
- Manual mutation and row deletion are disabled during recording so the recorder's source state and
  the visible bound macro cannot diverge.

## Recording architecture

- The global `NSEvent` monitor remains available for recording while another app is active.
- A local keyboard monitor handles key-down, key-up, and modifier events while the manager is
  active. It consumes recorded keys so they cannot invoke Done or another editor shortcut.
- An explicit in-app mouse capture surface accepts clicks and scrolling. Manager controls sit
  outside that surface, so Start, Stop, Done, Clear, and sidebar clicks cannot become macro events.
- `MacroRecorder.steps` is observed continuously by the editor and copied to the bound macro on
  every publication. Stop performs one final synchronization as a defensive completion step.
- Event timestamps come from `NSEvent.timestamp`, preserving physical timing across the local and
  global capture paths.

## Tahoe accessibility finding

SwiftUI's native `GroupBox` caused the macOS 27 beta accessibility inspection service to terminate
when it traversed the completed macro editor. The app remained alive, but the view was not safely
inspectable. The native boxes were replaced with a small reusable `MacroControlCard` presentation;
the complete view then exposed all controls and event rows correctly.

## Verification checkpoint

- Swift formatting lint is clean.
- Three focused app tests cover immediate event publication, exact event timing, and timing reset
  after clearing; the existing 24 protocol/profile tests remain unchanged.
- An isolated packaged-app host preserved the user's real profiles while exercising the actual
  macro editor. Pressing `Q` in the active manager immediately added Q down and Q up rows.
- Clicking the dedicated capture surface immediately added a wait plus left-mouse down/up rows.
- Clicking Stop left the event count unchanged, confirming that the control click was excluded.
- The complete idle and recording layouts were visually inspected at the default 1080×760 window
  size. No device Apply operation was performed.
