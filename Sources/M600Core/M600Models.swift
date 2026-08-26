import Foundation

public struct RGBColor: Codable, Hashable, Sendable {
  public var red: UInt8
  public var green: UInt8
  public var blue: UInt8

  public init(red: UInt8, green: UInt8, blue: UInt8) {
    self.red = red
    self.green = green
    self.blue = blue
  }

  public static let legionBlue = RGBColor(red: 0, green: 180, blue: 255)
  public static let black = RGBColor(red: 0, green: 0, blue: 0)
}

public enum LightingEffect: String, CaseIterable, Codable, Identifiable, Sendable {
  case staticColor
  case breathing
  case rainbow
  case random
  case off

  public var id: String { rawValue }

  public var displayName: String {
    switch self {
    case .staticColor: return "Static"
    case .breathing: return "Breathing"
    case .rainbow: return "Rainbow"
    case .random: return "Random"
    case .off: return "Off"
    }
  }
}

public struct LightingZone: Codable, Hashable, Sendable {
  public var effect: LightingEffect
  public var primaryColor: RGBColor
  public var secondaryColor: RGBColor

  public init(
    effect: LightingEffect = .rainbow,
    primaryColor: RGBColor = .legionBlue,
    secondaryColor: RGBColor = .black
  ) {
    self.effect = effect
    self.primaryColor = primaryColor
    self.secondaryColor = secondaryColor
  }
}

public enum PollingRate: Int, CaseIterable, Codable, Identifiable, Sendable {
  case hz125 = 125
  case hz250 = 250
  case hz500 = 500
  case hz1000 = 1000

  public var id: Int { rawValue }
  public var displayName: String { "\(rawValue) Hz" }

  public var deviceValue: UInt8 {
    switch self {
    case .hz125: return 0
    case .hz250: return 2
    case .hz500: return 4
    case .hz1000: return 8
    }
  }
}

public struct DPIStage: Codable, Hashable, Sendable {
  public var x: Int
  public var y: Int
  public var lockXY: Bool

  public init(x: Int, y: Int? = nil, lockXY: Bool = true) {
    self.x = x
    self.y = y ?? x
    self.lockXY = lockXY
  }
}

public enum M600Button: Int, CaseIterable, Codable, Identifiable, Sendable {
  case left = 0
  case middle = 2
  case right = 1
  case rearSide = 5
  case frontSide = 6
  case rightRear = 7
  case rightFront = 8
  case dpi = 9

  public var id: Int { rawValue }

  public var displayName: String {
    switch self {
    case .left: return "Left Mouse Button"
    case .middle: return "Middle Mouse Button"
    case .right: return "Right Mouse Button"
    case .rearSide: return "Left Side Front Button"
    case .frontSide: return "Left Side Back Button"
    case .rightRear: return "Right Side Front Button"
    case .rightFront: return "Right Side Back Button"
    case .dpi: return "Top Button"
    }
  }

  public var macroID: UInt8 {
    switch self {
    case .left: return 1
    case .right: return 2
    case .middle: return 3
    case .rearSide: return 4
    case .frontSide: return 5
    case .rightRear: return 6
    case .rightFront: return 7
    case .dpi: return 8
    }
  }

  public var defaultAction: ButtonActionKind {
    switch self {
    case .left: return .leftClick
    case .middle: return .middleClick
    case .right: return .rightClick
    case .rearSide: return .forward
    case .frontSide: return .back
    case .rightRear, .rightFront: return .disabled
    case .dpi: return .dpiCycle
    }
  }
}

public enum ButtonActionKind: String, CaseIterable, Codable, Identifiable, Sendable {
  case leftClick
  case middleClick
  case rightClick
  case forward
  case back
  case dpiCycle
  case playPause
  case previousTrack
  case nextTrack
  case volumeUp
  case volumeDown
  case mute
  case disabled
  case macro

  public var id: String { rawValue }

  public var displayName: String {
    switch self {
    case .leftClick: return "Left click"
    case .middleClick: return "Middle click"
    case .rightClick: return "Right click"
    case .forward: return "Forward"
    case .back: return "Back"
    case .dpiCycle: return "Cycle DPI"
    case .playPause: return "Play / Pause"
    case .previousTrack: return "Previous track"
    case .nextTrack: return "Next track"
    case .volumeUp: return "Volume up"
    case .volumeDown: return "Volume down"
    case .mute: return "Mute"
    case .disabled: return "Disabled"
    case .macro: return "Macro"
    }
  }

  public var deviceBytes: [UInt8]? {
    let code: UInt8
    switch self {
    case .leftClick: code = 0xB0
    case .rightClick: code = 0xB1
    case .middleClick: code = 0xB2
    case .forward: code = 0xB3
    case .back: code = 0xB4
    case .dpiCycle: code = 0xC1
    case .playPause: code = 0x93
    case .previousTrack: code = 0x95
    case .nextTrack: code = 0x96
    case .volumeUp: code = 0x90
    case .volumeDown: code = 0x91
    case .mute: code = 0x92
    case .disabled: code = 0x00
    case .macro: return nil
    }
    return [code, 0, 0, 0, 0]
  }
}

public enum MacroMouseButton: UInt8, CaseIterable, Codable, Identifiable, Sendable {
  case left = 1
  case middle = 3
  case right = 2
  case back = 4
  case forward = 5

