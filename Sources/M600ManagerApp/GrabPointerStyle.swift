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

  private var effectiveIsEnabled: Bool {
    isEnabled && environmentIsEnabled
  }

  func body(content: Content) -> some View {
    content
      .pointerStyle(
        effectiveIsEnabled ? (isActive ? .grabActive : .grabIdle) : nil
      )
  }
}
