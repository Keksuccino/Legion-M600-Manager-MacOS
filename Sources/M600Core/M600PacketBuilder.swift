import Foundation

public struct DeviceWriteStep: Equatable, Sendable {
  public let report: M600OutputReport
  public let delayAfterMilliseconds: UInt64

  public init(report: M600OutputReport, delayAfterMilliseconds: UInt64) {
    self.report = report
    self.delayAfterMilliseconds = delayAfterMilliseconds
  }
}

public enum M600PacketBuilder {
  // Lenovo's macro writer has a 50 ms device guard on both sides of every
  // 0xFD chunk in addition to the HID helper's 100 ms post-write delay. The
  // doubled guard is essential between chunks: using only 100 ms makes the
  // M600 retain the first 57 bytes and silently discard every later chunk.
  private static let macroBeginDelayMilliseconds: UInt64 = 200
  private static let macroLengthDelayMilliseconds: UInt64 = 150
  private static let macroChunkDelayMilliseconds: UInt64 = 200

  public static func direct(
    _ bytes: [UInt8], transferLength: Int = M600Constants.reportLength
  ) -> M600OutputReport {
    precondition(bytes.count <= M600Constants.reportLength)
    precondition(transferLength >= bytes.count)
    let padded = bytes + Array(repeating: 0, count: M600Constants.reportLength - bytes.count)
    return M600OutputReport(bytes: padded, transferLength: transferLength)
  }

  public static func checksummed(_ bytes: [UInt8]) -> M600OutputReport {
    precondition(bytes.count <= M600Constants.reportLength - 1)
    var reportBytes = direct(bytes).bytes
    reportBytes[63] = reportBytes[0..<63].reduce(0, &+)
    return M600OutputReport(bytes: reportBytes)
  }

  public static func chunks(command: UInt8, data: [UInt8]) -> [M600OutputReport] {
    precondition(!data.isEmpty)
    let chunkCount = Int(ceil(Double(data.count) / Double(M600Constants.maximumChunkPayload)))
    precondition(chunkCount <= Int(UInt8.max))

    return (0..<chunkCount).map { zeroBasedIndex in
      let start = zeroBasedIndex * M600Constants.maximumChunkPayload
      let end = min(start + M600Constants.maximumChunkPayload, data.count)
      let chunk = Array(data[start..<end])
      return checksummed(
        [
          command,
          0,
          UInt8(zeroBasedIndex + 1),
          UInt8(chunkCount),
          UInt8(chunk.count),
        ] + chunk)
    }
  }

  public static func keyAction(deviceOffset: Int, matrix: [UInt8]) -> M600OutputReport {
    precondition((0..<11).contains(deviceOffset))
    precondition(matrix.count == 5)
    return checksummed([0x02, 0, UInt8(deviceOffset)] + matrix)
  }

  public static func lightingUpdate(data: [UInt8]) -> M600OutputReport {
    precondition(data.count == 24)
    // Lenovo's lighting handler uses the general checksummed chunk sender even
    // though both 12-byte zone programs fit in one report.
    return chunks(command: 0x25, data: data)[0]
  }

  public static func macroProgrammingSteps(macroID: UInt8, body: [UInt8], deviceOffset: Int)
    -> [DeviceWriteStep]
  {
    precondition(!body.isEmpty && body.count <= Int(UInt16.max))
    let length = UInt16(body.count)
    let chunkCount = Int(ceil(Double(body.count) / Double(M600Constants.maximumMacroChunkPayload)))
    var steps = [
      DeviceWriteStep(
        report: direct([0xFB, macroID]),
        delayAfterMilliseconds: macroBeginDelayMilliseconds
      ),
      DeviceWriteStep(
        report: direct([0xFE, macroID, UInt8(length >> 8), UInt8(length & 0xFF)]),
        delayAfterMilliseconds: macroLengthDelayMilliseconds
      ),
    ]

    for zeroBasedIndex in 0..<chunkCount {
      let index = UInt16(zeroBasedIndex + 1)
      let total = UInt16(chunkCount)
      let start = zeroBasedIndex * M600Constants.maximumMacroChunkPayload
      let end = min(start + M600Constants.maximumMacroChunkPayload, body.count)
      let chunk = Array(body[start..<end])
      let prefix: [UInt8] = [
        0xFD, macroID,
        UInt8(index >> 8), UInt8(index & 0xFF),
        UInt8(total >> 8), UInt8(total & 0xFF),
        UInt8(chunk.count),
      ]
      steps.append(
        DeviceWriteStep(
          report: direct(prefix + chunk),
          delayAfterMilliseconds: macroChunkDelayMilliseconds
        ))
    }
    steps.append(
      DeviceWriteStep(
        report: keyAction(deviceOffset: deviceOffset, matrix: [0xF2, macroID, 0, 0, 0]),
        delayAfterMilliseconds: 100
      ))
    return steps
  }

  // These transfer sizes exclude Windows hidapi's leading report-ID byte. In
  // particular, the M600 firmware ignores a commit padded to the full 64 bytes.
  public static let commit = direct([0x05, 0, 0], transferLength: 3)
  public static let batteryQuery = direct([0x0B], transferLength: 2)
  public static let flashCountQuery = direct([0x0D], transferLength: 2)
  public static let connectionQuery = direct([0x0E], transferLength: 3)
  public static let stealthQuery = direct([0x0A], transferLength: 3)
  public static let factoryRestoreBegin = direct([0x07, 0x05])
  public static let factoryRestoreConfirm = direct([0x07, 0x05, 0x01])
}
