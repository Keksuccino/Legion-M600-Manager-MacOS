import Foundation

public struct StoredProfiles: Codable, Sendable {
  public var selectedProfileID: UUID?
  public var profiles: [M600Profile]

  public init(selectedProfileID: UUID?, profiles: [M600Profile]) {
    self.selectedProfileID = selectedProfileID
    self.profiles = profiles
  }
}

public final class ProfileStore {
  public let fileURL: URL

  public init(fileURL: URL? = nil) {
    if let fileURL {
      self.fileURL = fileURL
    } else {
      let applicationSupport = FileManager.default.urls(
        for: .applicationSupportDirectory,
        in: .userDomainMask
      ).first!
      self.fileURL =
        applicationSupport
        .appendingPathComponent("Legion M600 Manager", isDirectory: true)
        .appendingPathComponent("profiles.json")
    }
  }

  public func load() throws -> StoredProfiles {
    guard FileManager.default.fileExists(atPath: fileURL.path) else {
      let profile = M600Profile()
      return StoredProfiles(selectedProfileID: profile.id, profiles: [profile])
    }
    let data = try Data(contentsOf: fileURL)
    let stored = try JSONDecoder().decode(StoredProfiles.self, from: data)
    guard !stored.profiles.isEmpty else {
      let profile = M600Profile()
      return StoredProfiles(selectedProfileID: profile.id, profiles: [profile])
    }
    return stored
  }

  public func save(_ stored: StoredProfiles) throws {
    let directory = fileURL.deletingLastPathComponent()
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    let data = try encoder.encode(stored)
    // Atomic replacement prevents a power loss from truncating every local profile.
    try data.write(to: fileURL, options: .atomic)
  }
}
