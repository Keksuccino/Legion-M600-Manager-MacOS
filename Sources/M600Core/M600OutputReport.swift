import Foundation

/// A report's 64-byte firmware buffer and the number of payload bytes sent over USB.
///
/// Lenovo uses full-length transfers for checksummed commands, but a few direct commands
/// deliberately use shorter transfers. Keeping both values prevents zero padding from
/// silently changing the meaning of those commands.
public struct M600OutputReport: Equatable, Sendable {
  public let bytes: [UInt8]
  public let transferLength: Int

  public init(bytes: [UInt8], transferLength: Int = M600Constants.reportLength) {
    precondition(bytes.count == M600Constants.reportLength)
    precondition((1...M600Constants.reportLength).contains(transferLength))
    self.bytes = bytes
    self.transferLength = transferLength
  }

  public var transferredBytes: ArraySlice<UInt8> {
    bytes.prefix(transferLength)
  }
}
