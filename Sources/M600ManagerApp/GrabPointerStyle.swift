import AppKit
import SwiftUI

extension View {
  /// Shows Tahoe's open-hand cursor over a draggable surface and closes the hand while
  /// the owning control reports an active drag. Drag state stays explicit so this modifier
  /// never competes with the control's native slider or drag/drop gesture recognizer.
  func grabPointerStyle(isActive: Bool = false, isEnabled: Bool = true) -> some View {
    modifier(GrabPointerStyleModifier(isActive: isActive, isEnabled: isEnabled))
  }
}

private struct GrabPointerStyleModifier: ViewModifier {
  let isActive: Bool
  let isEnabled: Bool

  @Environment(\.isEnabled) private var environmentIsEnabled
  @State private var isHovering = false

  private var effectiveIsEnabled: Bool {
    isEnabled && environmentIsEnabled
  }

  func body(content: Content) -> some View {
    content
      .pointerStyle(
        effectiveIsEnabled ? (isActive ? .grabActive : .grabIdle) : nil
      )
      .onHover { hovering in
        isHovering = hovering
      }
      .onChange(of: isActive) {
        refreshCursorIfHovered()
      }
      .onChange(of: effectiveIsEnabled) {
        refreshCursorIfHovered()
      }
      .onDisappear {
        // An active cursor set while the button is held can outlive a disappearing drag surface.
        if isHovering, isActive { NSCursor.arrow.set() }
      }
  }

  private func refreshCursorIfHovered() {
    guard isHovering else { return }

    guard effectiveIsEnabled else {
      NSCursor.arrow.set()
      return
    }

    // PointerStyle updates its cursor rect lazily. Force the matching native cursor immediately
    // when drag state changes so the hand closes without waiting for another hover transition.
    (isActive ? NSCursor.closedHand : NSCursor.openHand).set()
  }
}
