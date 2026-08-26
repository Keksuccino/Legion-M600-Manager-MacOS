# Right-button mapping repair

Date: 2026-08-26

## Reproduction

- Custom actions applied to the DPI button work on the connected M600.
- Applying an action through the row labeled Right click leaves the physical right button
  behaving normally.
- The saved profile confirms that the SwiftUI picker persists the selected row correctly.

## Root cause

Lenovo's managed M600 layout uses WPF `MouseButton` values to describe default actions.
WPF defines left as `0`, middle as `1`, and right as `2`. Lenovo separately assigns the
M600 device offsets as left `0`, right `1`, and wheel click `2`.

The original Swift model treated the WPF values as hardware offsets. It also labeled
action byte `B1` as middle and `B2` as right, opposite Lenovo's action table. Defaults
looked correct because those two errors canceled each other. A non-default action selected
for Right click was written to offset `2`, which is the wheel-click slot, while offset `1`
retained its normal right-click action.

This is a firmware-slot mapping defect, not a macOS event override. Once the mouse emits a
different onboard action, macOS does not know which physical switch produced it.

## Repair

- Device offset `1` is modeled as Right click with macro ID `2`.
- Device offset `2` is modeled as Wheel click with macro ID `3`.
- `B1` means Right click; `B2` means Wheel click.
- Stored profile schema version 2 swaps the two legacy button identities on first load,
  and version 3 corrects right/wheel mouse events inside saved macros. These migrations
  keep every selected action and macro associated with its intended UI meaning.
- A pre-migration copy of the live profile store is retained under ignored
  `Research/local-wip/` storage.

## Verification state

- Swift format lint: clean.
- Unit coverage: 15 tests pass, including mapping and both migration stages.
- Packaged `Info.plist`, ad-hoc signature, ZIP integrity, and release hashes pass.
- The unchanged current profile committed through the corrected build at flash count 431.
- Live physical right-button action: pending user confirmation after installing build 3.
