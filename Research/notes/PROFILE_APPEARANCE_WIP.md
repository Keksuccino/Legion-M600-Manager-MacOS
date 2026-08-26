# Profile appearance — implementation checkpoint

Date: 2026-08-26
Target release: 0.1.21 (build 22)

## Model

- Each local profile can persist an optional SF Symbol name and 24-bit RGB display color.
- Missing appearance fields resolve to the mouse icon and Legion blue, so profiles saved by older
  builds remain compatible without a schema migration.
- Appearance is local app metadata and is deliberately excluded from M600 hardware encoding.

## Interface

- The centered profile-name field preserves its original native pill, with independent icon and
  color controls in separate toolbar items on its left and right. Build 21 removes the additional
  fixed toolbar spacers so both controls use the tighter native inter-item distance.
- Build 22 reduces the profile-name field from 260 to 208 points, an exact 20% reduction.
- The icon picker contains exactly 50 hardcoded symbols grouped into ten usage categories: generic,
  gaming, music, coding, office, image/art, chatting, streaming/recording, flowers/nature, and
  cleaning/home. The categories organize the catalog internally; the chooser presents one clean
  grid without category labels.
- The color control is a compact circular swatch that opens an 18-color preset grid plus a native
  Custom Color chooser, without exposing implementation-oriented RGB or hex text.
- Sidebar profile icons update from the selected symbol and RGB color.

## Verification

- All 50 catalog entries resolve to real Tahoe SF Symbols and are unique.
- Icon changes update the toolbar and sidebar immediately and survive a packaged-app restart;
  profile color persistence and the SwiftUI color bridge are covered deterministically.
- Older serialized profiles without appearance keys decode with the default icon and color.
- The temporary visual-test profile store is absent from the final source and release package.
