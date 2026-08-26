import Foundation

public enum M600ProfileError: LocalizedError, Equatable {
  case invalidTemplateLength(Int)
  case invalidDPIStageCount(Int)
  case invalidDPI(Int)
  case invalidActiveDPIStage(Int)
  case invalidLightingZoneCount(Int)
  case invalidButtonBindingCount(Int)
  case missingButton(M600Button)
  case missingLeftClick
  case macroHasNoSteps(M600Button)
  case macroTooLarge(Int)

  public var errorDescription: String? {
    switch self {
    case .invalidTemplateLength(let length):
      return "The profile template is \(length) bytes; the M600 requires exactly 142."
    case .invalidDPIStageCount(let count):
      return "The M600 supports one through four DPI stages, not \(count)."
    case .invalidDPI(let dpi):
      return "\(dpi) DPI is unsupported. Choose a 100-DPI increment from 100 to 16,000."
    case .invalidActiveDPIStage(let index):
      return "DPI stage \(index + 1) is not enabled."
    case .invalidLightingZoneCount(let count):
      return "The M600 profile requires two lighting zones, not \(count)."
    case .invalidButtonBindingCount(let count):
      return "The M600 profile requires eight programmable button bindings, not \(count)."
    case .missingButton(let button):
      return "The profile is missing the binding for \(button.displayName)."
    case .missingLeftClick:
      return "At least one button must remain assigned to Left click."
    case .macroHasNoSteps(let button):
      return "The macro assigned to \(button.displayName) has no steps."
    case .macroTooLarge(let count):
      return "The encoded macro is \(count) bytes and exceeds the protocol's 65,535-byte limit."
    }
  }
}

public struct EncodedM600Profile: Equatable, Sendable {
  public let bytes: [UInt8]
  public let keyMatrices: [[UInt8]]
  public let macrosByDeviceOffset: [Int: [UInt8]]
}

public enum M600ProfileCodec {
  private static let nameRange = 2..<32
  private static let keyMatrixOffset = 32
  private static let dpiOffset = 87
  private static let lightingOffset = 118

  public static func validate(_ profile: M600Profile) throws {
    guard profile.rawTemplate.count == M600Constants.profileLength else {
      throw M600ProfileError.invalidTemplateLength(profile.rawTemplate.count)
    }
    guard (1...4).contains(profile.enabledDPIStageCount), profile.dpiStages.count >= 4 else {
      throw M600ProfileError.invalidDPIStageCount(profile.enabledDPIStageCount)
    }
    guard profile.activeDPIStage >= 0,
      profile.activeDPIStage < profile.enabledDPIStageCount,
      profile.defaultDPIStage >= 0,
      profile.defaultDPIStage < profile.enabledDPIStageCount
    else {
      throw M600ProfileError.invalidActiveDPIStage(profile.activeDPIStage)
    }
    guard profile.lightingZones.count == 2 else {
      throw M600ProfileError.invalidLightingZoneCount(profile.lightingZones.count)
    }
    let uniqueButtons = Set(profile.buttonBindings.map(\.button))
    guard profile.buttonBindings.count == M600Button.allCases.count,
      uniqueButtons.count == M600Button.allCases.count
    else {
      throw M600ProfileError.invalidButtonBindingCount(profile.buttonBindings.count)
    }
    for stage in profile.dpiStages.prefix(4) {
      guard DPITable.sensorIndex(forDPI: stage.x) != nil else {
        throw M600ProfileError.invalidDPI(stage.x)
      }
      guard DPITable.sensorIndex(forDPI: stage.y) != nil else {
        throw M600ProfileError.invalidDPI(stage.y)
      }
    }
    for button in M600Button.allCases
    where !profile.buttonBindings.contains(where: { $0.button == button }) {
      throw M600ProfileError.missingButton(button)
    }
    guard profile.buttonBindings.contains(where: { $0.action == .leftClick }) else {
      throw M600ProfileError.missingLeftClick
    }
    for binding in profile.buttonBindings
    where binding.action == .macro && binding.macro.steps.isEmpty {
      throw M600ProfileError.macroHasNoSteps(binding.button)
    }
  }

