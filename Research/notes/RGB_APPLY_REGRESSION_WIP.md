# RGB Apply regression — WIP checkpoint

Date: 2026-08-26

## Reported behavior

- Applying the existing profile reports success, but both lighting zones remain dark.
- The running app reported `Applied to onboard memory · flash #506`, so the current failure is
  distinct from the earlier incorrectly padded `0x05` commit.

## Captured state

- The selected local profile still contains two non-Off breathing programs.
- A live read-only `0x0A` query returned hardware stealth mode `off`.
- The saved profile, profile commit, and hardware light-suppression state therefore do not explain
  the dark LEDs.

## Recovered Windows behavior

- Full profile application sends command `0x01`, all eleven `0x02` key actions, and `0x05` commit.
- Lighting changes also use a dedicated checksummed `0x25` packet containing the same two 12-byte
  lighting records.
- The native handler uses the normal 100 ms checksummed-send delay, waits another 50 ms, and then
  queries `0x0D`.

## Implemented correction

1. Query the flash counter after staging, send `0x05`, and require a second fresh response
   with a different value.
2. Send the encoded 24-byte lighting block as command `0x25` only after that verified commit.
3. Wait the recovered 150 ms and require another fresh counter change.
4. Expose hardware stealth state in the app and read-only CLI so future light-off reports are
   distinguishable.
5. Cover packet bytes, stealth parsing, exact ordering, rejected commits, and rejected lighting
   activation with deterministic tests.
6. Serialize read-only refreshes with writes so a connection-triggered query cannot land between
   two timing-sensitive profile reports.

## Live result

- A first corrected build applied the unchanged profile and advanced the counter from 506 to 522.
- The build containing the finalized staged/commit/lighting sequence advanced it from 522 to 538.
- Each 16-count change matches 14 staged profile/button reports, one accepted `0x05`, and one
  accepted `0x25` lighting report.
- The live application reported `Applied profile and lighting · flash #538`.
- The packaged build then added status/write serialization, was restarted, and completed its
  read-only connected-device refresh at the same flash count without another hardware write.
