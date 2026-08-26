# Reverse-engineering workspace

This directory preserves the useful intermediate state used to implement the
native macOS M600 manager. It is deliberately separate from the application
source.

## Layout

- `windows-payload/`: local-only files extracted from Lenovo's Inno Setup installer.
- `decompiled-managed/`: local-only ILSpy output for the managed Windows front end.
- `notes/`: tracked protocol notes, inventories, and milestones, plus ignored local
  native decompiler output used during analysis.
- `ghidra-project/`: the persisted, local-only native M600 analysis database.
- `tools/DecompileAt.java`: reusable headless Ghidra decompiler helper.

The original `setup_v2_0_9_10231.exe` remains unchanged at the workspace root.
Git intentionally excludes that installer, extracted payloads, binary analysis
databases, direct decompiler output, and release builds while tracking the
compact, reviewable research notes needed to reproduce the protocol
implementation.
