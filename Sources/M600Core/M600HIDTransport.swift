import CoreFoundation
import Foundation
import IOKit
import IOKit.hid

public enum M600TransportError: LocalizedError {
  case managerOpenFailed(IOReturn)
  case deviceOpenFailed(IOReturn)
  case noConfigurationInterface
  case invalidReportBufferLength(Int)
  case invalidTransferLength(Int)
  case writeFailed(IOReturn)

  public var errorDescription: String? {
    switch self {
    case .managerOpenFailed(let code): return "IOKit could not start HID discovery (\(hex(code)))."
    case .deviceOpenFailed(let code):
      return "macOS could not open the M600 configuration interface (\(hex(code)))."
    case .noConfigurationInterface: return "The M600 configuration interface is not connected."
    case .invalidReportBufferLength(let length):
      return "A HID report buffer was \(length) bytes; it must be exactly 64."
    case .invalidTransferLength(let length):
      return "A HID transfer requested \(length) bytes; it must be between 1 and 64."
    case .writeFailed(let code): return "The M600 rejected a HID output report (\(hex(code)))."
    }
  }

  private func hex(_ value: IOReturn) -> String {
    String(format: "0x%08X", UInt32(bitPattern: value))
  }
}

@MainActor
public protocol M600ReportTransport: AnyObject {
  var onConnectionChange: ((Bool, String?) -> Void)? { get set }
  var onInputReport: ((M600InputReport) -> Void)? { get set }
  var onError: ((Error) -> Void)? { get set }

  func start() throws
  func send(_ report: M600OutputReport) throws
}

@MainActor
public final class M600HIDTransport: M600ReportTransport {
  public private(set) var isConnected = false
  public private(set) var productName: String?
  public var onConnectionChange: ((Bool, String?) -> Void)?
  public var onInputReport: ((M600InputReport) -> Void)?
  public var onError: ((Error) -> Void)?

  private let manager: IOHIDManager
  private let inputBuffer: UnsafeMutablePointer<UInt8>
  private var device: IOHIDDevice?
  private var started = false

  public init() {
    manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
    inputBuffer = .allocate(capacity: M600Constants.reportLength)
    inputBuffer.initialize(repeating: 0, count: M600Constants.reportLength)
  }

