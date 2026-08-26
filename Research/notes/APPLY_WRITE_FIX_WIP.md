# Apply/write defect — WIP checkpoint

Date: 2026-08-26

## User-observed failure

- Applying either lighting zone did not visibly change the mouse.
- Reassigning the right mouse button did not change its hardware behavior.
- IOKit returned success, so the original app did not surface an error.

## Evidence recovered from Lenovo's native module

- Checksummed profile chunks and key-action reports use the complete 64-byte HID payload.
- The final onboard commit is different: `FUN_1800238d0` calls Windows `hid_write`
  with four bytes total: report ID `00` followed by payload `05 00 00`.
- macOS passes report ID zero separately. The correct commit transfer is therefore exactly
  three payload bytes, not a zero-padded 64-byte transfer.
- Lenovo's generic checksummed sender waits 100 ms internally and the chunk sender waits
  another 50 ms. The original macOS implementation waited only 50 ms between profile
  chunks and button reports.

## Original implementation defect

`M600HIDTransport.send` required every transfer to be 64 bytes. This was correct for
checksummed writes but incorrect for Lenovo's short direct commit. IOKit accepting the
USB transfer did not mean that the device firmware accepted the command.

## UI-state observation

The persisted profile snapshot currently contains `Off` for both zones and `Right Click`
for the right button. That snapshot alone cannot distinguish a SwiftUI binding defect from
the user reverting selections after the unsuccessful apply. The control bindings remain
under verification; the apply button already saves the current bound profile before
starting the hardware write.

The live control checks subsequently confirmed that both the lighting picker and the
right-button picker mutate and persist their bound profile values correctly.

## Live result

- A corrected full write advanced the device flash counter from 73 to 88.
- Applying a non-Off red program in profile zone 0 advanced it from 88 to 103.
- The user observed the scroll wheel turn red while the logo remained off.
- This confirms the write/commit repair and corrects the zone identity: zone 0 is the
  scroll wheel; zone 1 is the Legion logo. The original UI labels were reversed.

## Planned correction

1. Model the fixed 64-byte backing buffer separately from the actual USB transfer length.
2. Send the commit as a 3-byte payload and direct queries at their native lengths.
3. Match Lenovo's 150 ms profile-chunk and 100 ms action/commit timing.
4. Require a fresh post-commit flash-counter response and show success in the UI.
5. Add regression tests for bytes, lengths, checksum placement, and timings.
