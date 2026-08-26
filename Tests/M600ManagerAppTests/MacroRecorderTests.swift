import AppKit
import Combine
import M600Core
import XCTest

@testable import M600ManagerApp

@MainActor
final class MacroRecorderTests: XCTestCase {
  func testLocalEventsAppendImmediatelyWithRecordedTiming() throws {
    let recorder = MacroRecorder(
      installsLocalKeyboardMonitor: false,
      isApplicationActive: { true }
    )
    recorder.start(existingSteps: [.wheelUp])

    recorder.captureLocalEvent(
      try XCTUnwrap(mouseEvent(type: .leftMouseDown, timestamp: 10.0))
    )
    recorder.captureLocalEvent(
      try XCTUnwrap(mouseEvent(type: .leftMouseUp, timestamp: 10.125))
    )

    XCTAssertEqual(
      recorder.steps,
      [
        .wheelUp,
        .mouseDown(button: .left),
        .delay(milliseconds: 125),
        .mouseUp(button: .left),
      ]
    )
    XCTAssertTrue(recorder.isRecording)
  }

  func testClearResetsRecordedTiming() throws {
    let recorder = MacroRecorder(
      installsLocalKeyboardMonitor: false,
      isApplicationActive: { true }
    )
    recorder.start(existingSteps: [.wheelDown])
    recorder.captureLocalEvent(
      try XCTUnwrap(mouseEvent(type: .leftMouseDown, timestamp: 10.0))
    )

    recorder.clear()
    recorder.captureLocalEvent(
      try XCTUnwrap(mouseEvent(type: .leftMouseUp, timestamp: 50.0))
    )

    XCTAssertEqual(recorder.steps, [.mouseUp(button: .left)])
  }

  func testEachKeyboardEventPublishesWhileRecording() throws {
    let recorder = MacroRecorder(
      installsLocalKeyboardMonitor: false,
      isApplicationActive: { true }
    )
    var publishedSteps: [[MacroStep]] = []
    let observation = recorder.$steps.dropFirst().sink { publishedSteps.append($0) }
    recorder.start(existingSteps: [])

    recorder.captureLocalEvent(
      try XCTUnwrap(keyEvent(type: .keyDown, timestamp: 20.0, keyCode: 12))
    )
    recorder.captureLocalEvent(
      try XCTUnwrap(keyEvent(type: .keyUp, timestamp: 20.050, keyCode: 12))
    )

    XCTAssertTrue(publishedSteps.contains([.keyDown(usage: 0x14)]))
    XCTAssertEqual(
      recorder.steps,
      [
        .keyDown(usage: 0x14),
        .delay(milliseconds: 50),
        .keyUp(usage: 0x14),
      ]
    )
    withExtendedLifetime(observation) {}
  }

  func testEventsAreIgnoredWhileManagerIsInactive() throws {
    let recorder = MacroRecorder(
      installsLocalKeyboardMonitor: false,
      isApplicationActive: { false }
    )
    recorder.start(existingSteps: [.wheelUp])

    recorder.captureLocalEvent(
      try XCTUnwrap(keyEvent(type: .keyDown, timestamp: 20.0, keyCode: 12))
    )
    recorder.captureLocalEvent(
      try XCTUnwrap(mouseEvent(type: .leftMouseDown, timestamp: 20.1))
    )

    XCTAssertEqual(recorder.steps, [.wheelUp])
  }

  private func mouseEvent(type: NSEvent.EventType, timestamp: TimeInterval) -> NSEvent? {
    NSEvent.mouseEvent(
      with: type,
      location: .zero,
      modifierFlags: [],
      timestamp: timestamp,
      windowNumber: 0,
      context: nil,
      eventNumber: 0,
      clickCount: 1,
      pressure: 1
    )
  }

  private func keyEvent(
    type: NSEvent.EventType,
    timestamp: TimeInterval,
    keyCode: UInt16
  ) -> NSEvent? {
    NSEvent.keyEvent(
      with: type,
      location: .zero,
      modifierFlags: [],
      timestamp: timestamp,
      windowNumber: 0,
      context: nil,
      characters: "q",
      charactersIgnoringModifiers: "q",
      isARepeat: false,
      keyCode: keyCode
    )
  }
}