  deinit {
    if started {
      IOHIDManagerUnscheduleFromRunLoop(
        manager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
      IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
    }
    if let device {
      IOHIDDeviceClose(device, IOOptionBits(kIOHIDOptionsTypeNone))
    }
    inputBuffer.deinitialize(count: M600Constants.reportLength)
    inputBuffer.deallocate()
  }

  public func start() throws {
    guard !started else { return }
    started = true

    let context = Unmanaged.passUnretained(self).toOpaque()
    IOHIDManagerRegisterDeviceMatchingCallback(manager, m600DeviceMatchedCallback, context)
    IOHIDManagerRegisterDeviceRemovalCallback(manager, m600DeviceRemovedCallback, context)
    let matching: [String: Any] = [
      kIOHIDVendorIDKey: M600Constants.vendorID,
      kIOHIDProductIDKey: M600Constants.productID,
      kIOHIDPrimaryUsagePageKey: 0x01,
      kIOHIDPrimaryUsageKey: 0x00,
    ]
    IOHIDManagerSetDeviceMatching(manager, matching as CFDictionary)
    IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)

    let result = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
    guard result == kIOReturnSuccess else {
      IOHIDManagerUnscheduleFromRunLoop(
        manager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
      started = false
      throw M600TransportError.managerOpenFailed(result)
    }
  }

  public func send(_ report: M600OutputReport) throws {
    guard report.bytes.count == M600Constants.reportLength else {
      throw M600TransportError.invalidReportBufferLength(report.bytes.count)
    }
    guard (1...M600Constants.reportLength).contains(report.transferLength) else {
      throw M600TransportError.invalidTransferLength(report.transferLength)
    }
    guard let device else { throw M600TransportError.noConfigurationInterface }

    let result = report.bytes.withUnsafeBytes { rawBuffer -> IOReturn in
      let pointer = rawBuffer.bindMemory(to: UInt8.self).baseAddress!
      // Report ID zero is passed separately on macOS. The transfer length is
      // intentionally not derived from the padded backing buffer: Lenovo's
      // commit command is accepted by IOKit but ignored by the mouse if padded.
      return IOHIDDeviceSetReport(
        device,
        kIOHIDReportTypeOutput,
        CFIndex(0),
        pointer,
        report.transferLength
      )
    }
    guard result == kIOReturnSuccess else { throw M600TransportError.writeFailed(result) }
  }

  fileprivate func handleMatchedDevice(_ candidate: IOHIDDevice) {
    guard device == nil, isConfigurationInterface(candidate) else { return }

    let result = IOHIDDeviceOpen(candidate, IOOptionBits(kIOHIDOptionsTypeNone))
    guard result == kIOReturnSuccess else {
      onError?(M600TransportError.deviceOpenFailed(result))
      return
    }
    device = candidate
    productName = stringProperty(candidate, key: kIOHIDProductKey) ?? "Lenovo Legion M600"
    let context = Unmanaged.passUnretained(self).toOpaque()
    IOHIDDeviceRegisterInputReportCallback(
      candidate,
      inputBuffer,
      M600Constants.reportLength,
      m600InputReportCallback,
      context
    )
    isConnected = true
    onConnectionChange?(true, productName)
  }

  fileprivate func handleRemovedDevice(_ candidate: IOHIDDevice) {
    guard let device, objectIdentity(device) == objectIdentity(candidate) else { return }
    IOHIDDeviceClose(device, IOOptionBits(kIOHIDOptionsTypeNone))
    self.device = nil
    isConnected = false
    productName = nil
    onConnectionChange?(false, nil)
  }

  fileprivate func handleInput(bytes: [UInt8]) {
    guard let report = M600InputReportParser.parse(bytes) else { return }
    onInputReport?(report)
  }

  private func isConfigurationInterface(_ device: IOHIDDevice) -> Bool {
    let usage = integerProperty(device, key: kIOHIDPrimaryUsageKey)
    let outputLength = integerProperty(device, key: kIOHIDMaxOutputReportSizeKey)
    return usage == 0 && outputLength >= M600Constants.reportLength
  }

  private func integerProperty(_ device: IOHIDDevice, key: String) -> Int {
    guard let value = IOHIDDeviceGetProperty(device, key as CFString) else { return -1 }
    return (value as? NSNumber)?.intValue ?? -1
  }

  private func stringProperty(_ device: IOHIDDevice, key: String) -> String? {
    IOHIDDeviceGetProperty(device, key as CFString) as? String
  }

  private func objectIdentity(_ device: IOHIDDevice) -> UnsafeMutableRawPointer {
    Unmanaged.passUnretained(device).toOpaque()
  }
}

private func m600DeviceMatchedCallback(
  context: UnsafeMutableRawPointer?,
  result: IOReturn,
  sender: UnsafeMutableRawPointer?,
  device: IOHIDDevice
) {
  guard result == kIOReturnSuccess, let context else { return }
  let transport = Unmanaged<M600HIDTransport>.fromOpaque(context).takeUnretainedValue()
  Task { @MainActor in transport.handleMatchedDevice(device) }
}

private func m600DeviceRemovedCallback(
  context: UnsafeMutableRawPointer?,
  result: IOReturn,
  sender: UnsafeMutableRawPointer?,
  device: IOHIDDevice
) {
  guard result == kIOReturnSuccess, let context else { return }
  let transport = Unmanaged<M600HIDTransport>.fromOpaque(context).takeUnretainedValue()
  Task { @MainActor in transport.handleRemovedDevice(device) }
}

private func m600InputReportCallback(
  context: UnsafeMutableRawPointer?,
  result: IOReturn,
  sender: UnsafeMutableRawPointer?,
  type: IOHIDReportType,
  reportID: UInt32,
  report: UnsafeMutablePointer<UInt8>,
  reportLength: CFIndex
) {
  guard result == kIOReturnSuccess, let context, reportLength > 0 else { return }
  let bytes = Array(UnsafeBufferPointer(start: report, count: reportLength))
  let transport = Unmanaged<M600HIDTransport>.fromOpaque(context).takeUnretainedValue()
  Task { @MainActor in transport.handleInput(bytes: bytes) }
}
