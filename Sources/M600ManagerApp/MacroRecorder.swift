import AppKit
import ApplicationServices
import Combine
import M600Core

@MainActor
final class MacroRecorder: ObservableObject {
  @Published private(set) var isRecording = false
  @Published private(set) var steps: [MacroStep] = []
  @Published private(set) var permissionWarning: String?

  private var monitor: Any?
  private var lastEventTime: TimeInterval?

  func start(existingSteps: [MacroStep]) {
    stop()
    steps = existingSteps
    lastEventTime = nil

    let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
    if !AXIsProcessTrustedWithOptions([promptKey: true] as CFDictionary) {
      permissionWarning =
        "Enable this app in System Settings › Privacy & Security › Accessibility and Input Monitoring to record keyboard events. Manual macro editing still works."
    } else {
      permissionWarning = nil
    }

    let mask: NSEvent.EventTypeMask = [
      .keyDown, .keyUp, .flagsChanged,
      .leftMouseDown, .leftMouseUp,
      .rightMouseDown, .rightMouseUp,
      .otherMouseDown, .otherMouseUp,
      .scrollWheel,
    ]
    monitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] event in
      Task { @MainActor [weak self] in self?.capture(event) }
    }
    isRecording = monitor != nil
    if monitor == nil {
      permissionWarning =
        "macOS did not grant an input event monitor. Add steps manually or review Privacy & Security permissions."
    }
  }

  func stop() {
    if let monitor { NSEvent.removeMonitor(monitor) }
    monitor = nil
    isRecording = false
    lastEventTime = nil
  }

  private func capture(_ event: NSEvent) {
    guard isRecording else { return }
    let step: MacroStep?
    switch event.type {
    case .keyDown where !event.isARepeat:
      step = Self.keyCodeToUSBUsage[event.keyCode].map(MacroStep.keyDown)
    case .keyUp:
      step = Self.keyCodeToUSBUsage[event.keyCode].map(MacroStep.keyUp)
    case .flagsChanged:
      guard let mapping = Self.modifierMapping[event.keyCode] else { return }
      let isDown = !event.modifierFlags.intersection(mapping.flag).isEmpty
      step = isDown ? .keyDown(usage: mapping.usage) : .keyUp(usage: mapping.usage)
    case .leftMouseDown: step = .mouseDown(button: .left)
    case .leftMouseUp: step = .mouseUp(button: .left)
    case .rightMouseDown: step = .mouseDown(button: .right)
    case .rightMouseUp: step = .mouseUp(button: .right)
    case .otherMouseDown:
      step = Self.mouseButton(for: event.buttonNumber).map(MacroStep.mouseDown)
    case .otherMouseUp:
      step = Self.mouseButton(for: event.buttonNumber).map(MacroStep.mouseUp)
    case .scrollWheel where event.scrollingDeltaY > 0: step = .wheelUp
    case .scrollWheel where event.scrollingDeltaY < 0: step = .wheelDown
    default: step = nil
    }
    guard let step else { return }

    let now = ProcessInfo.processInfo.systemUptime
    if let lastEventTime {
      appendDelay(milliseconds: Int((now - lastEventTime) * 1_000))
    }
    lastEventTime = now
    steps.append(step)
  }

  private func appendDelay(milliseconds: Int) {
    var remaining = max(0, milliseconds)
    guard remaining >= 2 else { return }
    while remaining > 0 {
      let piece = min(remaining, Int(UInt16.max))
      steps.append(.delay(milliseconds: UInt16(piece)))
      remaining -= piece
    }
  }

  private static func mouseButton(for buttonNumber: Int) -> MacroMouseButton? {
    switch buttonNumber {
    case 2: return .middle
    case 3: return .back
    case 4: return .forward
    default: return nil
    }
  }

  private static let modifierMapping: [UInt16: (usage: UInt8, flag: NSEvent.ModifierFlags)] = [
    59: (0xE0, .control), 56: (0xE1, .shift), 58: (0xE2, .option), 55: (0xE3, .command),
    62: (0xE4, .control), 60: (0xE5, .shift), 61: (0xE6, .option), 54: (0xE7, .command),
  ]

  /// macOS virtual key codes are position based; the mouse firmware expects USB HID usages.
  private static let keyCodeToUSBUsage: [UInt16: UInt8] = [
    0: 0x04, 11: 0x05, 8: 0x06, 2: 0x07, 14: 0x08, 3: 0x09, 5: 0x0A,
    4: 0x0B, 34: 0x0C, 38: 0x0D, 40: 0x0E, 37: 0x0F, 46: 0x10,
    45: 0x11, 31: 0x12, 35: 0x13, 12: 0x14, 15: 0x15, 1: 0x16,
    17: 0x17, 32: 0x18, 9: 0x19, 13: 0x1A, 7: 0x1B, 16: 0x1C, 6: 0x1D,
    18: 0x1E, 19: 0x1F, 20: 0x20, 21: 0x21, 23: 0x22, 22: 0x23,
    26: 0x24, 28: 0x25, 25: 0x26, 29: 0x27,
    36: 0x28, 53: 0x29, 51: 0x2A, 48: 0x2B, 49: 0x2C,
    122: 0x3A, 120: 0x3B, 99: 0x3C, 118: 0x3D, 96: 0x3E, 97: 0x3F,
    98: 0x40, 100: 0x41, 101: 0x42, 109: 0x43, 103: 0x44, 111: 0x45,
    124: 0x4F, 123: 0x50, 125: 0x51, 126: 0x52,
  ]
}
