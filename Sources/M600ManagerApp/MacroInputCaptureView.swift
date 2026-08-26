import AppKit
import SwiftUI

/// A deliberate mouse target for in-app recording. Keyboard events are handled by
/// MacroRecorder's local monitor; limiting mouse capture to this surface keeps clicks on
/// recording controls from being written into the macro itself.
struct MacroInputCaptureView: View {
  let capture: (NSEvent) -> Void

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 10, style: .continuous)
        .fill(Color.red.opacity(0.07))
      RoundedRectangle(cornerRadius: 10, style: .continuous)
        .strokeBorder(Color.red.opacity(0.45), style: StrokeStyle(lineWidth: 1, dash: [5, 4]))

      MouseEventCaptureRepresentable(capture: capture)

      VStack(spacing: 5) {
        Label("Input capture is active", systemImage: "waveform.circle.fill")
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(.red)
        Text("Type anywhere in this window. Click or scroll inside this area.")
          .font(.caption)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
      }
      .padding(10)
      .allowsHitTesting(false)
    }
    .frame(height: 84)
    .help("Mouse clicks and scrolling in this area are added to the recording")
  }
}

private struct MouseEventCaptureRepresentable: NSViewRepresentable {
  let capture: (NSEvent) -> Void

  func makeNSView(context: Context) -> MouseEventCaptureNSView {
    let view = MouseEventCaptureNSView()
    view.capture = capture
    return view
  }

  func updateNSView(_ nsView: MouseEventCaptureNSView, context: Context) {
    nsView.capture = capture
  }
}

private final class MouseEventCaptureNSView: NSView {
  var capture: ((NSEvent) -> Void)?

  override var acceptsFirstResponder: Bool { true }

  override func resetCursorRects() {
    addCursorRect(bounds, cursor: .crosshair)
  }

  override func mouseDown(with event: NSEvent) {
    window?.makeFirstResponder(self)
    capture?(event)
  }

  override func mouseUp(with event: NSEvent) {
    capture?(event)
  }

  override func rightMouseDown(with event: NSEvent) {
    window?.makeFirstResponder(self)
    capture?(event)
  }

  override func rightMouseUp(with event: NSEvent) {
    capture?(event)
  }

  override func otherMouseDown(with event: NSEvent) {
    window?.makeFirstResponder(self)
    capture?(event)
  }

  override func otherMouseUp(with event: NSEvent) {
    capture?(event)
  }

  override func scrollWheel(with event: NSEvent) {
    capture?(event)
  }
}
