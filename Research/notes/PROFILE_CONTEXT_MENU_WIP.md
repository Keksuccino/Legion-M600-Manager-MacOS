# Profile context menu — implementation checkpoint

Date: 2026-08-26
Target release: 0.1.22 (build 23)

## Behavior

- Every local-profile sidebar row owns a native right-click context menu.
- Edit selects the targeted profile and opens it in the existing detail editor.
- Rename replaces only that row's label with an inline text field. Return or clicking elsewhere
  commits before leaving the field.
- Duplicate copies the targeted profile rather than assuming the selected row, then selects the
  new copy.
- Delete removes only the targeted profile, preserves a different current selection, selects an
  adjacent profile when deleting the current one, and remains disabled for the final profile.
- Change Icon and Change Color reuse the same 50-symbol and 18-preset catalogs as the toolbar
  controls; the color submenu also retains the native custom-color chooser.
- The sidebar toolbar now contains only New Profile; the former selected-profile actions menu has
  been removed.

## Verification scope

- Deterministic tests exercise row-targeted duplication, rename, appearance changes, selection
  behavior, deletion fallback, last-profile protection, persistence, and catalog integrity.
- Interactive verification must not activate Delete or Apply against the user's real profiles or
  connected mouse.
