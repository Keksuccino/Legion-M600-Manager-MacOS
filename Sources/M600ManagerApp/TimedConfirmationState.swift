struct TimedConfirmationState {
  let timeout: Duration
  private(set) var deadline: ContinuousClock.Instant?

  init(timeout: Duration) {
    precondition(timeout > .zero, "Confirmation timeout must be positive")
    self.timeout = timeout
  }

  var isAwaitingConfirmation: Bool {
    deadline != nil
  }

  /// Returns true only for a second activation strictly before the current deadline.
  /// An activation at or after the deadline starts a fresh confirmation window instead.
  mutating func activateOrConfirm(
    at now: ContinuousClock.Instant = ContinuousClock().now
  ) -> Bool {
    if let deadline, now < deadline {
      self.deadline = nil
      return true
    }

    deadline = now.advanced(by: timeout)
    return false
  }

  mutating func cancel() {
    deadline = nil
  }

  mutating func expire(at now: ContinuousClock.Instant = ContinuousClock().now) {
    guard let deadline, now >= deadline else { return }
    self.deadline = nil
  }
}