  public static func encode(_ profile: M600Profile) throws -> EncodedM600Profile {
    try validate(profile)
    var result = profile.rawTemplate

    result.replaceSubrange(nameRange, with: encodedName(profile.name))

    var matrices = stride(from: keyMatrixOffset, to: keyMatrixOffset + 55, by: 5).map {
      Array(result[$0..<($0 + 5)])
    }
    var macros: [Int: [UInt8]] = [:]
    for binding in profile.buttonBindings {
      if binding.action == .macro {
        matrices[binding.button.rawValue] = [0xF2, binding.button.macroID, 0, 0, 0]
        let macroBytes = encodeMacroBody(binding.macro.steps)
        let fullLength = 30 + macroBytes.count
        guard fullLength <= Int(UInt16.max) else {
          throw M600ProfileError.macroTooLarge(fullLength)
        }
        // The 30-byte prefix is an opaque reservation emitted by Lenovo's client.
        macros[binding.button.rawValue] = Array(repeating: 0, count: 30) + macroBytes
      } else if let bytes = binding.action.deviceBytes {
        matrices[binding.button.rawValue] = bytes
      }
    }
    for (index, matrix) in matrices.enumerated() {
      result.replaceSubrange(
        (keyMatrixOffset + index * 5)..<(keyMatrixOffset + index * 5 + 5), with: matrix)
    }

    for index in 0..<4 {
      let stage = profile.dpiStages[index]
      guard let x = DPITable.sensorIndex(forDPI: stage.x) else {
        throw M600ProfileError.invalidDPI(stage.x)
      }
      let effectiveY = stage.lockXY ? stage.x : stage.y
      guard let y = DPITable.sensorIndex(forDPI: effectiveY) else {
        throw M600ProfileError.invalidDPI(effectiveY)
      }
      let offset = dpiOffset + index * 4
      writeLittleEndian(x, to: &result, at: offset)
      writeLittleEndian(y, to: &result, at: offset + 2)
      result[107 + index] = stage.lockXY ? 1 : 0
    }
    result[103] = profile.pollingRate.deviceValue
    result[104] = UInt8(profile.activeDPIStage)
    result[105] = UInt8(profile.defaultDPIStage)
    result[106] = UInt8(profile.enabledDPIStageCount - 1)

    for (zoneIndex, zone) in profile.lightingZones.enumerated() {
      let offset = lightingOffset + zoneIndex * 12
      result.replaceSubrange(offset..<(offset + 12), with: lightingBytes(zone))
    }

    return EncodedM600Profile(bytes: result, keyMatrices: matrices, macrosByDeviceOffset: macros)
  }

  public static func encodeMacroBody(_ steps: [MacroStep]) -> [UInt8] {
    steps.flatMap { step -> [UInt8] in
      switch step {
      case .delay(let milliseconds):
        return [0x01, UInt8(milliseconds >> 8), UInt8(milliseconds & 0xFF)]
      case .keyDown(let usage): return [0x02, usage]
      case .keyUp(let usage): return [0x03, usage]
      case .mouseDown(let button): return [0x04, button.rawValue]
      case .mouseUp(let button): return [0x05, button.rawValue]
      case .wheelUp: return [0x08]
      case .wheelDown: return [0x09]
      }
    }
  }

  public static func lightingBytes(_ zone: LightingZone) -> [UInt8] {
    switch zone.effect {
    case .staticColor:
      return [
        3, 100, 0, zone.primaryColor.red, zone.primaryColor.green, zone.primaryColor.blue,
        0, 0, 0, 0, 0, 0,
      ]
    case .breathing:
      let alternateMode: UInt8 = zone.secondaryColor == .black ? 1 : 3
      return [
        2, 100, 0, 2, alternateMode, 0,
        zone.primaryColor.red, zone.primaryColor.green, zone.primaryColor.blue,
        zone.secondaryColor.red, zone.secondaryColor.green, zone.secondaryColor.blue,
      ]
    case .rainbow:
      return [1, 100, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0]
    case .random:
      return [3, 100, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    case .off:
      return [3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    }
  }

  private static func encodedName(_ name: String) -> [UInt8] {
    var utf8: [UInt8] = []
    for character in name {
      let next = Array(String(character).utf8)
      guard utf8.count + next.count < nameRange.count else { break }
      utf8.append(contentsOf: next)
    }
    return utf8 + Array(repeating: 0, count: nameRange.count - utf8.count)
  }

  private static func writeLittleEndian(_ value: UInt16, to bytes: inout [UInt8], at offset: Int) {
    bytes[offset] = UInt8(value & 0xFF)
    bytes[offset + 1] = UInt8(value >> 8)
  }
}
