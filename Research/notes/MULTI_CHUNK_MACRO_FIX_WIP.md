# Multi-chunk macro defect — WIP checkpoint

Date: 2026-08-26

## User-observed failure

- A recorded Top Button macro containing a left click followed by `qwertz` executed only the
  click and `qw` after being applied to the connected M600.
- The persisted macro contains 27 low-level actions: 13 delays, six key-down events, six key-up
  events, and one mouse-down/mouse-up pair.

## Exact boundary reproduction

- The encoded actions occupy 67 bytes and Lenovo's required opaque prefix occupies 30 bytes,
  producing a 97-byte macro body.
- Command `0xFD` can carry 57 macro bytes in each 64-byte HID payload, so this macro requires two
  chunks: 57 bytes followed by 40 bytes.
- After the 30-byte prefix, the first chunk's remaining 27 bytes end exactly after the recorded
  mouse click, `q`, and `w` release. The second chunk starts with the delay before `e` and contains
  the rest of `ertz`.
- The physical behavior therefore proves that the first chunk was stored and the second chunk was
  silently dropped; it is not a three-input firmware limit.

## Recovered Windows pacing

- Lenovo's native M600 writer sleeps for its 50 ms device guard before every `0xFD` report, waits
  100 ms after the HID write, and then sleeps for another 50 ms device guard.
- Consecutive macro chunks therefore require 200 ms between their HID writes. The original macOS
  implementation waited only 100 ms, which was already known to be too short for other staged M600
  writes.
- Macro begin (`0xFB`) and length (`0xFE`) packets also retain the native preparation windows;
  ordinary key-action timing remains unchanged.

## Verification status

1. The exact two-chunk encoding and native delays for the persisted click-plus-`qwertz` sequence
   are covered by a deterministic regression test.
2. Build 10 applied the unchanged selected profile successfully and the connected mouse confirmed
   the complete write at flash count 686.
3. The user pressed the physical Top Button and confirmed that the mouse executed the complete
   click-plus-`qwertz` macro, including `ertz` from the second programming chunk.
