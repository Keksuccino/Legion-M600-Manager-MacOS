import Foundation

public enum M600Constants {
  public static let vendorID = 0x17EF
  public static let productID = 0x60E5
  public static let reportLength = 64
  public static let profileLength = 142
  public static let maximumChunkPayload = 58
  public static let maximumMacroChunkPayload = 57

  /// Lenovo's exact factory profile from `Lenny.Module.M600.Protocol.DefaultProfile`.
  /// Unknown fields are deliberately retained when a profile is encoded.
  public static let defaultProfileBytes: [UInt8] = [
    0, 0, 233, 133, 141, 231, 189, 174, 230, 150,
    135, 228, 187, 182, 49, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 176, 0, 0, 0, 0, 177, 2, 0,
    0, 0, 178, 0, 0, 0, 0, 181, 0, 0,
    0, 0, 182, 0, 0, 0, 0, 179, 0, 0,
    0, 0, 180, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 1, 0, 0, 0, 0, 193, 0, 0,
    0, 0, 208, 0, 0, 0, 0, 4, 0, 4,
    0, 9, 0, 9, 0, 18, 0, 18, 0, 38,
    0, 38, 0, 0, 1, 1, 3, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 204, 131, 1, 100,
    100, 1, 1, 0, 0, 0, 0, 0, 0, 0,
    1, 100, 100, 1, 1, 0, 0, 0, 0, 0,
    0, 0,
  ]
}
