import Combine
import Foundation

public enum M600DeviceOperationError: LocalizedError, Equatable {
  case noFlashCounterResponse
  case commitNotConfirmed(previous: UInt32, current: UInt32)
  case lightingNotConfirmed(previous: UInt32, current: UInt32)

  public var errorDescription: String? {
    switch self {
    case .noFlashCounterResponse:
      return "The profile was sent, but the mouse did not answer the verification query."
    case .commitNotConfirmed(let previous, let current):
      return
        "The mouse answered, but its onboard flash counter remained at \(current) "
        + "(previously \(previous)). The profile was not committed."
    case .lightingNotConfirmed(let previous, let current):
      return
        "The profile was committed, but the mouse did not accept the lighting update "
        + "(flash counter remained at \(current), previously \(previous))."
    }
  }
}

@MainActor
public final class M600DeviceController: ObservableObject {
  @Published public private(set) var isConnected = false
  @Published public private(set) var productName = "Lenovo Legion M600"
  @Published public private(set) var batteryPercentage: Int?
  @Published public private(set) var batteryVoltageMillivolts: UInt16?
  @Published public private(set) var flashCount: UInt32?
  @Published public private(set) var wirelessConnectionActive: Bool?
  @Published public private(set) var stealthModeActive: Bool?
  @Published public private(set) var activeHardwareDPIStage: Int?
  @Published public private(set) var isBusy = false
  @Published public private(set) var operationDescription: String?
  @Published public private(set) var lastSuccess: String?
  @Published public private(set) var lastError: String?

  private let transport: any M600ReportTransport
  private let wait: (UInt64) async throws -> Void
  private var flashResponseGeneration = 0

  public convenience init() {
    self.init(transport: M600HIDTransport())
  }

  public convenience init(transport: any M600ReportTransport) {
    self.init(
      transport: transport,
      wait: { milliseconds in
        try await Task.sleep(nanoseconds: milliseconds * 1_000_000)
      }
    )
  }

  init(transport: any M600ReportTransport, wait: @escaping (UInt64) async throws -> Void) {
    self.transport = transport
    self.wait = wait
    transport.onConnectionChange = { [weak self] connected, name in
      guard let self else { return }
      self.isConnected = connected
      if let name { self.productName = name }
      if connected {
        Task { await self.refreshReadOnlyStatus() }
      } else {
        self.batteryPercentage = nil
        self.batteryVoltageMillivolts = nil
        self.wirelessConnectionActive = nil
        self.stealthModeActive = nil
        self.lastSuccess = nil
      }
    }
    transport.onInputReport = { [weak self] report in self?.handle(report) }
    transport.onError = { [weak self] error in self?.lastError = error.localizedDescription }
    do {
      try transport.start()
    } catch {
      lastError = error.localizedDescription
    }
  }

  public func clearError() {
    lastError = nil
  }

  public func clearApplyConfirmation() {
    lastSuccess = nil
  }

  public func refreshReadOnlyStatus() async {
    guard isConnected, !isBusy else { return }
    // The M600 can drop reports when another command is interleaved during its
    // mandatory delays. Treat status reads as a device operation so Apply and
    // factory restore cannot overlap a connection-triggered refresh.
    isBusy = true
    operationDescription = "Refreshing status"
    defer {
      isBusy = false
      operationDescription = nil
    }
    do {
      try transport.send(M600PacketBuilder.batteryQuery)
      try await delay(milliseconds: 75)
      try transport.send(M600PacketBuilder.flashCountQuery)
      try await delay(milliseconds: 75)
      try transport.send(M600PacketBuilder.connectionQuery)
      try await delay(milliseconds: 75)
      try transport.send(M600PacketBuilder.stealthQuery)
    } catch {
      lastError = error.localizedDescription
    }
  }

