import Foundation

public struct StoredProfiles: Codable, Sendable {
  public static let currentSchemaVersion = 3

  public var schemaVersion: Int
  public var selectedProfileID: UUID?
  public var profiles: [M600Profile]

  public init(
    schemaVersion: Int = Self.currentSchemaVersion,
    selectedProfileID: UUID?,
    profiles: [M600Profile]
  ) {
    self.schemaVersion = schemaVersion
    self.selectedProfileID = selectedProfileID
    self.profiles = profiles
  }

  private enum CodingKeys: String, CodingKey {
    case schemaVersion
    case selectedProfileID
    case profiles
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    schemaVersion =
      try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
    selectedProfileID = try container.decodeIfPresent(UUID.self, forKey: .selectedProfileID)
    profiles = try container.decode([M600Profile].self, forKey: .profiles)
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
    var stored = try JSONDecoder().decode(StoredProfiles.self, from: data)
    var requiresSave = false
    if stored.schemaVersion < 2 {
      migrateLegacyButtonOffsets(in: &stored)
      requiresSave = true
    }
    if stored.schemaVersion < 3 {
      migrateLegacyMacroMouseButtons(in: &stored)
      requiresSave = true
    }
    if requiresSave {
      try save(stored)
    }
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

  private func migrateLegacyButtonOffsets(in stored: inout StoredProfiles) {
    // Version 1 mistook WPF's MouseButton enum values for M600 device offsets,
    // swapping the persisted right-button and wheel-click identities. Swap only
    // those identities; each action and macro continues to belong to the row the
    // user originally edited.
    for profileIndex in stored.profiles.indices {
      for bindingIndex in stored.profiles[profileIndex].buttonBindings.indices {
        switch stored.profiles[profileIndex].buttonBindings[bindingIndex].button {
        case .right:
          stored.profiles[profileIndex].buttonBindings[bindingIndex].button = .middle
        case .middle:
          stored.profiles[profileIndex].buttonBindings[bindingIndex].button = .right
        default:
          break
        }
      }
    }
    stored.schemaVersion = 2
  }

  private func migrateLegacyMacroMouseButtons(in stored: inout StoredProfiles) {
    // Version 2 corrected physical button slots but still serialized macro
    // buttons using the mistaken WPF-value interpretation. Reassociate values
    // 2 and 3 with the semantic button the user selected.
    for profileIndex in stored.profiles.indices {
      for bindingIndex in stored.profiles[profileIndex].buttonBindings.indices {
        for stepIndex in stored.profiles[profileIndex].buttonBindings[bindingIndex].macro.steps
          .indices
        {
          migrateLegacyMacroMouseButton(
            in: &stored.profiles[profileIndex].buttonBindings[bindingIndex].macro.steps[stepIndex]
          )
        }
      }
    }
    stored.schemaVersion = StoredProfiles.currentSchemaVersion
  }

  private func migrateLegacyMacroMouseButton(in step: inout MacroStep) {
    switch step {
    case .mouseDown(button: .right): step = .mouseDown(button: .middle)
    case .mouseDown(button: .middle): step = .mouseDown(button: .right)
    case .mouseUp(button: .right): step = .mouseUp(button: .middle)
    case .mouseUp(button: .middle): step = .mouseUp(button: .right)
    default: break
    }
  }
}