  public var id: UInt8 { rawValue }
  public var displayName: String { String(describing: self).capitalized }
}

public enum MacroStep: Codable, Hashable, Sendable {
  case delay(milliseconds: UInt16)
  case keyDown(usage: UInt8)
  case keyUp(usage: UInt8)
  case mouseDown(button: MacroMouseButton)
  case mouseUp(button: MacroMouseButton)
  case wheelUp
  case wheelDown

  public var displayName: String {
    switch self {
    case .delay(let milliseconds): return "Wait \(milliseconds) ms"
    case .keyDown(let usage): return "Key down · \(HIDKeyNames.name(for: usage))"
    case .keyUp(let usage): return "Key up · \(HIDKeyNames.name(for: usage))"
    case .mouseDown(let button): return "Mouse down · \(button.displayName)"
    case .mouseUp(let button): return "Mouse up · \(button.displayName)"
    case .wheelUp: return "Wheel up"
    case .wheelDown: return "Wheel down"
    }
  }
}

public struct MacroDefinition: Codable, Hashable, Sendable {
  public var name: String
  public var steps: [MacroStep]

  public init(name: String = "New Macro", steps: [MacroStep] = []) {
    self.name = name
    self.steps = steps
  }
}

public struct ButtonBinding: Codable, Hashable, Identifiable, Sendable {
  public var button: M600Button
  public var action: ButtonActionKind
  public var macro: MacroDefinition

  public var id: Int { button.rawValue }

  public init(button: M600Button, action: ButtonActionKind, macro: MacroDefinition = .init()) {
    self.button = button
    self.action = action
    self.macro = macro
  }
}

public struct M600Profile: Codable, Hashable, Identifiable, Sendable {
  public var id: UUID
  public var name: String
  public var dpiStages: [DPIStage]
  public var enabledDPIStageCount: Int
  public var activeDPIStage: Int
  public var defaultDPIStage: Int
  public var pollingRate: PollingRate
  public var buttonBindings: [ButtonBinding]
  public var lightingZones: [LightingZone]
  public var rawTemplate: [UInt8]

  public init(
    id: UUID = UUID(),
    name: String = "Default",
    dpiStages: [DPIStage] = [800, 1600, 3200, 6400].map { DPIStage(x: $0) },
    enabledDPIStageCount: Int = 4,
    activeDPIStage: Int = 0,
    defaultDPIStage: Int = 0,
    pollingRate: PollingRate = .hz1000,
    buttonBindings: [ButtonBinding]? = nil,
    lightingZones: [LightingZone] = [LightingZone(), LightingZone()],
    rawTemplate: [UInt8] = M600Constants.defaultProfileBytes
  ) {
    self.id = id
    self.name = name
    self.dpiStages = dpiStages
    self.enabledDPIStageCount = enabledDPIStageCount
    self.activeDPIStage = activeDPIStage
    self.defaultDPIStage = defaultDPIStage
    self.pollingRate = pollingRate
    self.buttonBindings =
      buttonBindings
      ?? M600Button.allCases.map {
        ButtonBinding(button: $0, action: $0.defaultAction)
      }
    self.lightingZones = lightingZones
    self.rawTemplate = rawTemplate
  }
}

public enum HIDKeyNames {
  public static let common: [(name: String, usage: UInt8)] = [
    ("A", 0x04), ("B", 0x05), ("C", 0x06), ("D", 0x07), ("E", 0x08),
    ("F", 0x09), ("G", 0x0A), ("H", 0x0B), ("I", 0x0C), ("J", 0x0D),
    ("K", 0x0E), ("L", 0x0F), ("M", 0x10), ("N", 0x11), ("O", 0x12),
    ("P", 0x13), ("Q", 0x14), ("R", 0x15), ("S", 0x16), ("T", 0x17),
    ("U", 0x18), ("V", 0x19), ("W", 0x1A), ("X", 0x1B), ("Y", 0x1C),
    ("Z", 0x1D), ("1", 0x1E), ("2", 0x1F), ("3", 0x20), ("4", 0x21),
    ("5", 0x22), ("6", 0x23), ("7", 0x24), ("8", 0x25), ("9", 0x26),
    ("0", 0x27), ("Return", 0x28), ("Escape", 0x29), ("Delete", 0x2A),
    ("Tab", 0x2B), ("Space", 0x2C), ("F1", 0x3A), ("F2", 0x3B),
    ("F3", 0x3C), ("F4", 0x3D), ("F5", 0x3E), ("F6", 0x3F),
    ("F7", 0x40), ("F8", 0x41), ("F9", 0x42), ("F10", 0x43),
    ("F11", 0x44), ("F12", 0x45), ("Right Arrow", 0x4F),
    ("Left Arrow", 0x50), ("Down Arrow", 0x51), ("Up Arrow", 0x52),
    ("Left Control", 0xE0), ("Left Shift", 0xE1), ("Left Option", 0xE2),
    ("Left Command", 0xE3), ("Right Control", 0xE4), ("Right Shift", 0xE5),
    ("Right Option", 0xE6), ("Right Command", 0xE7),
  ]

  public static func name(for usage: UInt8) -> String {
    common.first(where: { $0.usage == usage })?.name
      ?? String(format: "HID 0x%02X", usage)
  }
}