  public func apply(_ profile: M600Profile) async {
    guard isConnected, !isBusy else { return }
    isBusy = true
    lastSuccess = nil
    lastError = nil
    defer {
      isBusy = false
      operationDescription = nil
    }

    do {
      let encoded = try M600ProfileCodec.encode(profile)
      operationDescription = "Writing profile"
      for report in M600PacketBuilder.chunks(command: 0x01, data: encoded.bytes) {
        try transport.send(report)
        // Lenovo's chunk helper waits 100 ms after the HID write and its caller
        // waits another 50 ms. The device drops later writes if this is shortened.
        try await delay(milliseconds: 150)
      }

      for deviceOffset in 0..<11 {
        operationDescription = "Writing button \(deviceOffset + 1) of 11"
        if let macroBody = encoded.macrosByDeviceOffset[deviceOffset],
          let button = M600Button(rawValue: deviceOffset)
        {
          for step in M600PacketBuilder.macroProgrammingSteps(
            macroID: button.macroID,
            body: macroBody,
            deviceOffset: deviceOffset
          ) {
            try transport.send(step.report)
            try await delay(milliseconds: step.delayAfterMilliseconds)
          }
        } else {
          try transport.send(
            M600PacketBuilder.keyAction(
              deviceOffset: deviceOffset,
              matrix: encoded.keyMatrices[deviceOffset]
            ))
          try await delay(milliseconds: 100)
        }
      }

      operationDescription = "Verifying staged profile"
      let stagedFlashCount = try await requestFreshFlashCount()

      operationDescription = "Committing to onboard memory"
      try transport.send(M600PacketBuilder.commit)
      try await delay(milliseconds: 100)

      operationDescription = "Verifying onboard memory"
      let committedFlashCount = try await requestFreshFlashCount()
      if committedFlashCount == stagedFlashCount {
        throw M600DeviceOperationError.commitNotConfirmed(
          previous: stagedFlashCount,
          current: committedFlashCount
        )
      }

      // The full 142-byte profile persists the RGB records, but the Windows UI
      // also sends command 0x25 to make those records active immediately. Keep
      // this after the independently verified profile commit: otherwise a 0x25
      // flash-counter change could conceal a rejected 0x05 commit.
      operationDescription = "Activating lighting"
      try transport.send(M600PacketBuilder.lightingUpdate(data: encoded.lightingData))
      try await delay(milliseconds: 150)

      operationDescription = "Verifying lighting"
      let lightingFlashCount = try await requestFreshFlashCount()
      guard lightingFlashCount != committedFlashCount else {
        throw M600DeviceOperationError.lightingNotConfirmed(
          previous: committedFlashCount,
          current: lightingFlashCount
        )
      }
      lastSuccess = "Applied profile and lighting · flash #\(lightingFlashCount)"
    } catch {
      lastError = error.localizedDescription
    }
  }

  public func restoreFactorySettings() async {
    guard isConnected, !isBusy else { return }
    isBusy = true
    lastSuccess = nil
    lastError = nil
    operationDescription = "Restoring factory settings"
    defer {
      isBusy = false
      operationDescription = nil
    }
    do {
      try transport.send(M600PacketBuilder.factoryRestoreBegin)
      try await delay(milliseconds: 100)
      try transport.send(M600PacketBuilder.factoryRestoreConfirm)
      try await delay(milliseconds: 250)
      try transport.send(M600PacketBuilder.flashCountQuery)
    } catch {
      lastError = error.localizedDescription
    }
  }

  private func handle(_ report: M600InputReport) {
    switch report {
    case .battery(let voltage, let rawPercentage):
      batteryVoltageMillivolts = voltage
      batteryPercentage = min(100, max(0, Int(rawPercentage)))
    case .flashCount(let count):
      flashCount = count
      flashResponseGeneration &+= 1
    case .wirelessConnection(let active):
      wirelessConnectionActive = active
    case .dpiChanged(_, let stage, _, _):
      activeHardwareDPIStage = Int(stage)
    case .stealth(let enabled):
      stealthModeActive = enabled
    case .acknowledgement, .unknown:
      break
    }
  }

  private func delay(milliseconds: UInt64) async throws {
    try await wait(milliseconds)
  }

  private func requestFreshFlashCount() async throws -> UInt32 {
    for _ in 0..<3 {
      let generationBeforeQuery = flashResponseGeneration
      try transport.send(M600PacketBuilder.flashCountQuery)
      for _ in 0..<10 {
        try await delay(milliseconds: 50)
        if flashResponseGeneration != generationBeforeQuery, let flashCount {
          return flashCount
        }
      }
    }
    throw M600DeviceOperationError.noFlashCounterResponse
  }
}
