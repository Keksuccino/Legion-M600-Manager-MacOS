import XCTest

@testable import M600ManagerApp

final class TimedConfirmationStateTests: XCTestCase {
  func testSecondActivationWithinDeadlineConfirms() {
    let start = ContinuousClock().now
    var state = TimedConfirmationState(timeout: .seconds(3))

    XCTAssertFalse(state.activateOrConfirm(at: start))
    XCTAssertTrue(state.isAwaitingConfirmation)
    XCTAssertTrue(state.activateOrConfirm(at: start.advanced(by: .milliseconds(2_999))))
    XCTAssertFalse(state.isAwaitingConfirmation)
  }

  func testActivationAtDeadlineStartsFreshWindow() {
    let start = ContinuousClock().now
    var state = TimedConfirmationState(timeout: .seconds(3))

    XCTAssertFalse(state.activateOrConfirm(at: start))
    XCTAssertFalse(state.activateOrConfirm(at: start.advanced(by: .seconds(3))))
    XCTAssertEqual(state.deadline, start.advanced(by: .seconds(6)))
  }

  func testCancelAndTimeoutNeverConfirm() {
    let start = ContinuousClock().now
    var state = TimedConfirmationState(timeout: .seconds(3))

    XCTAssertFalse(state.activateOrConfirm(at: start))
    state.cancel()
    XCTAssertFalse(state.isAwaitingConfirmation)

    XCTAssertFalse(state.activateOrConfirm(at: start))
    state.expire(at: start.advanced(by: .milliseconds(2_999)))
    XCTAssertTrue(state.isAwaitingConfirmation)
    state.expire(at: start.advanced(by: .seconds(3)))
    XCTAssertFalse(state.isAwaitingConfirmation)
  }
}
