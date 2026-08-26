# Profile context menu — implementation checkpoint

Date: 2026-08-26
Target release: 0.1.23 (build 24)

## Behavior

- Every local-profile sidebar row owns a native right-click context menu.
- Rename replaces only that row's label with an inline text field. Return or clicking elsewhere
  commits before leaving the field.
- Duplicate copies the targeted profile rather than assuming the selected row, then selects the
  new copy.
- Delete removes only the targeted profile, preserves a different current selection, selects an
  adjacent profile when deleting the current one, and remains disabled for the final profile.
- Change Icon and Change Color are direct actions rather than nested context-menu choosers. Each
  selects the targeted profile, lets the native context menu close, and then opens the existing
  toolbar icon or color popover. This keeps one chooser implementation and includes the full
  custom-color control.
- The sidebar toolbar now contains only New Profile; the former selected-profile actions menu has
  been removed.

## Verification scope

- Deterministic tests exercise row-targeted duplication, rename, selection behavior, deletion
  fallback, last-profile protection, persistence, and catalog integrity.
- Interactive verification must confirm that neither appearance action leaves its context menu
  open and that it presents the same chooser as its corresponding toolbar control.
- Interactive verification must not activate Delete or Apply against the user's real profiles or
  connected mouse.
