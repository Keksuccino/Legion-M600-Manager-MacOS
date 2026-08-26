import Foundation

public enum M600ConnectionMode: String, Codable, Sendable {
  case wired
  case wireless24GHz
  case bluetooth
  case unknown
}

public enum M600InputReport: Equatable, Sendable {
  case dpiChanged(profile: UInt8, stage: UInt8, xSensorIndex: UInt8, ySensorIndex: UInt8)
  case stealth(enabled: Bool)
  case battery(voltageMillivolts: UInt16, rawPercentage: UInt8)
  case flashCount(UInt32)
  case wirelessConnection(Bool)
  case acknowledgement(command: UInt8, bytes: [UInt8])
  case unknown(command: UInt8, bytes: [UInt8])

  public var command: UInt8 {
    switch self {
    case .dpiChanged: return 0x04
    case .stealth: return 0x0A
    case .battery: return 0x0B
    case .flashCount: return 0x0D
    case .wirelessConnection: return 0x0E
    case .acknowledgement(let command, _), .unknown(let command, _): return command
    }
  }
}

public enum M600InputReportParser {
  public static func parse(_ bytes: [UInt8]) -> M600InputReport? {
    guard let command = bytes.first else { return nil }
    switch command {
    case 0x04 where bytes.count >= 6 && bytes[1] == 0:
      return .dpiChanged(
        profile: bytes[2],
        stage: bytes[3],
        xSensorIndex: bytes[4],
        ySensorIndex: bytes[5]
      )
    case 0x0A where bytes.count >= 3:
      return .stealth(enabled: bytes[2] != 0)
    case 0x0B where bytes.count >= 5:
      let voltage = UInt16(bytes[2]) | (UInt16(bytes[3]) << 8)
      return .battery(voltageMillivolts: voltage, rawPercentage: bytes[4])
    case 0x0D where bytes.count >= 5:
      let count = UInt32(bytes[2]) | (UInt32(bytes[3]) << 8) | (UInt32(bytes[4]) << 16)
      return .flashCount(count)
    case 0x0E where bytes.count >= 3:
      return .wirelessConnection(bytes[2] != 0)
    case 0xFB, 0xFD, 0xFE, 0x02, 0x05, 0x07, 0x25:
      return .acknowledgement(command: command, bytes: bytes)
    default:
      return .unknown(command: command, bytes: bytes)
    }
  }
}
