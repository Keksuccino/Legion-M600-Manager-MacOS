# Dedicated key-press action WIP

Date: 2026-08-26

## Goal

Add a nested `Key Press` action to each programmable-button menu. A selected key must appear as
`Press <key name>` and use the M600's existing macro protocol when applied.

## Design

- Persist `keyPress` as its own button-action kind plus an optional HID usage on the binding.
- Keep the editable user macro separate so switching to a key press does not destroy it.
- Compile a key press to exactly two on-device macro steps: matching key-down and key-up events.
- Do not infer the action from an arbitrary two-step macro. An explicitly created two-step macro
  remains a macro, which preserves the user's intent and makes persistence deterministic.
- Reuse `HIDKeyNames.common` for both the macro editor and the new nested action menu.

## Verification checklist

- [x] Core compilation and persistence tests.
- [x] Existing macro and profile regression suite.
- [x] Tahoe debug and release builds.
- [x] Packaged nested-menu and selected-label inspection.
- [x] Release metadata, signature, archive, and read-only device status.

## Result

- Version 0.1.10 (build 11) exposes `Key Press` as a nested action menu containing the same
  HID-key list as the macro editor.
- Selecting `A` in the packaged app displayed `Press A` immediately. The temporary test binding
  was then restored to its original `Disabled` state, including removal of its persisted HID usage.
- The deterministic suite has 24 tests. Exact encoding coverage confirms that `Press A` produces
  the 30-byte Lenovo prefix followed by `02 04 03 04` (A down, A up).
- No profile was applied during this UI verification. The compiled action uses the same macro
  programming path already verified on the connected mouse with the multi-chunk macro test.
