# Lenovo Legion M600 configuration protocol

This document records the implementation-relevant results of reverse-engineering Legion Accessory Central 2.0.9.10231. Addresses refer to the extracted 64-bit `ldm_m600.dll` with SHA-256:

`3f26250721bfeec9504b0fa8df10375bc156fec5e77ec5ed90c782dbe4615dca`

The complete recovered artifacts and decompiler output are stored under `Research/`.

## USB/HID identity

- Vendor ID: `0x17EF`
- Product ID: `0x60E5`
- Configuration collection: Generic Desktop usage page `0x01`, usage `0x00`
- Input report: 64 bytes, report ID 0
- Output report: 64 bytes, report ID 0

Windows hidapi prepends the zero report ID and therefore writes 65 bytes. `IOHIDDeviceSetReport` accepts the report ID separately, so the macOS transport passes the 64 payload bytes and report ID 0.

## Checksummed packets

General chunk and key-action reports use an additive 8-bit checksum:

- Bytes `0...62`: command and payload, zero padded
- Byte `63`: wrapping sum of bytes `0...62`

Chunk framing carries at most 58 data bytes:

| Offset | Meaning |
|---:|---|
| 0 | command |
| 1 | zero |
| 2 | one-based chunk index |
| 3 | total chunk count |
| 4 | data length in this chunk |
| 5...62 | data, then zero padding |
| 63 | checksum |

Chunk command `0x01` writes the 142-byte base profile. Command `0x25` is the standalone 24-byte lighting update used by the Windows UI.

Key action reports use:

`02 00 <device-offset> <five action bytes> ... <checksum>`

The primary mouse-action bytes are `B0` for left click, `B1` for right click,
and `B2` for wheel click. Lenovo's managed client expresses those buttons with
WPF enum values `0`, `2`, and `1`, but its M600 device offsets are `0`, `1`, and
`2`; the WPF values must not be mistaken for device offsets.

## Direct reports

Direct packets are zero-padded 64-byte reports without the additive checksum.

| Operation | Prefix |
|---|---|
| Commit onboard configuration | `05 00 00` |
| Query battery | `0B` |
| Query flash counter | `0D` |
| Query 2.4 GHz connection | `0E` |
| Query stealth state | `0A` |
| Set active DPI stage | `04 01 01 <stage>` |
| Set highest enabled DPI stage | `04 01 02 <count-minus-one>` |
| Set DPI value | `04 01 00 <stage> <x-le16> <y-le16>` |
| Set polling-rate register | `04 02 00 <value>` |
| Factory restore, begin | `07 05` |
| Factory restore, confirm | `07 05 01` |

Polling-rate register values are `0 → 125 Hz`, `2 → 250 Hz`, `4 → 500 Hz`, and `8 → 1,000 Hz`.

## Full profile write

The Windows handler at `0x1800040e0` performs this sequence:

1. Send the 142-byte profile with checksummed `0x01` chunks (58, 58, and 26 bytes).
2. Write all 11 key matrix positions individually.
3. For macro bindings, program the macro body before sending its `0xF2` key action.
4. Send direct command `0x05` to commit the configuration to onboard flash.

The macOS app follows that ordering with the recovered 150 ms profile-chunk and
100 ms action/commit timing.

## Macro protocol

A macro key matrix is `F2 <macro-id> 00 00 00`. Profile-zero macro IDs map visible device offsets as follows:

| Device offset | Button | Macro ID |
|---:|---|---:|
| 0 | Left | 1 |
| 1 | Right | 2 |
| 2 | Wheel click | 3 |
| 5 | Rear side | 4 |
| 6 | Front side | 5 |
| 7 | Right rear | 6 |
| 8 | Right front | 7 |
| 9 | DPI | 8 |

The Windows client prefixes macro bytecode with 30 reserved zero bytes. Programming then uses:

1. `FB <macro-id>` — clear existing macro
2. `FE <macro-id> <length-be16>` — declare body length
3. `FD <macro-id> <index-be16> <total-be16> <length> <up-to-57-data-bytes>` — body chunks
4. Normal checksummed `0x02` key action containing the `0xF2` binding

Macro bytecode:

| Opcode | Payload | Meaning |
|---:|---|---|
| `01` | delay in milliseconds, big-endian 16-bit | delay |
| `02` | USB HID usage | key down |
| `03` | USB HID usage | key up |
| `04` | mouse button `1...5` | mouse down |
| `05` | mouse button `1...5` | mouse up |
| `08` | none | wheel up |
| `09` | none | wheel down |

Macro mouse-button values are `1` left, `2` right, `3` wheel click, `4` back,
and `5` forward.

## 142-byte profile

| Offset | Length | Meaning |
|---:|---:|---|
| 0 | 2 | reserved |
| 2 | 30 | UTF-8 name, zero padded |
| 32 | 55 | 11 × five-byte key actions |
| 87 | 16 | four X/Y sensor-index pairs, little endian |
| 103 | 1 | polling-rate register |
| 104 | 1 | active DPI stage |
| 105 | 1 | default DPI stage |
| 106 | 1 | enabled stage count minus one |
| 107 | 6 | X/Y lock flags |
| 113 | 1 | surface pixel threshold |
| 114 | 1 | surface minimum square |
| 115 | 3 | unused acceleration/lightness/sleep fields |
| 118 | 12 | lighting zone 0 — scroll wheel |
| 130 | 12 | lighting zone 1 — Legion logo |

The app starts with Lenovo's exact default 142-byte buffer and mutates known fields so reserved values survive. DPI is encoded through Lenovo's explicit 160-entry sensor table; the register sequence is not a safe linear formula.

## Lighting

Each lighting zone is 12 bytes:

- Zone 0 controls the scroll wheel.
- Zone 1 controls the Legion logo.

- Static: `03 64 00 R G B 00 00 00 00 00 00`
- Breathing: `02 64 00 02 <mode> 00 R G B R2 G2 B2`, mode 1 for a black alternate and 3 for two colors
- Rainbow: `01 64 00 0A 00 00 00 00 00 00 00 00`
- Random: `03 64 01 00 00 00 00 00 00 00 00 00`
- Off: `03 00 00 00 00 00 00 00 00 00 00 00`

## Input reports

The native parser handles the command in byte 0:

- `0x04`: DPI changed; stage is byte 3, sensor indices bytes 4 and 5
- `0x0A`: stealth event
- `0x0B`: voltage is little-endian bytes 2–3; raw battery percentage is byte 4
- `0x0D`: 24-bit little-endian flash counter in bytes 2–4
- `0x0E`: 2.4 GHz connection state in byte 2

## Confidence and safety boundary

- **Live verified:** macOS discovery of the usage-0 interface; read-only `0x0B`, `0x0D`, and `0x0E` exchanges; full profile writes; the short `0x05` commit; and both lighting-zone identities.
- **Cross-checked and unit tested:** profile layout, DPI table, checksum/chunk framing, action encodings, lighting programs, macro bytecode and transfer framing, response parsing.
- **Not exercised during development:** factory reset.
- **Out of scope by design:** firmware update and receiver pairing.
