import XCTest

@testable import M600Core

final class M600CoreTests: XCTestCase {
  func testRecoveredConstantsAreComplete() {
    XCTAssertEqual(M600Constants.defaultProfileBytes.count, 142)
    XCTAssertEqual(DPITable.values.count, 160)
    XCTAssertEqual(DPITable.sensorIndices.count, 160)
    XCTAssertEqual(DPITable.sensorIndex(forDPI: 100), 0)
    XCTAssertEqual(DPITable.sensorIndex(forDPI: 800), 9)
    XCTAssertEqual(DPITable.sensorIndex(forDPI: 15_100), 180)
    XCTAssertEqual(DPITable.sensorIndex(forDPI: 16_000), 189)
    XCTAssertEqual(DPITable.dpi(forSensorIndex: 37), 3_100)
    XCTAssertNil(DPITable.sensorIndex(forDPI: 50))
    XCTAssertNil(DPITable.sensorIndex(forDPI: 16_100))
  }

  func testRightAndMiddleMappingsMatchRecoveredWindowsLayout() {
    XCTAssertEqual(M600Button.right.rawValue, 1)
    XCTAssertEqual(M600Button.right.macroID, 2)
    XCTAssertEqual(M600Button.middle.rawValue, 2)
    XCTAssertEqual(M600Button.middle.macroID, 3)
    XCTAssertEqual(ButtonActionKind.rightClick.deviceBytes, [0xB1, 0, 0, 0, 0])
    XCTAssertEqual(ButtonActionKind.middleClick.deviceBytes, [0xB2, 0, 0, 0, 0])
    XCTAssertEqual(MacroMouseButton.right.rawValue, 2)
    XCTAssertEqual(MacroMouseButton.middle.rawValue, 3)
  }

  func testPhysicalButtonDisplayNames() {
    XCTAssertEqual(
      M600Button.allCases.map(\.displayName),
      [
        "Left Mouse Button",
        "Middle Mouse Button",
        "Right Mouse Button",
        "Left Side Front Button",
        "Left Side Back Button",
        "Right Side Front Button",
        "Right Side Back Button",
        "Top Button",
      ]
    )
  }

  func testProfileEncodingPreservesShapeAndHiddenButtons() throws {
    var profile = M600Profile(name: "Mac Profile")
    profile.pollingRate = .hz500
    profile.activeDPIStage = 2
    let encoded = try M600ProfileCodec.encode(profile)

    XCTAssertEqual(encoded.bytes.count, 142)
    XCTAssertEqual(Array(encoded.bytes[2..<13]), Array("Mac Profile".utf8))
    XCTAssertEqual(encoded.bytes[103], 4)
    XCTAssertEqual(encoded.bytes[104], 2)
    XCTAssertEqual(Array(encoded.bytes[47..<52]), [0xB5, 0, 0, 0, 0])
    XCTAssertEqual(Array(encoded.bytes[52..<57]), [0xB6, 0, 0, 0, 0])
    XCTAssertEqual(Array(encoded.bytes[82..<87]), [0xD0, 0, 0, 0, 0])
    XCTAssertEqual(encoded.keyMatrices.count, 11)
  }

  func testProfileRequiresLeftClick() {
    var profile = M600Profile()
    for index in profile.buttonBindings.indices {
      profile.buttonBindings[index].action = .disabled
    }
    XCTAssertThrowsError(try M600ProfileCodec.encode(profile)) { error in
      XCTAssertEqual(error as? M600ProfileError, .missingLeftClick)
    }
  }

  func testProfileRejectsDuplicateButtonBindings() {
    var profile = M600Profile()
    profile.buttonBindings[1].button = .left
    XCTAssertThrowsError(try M600ProfileCodec.encode(profile)) { error in
      XCTAssertEqual(
        error as? M600ProfileError,
        .invalidButtonBindingCount(M600Button.allCases.count)
      )
    }
  }

  func testProfileNameDoesNotSplitUTF8Characters() throws {
    let encoded = try M600ProfileCodec.encode(M600Profile(name: String(repeating: "🙂", count: 10)))
    let nameBytes = encoded.bytes[2..<32].prefix(while: { $0 != 0 })
    XCTAssertNotNil(String(bytes: nameBytes, encoding: .utf8))
    XCTAssertEqual(nameBytes.count, 28)
  }

  func testLightingPacketsMatchRecoveredWindowsImplementation() {
    let staticZone = LightingZone(
      effect: .staticColor,
      primaryColor: RGBColor(red: 1, green: 2, blue: 3)
    )
    XCTAssertEqual(
      M600ProfileCodec.lightingBytes(staticZone),
      [3, 100, 0, 1, 2, 3, 0, 0, 0, 0, 0, 0]
    )
    let breathing = LightingZone(
      effect: .breathing,
      primaryColor: RGBColor(red: 4, green: 5, blue: 6),
      secondaryColor: .black
    )
    XCTAssertEqual(
      M600ProfileCodec.lightingBytes(breathing),
      [2, 100, 0, 2, 1, 0, 4, 5, 6, 0, 0, 0]
    )
  }

  func testRightButtonAndBothLightingZonesReachEncodedProfile() throws {
    var profile = M600Profile()
    let rightButtonIndex = profile.buttonBindings.firstIndex(where: { $0.button == .right })!
    profile.buttonBindings[rightButtonIndex].action = .volumeDown
    profile.lightingZones[0] = LightingZone(
      effect: .staticColor,
      primaryColor: RGBColor(red: 10, green: 20, blue: 30)
    )
    profile.lightingZones[1] = LightingZone(
      effect: .breathing,
      primaryColor: RGBColor(red: 40, green: 50, blue: 60),
      secondaryColor: RGBColor(red: 70, green: 80, blue: 90)
    )

    let encoded = try M600ProfileCodec.encode(profile)
    XCTAssertEqual(Array(encoded.bytes[37..<42]), [0x91, 0, 0, 0, 0])
    XCTAssertEqual(
      Array(encoded.bytes[118..<130]),
      [3, 100, 0, 10, 20, 30, 0, 0, 0, 0, 0, 0]
    )
    XCTAssertEqual(
      Array(encoded.bytes[130..<142]),
      [2, 100, 0, 2, 3, 0, 40, 50, 60, 70, 80, 90]
    )
    XCTAssertEqual(encoded.lightingData, Array(encoded.bytes[118..<142]))
    let lightingReport = M600PacketBuilder.lightingUpdate(data: encoded.lightingData)
    XCTAssertEqual(Array(lightingReport.bytes[0..<5]), [0x25, 0, 1, 1, 24])
    XCTAssertEqual(Array(lightingReport.bytes[5..<29]), encoded.lightingData)
    XCTAssertEqual(lightingReport.bytes[63], lightingReport.bytes[0..<63].reduce(0, &+))
  }

  func testProfileChunksAndChecksum() {
    let data = Array(0..<142).map(UInt8.init)
    let reports = M600PacketBuilder.chunks(command: 0x01, data: data)
    XCTAssertEqual(reports.count, 3)
    XCTAssertEqual(Array(reports[0].bytes[0..<5]), [1, 0, 1, 3, 58])
    XCTAssertEqual(Array(reports[1].bytes[0..<5]), [1, 0, 2, 3, 58])
    XCTAssertEqual(Array(reports[2].bytes[0..<5]), [1, 0, 3, 3, 26])
    for report in reports {
      XCTAssertEqual(report.bytes.count, 64)
      XCTAssertEqual(report.transferLength, 64)
      XCTAssertEqual(report.bytes[63], report.bytes[0..<63].reduce(0, &+))
    }
  }

  func testDirectReportTransferLengthsMatchNativeHIDWrites() {
    XCTAssertEqual(Array(M600PacketBuilder.commit.transferredBytes), [0x05, 0, 0])
    XCTAssertEqual(Array(M600PacketBuilder.batteryQuery.transferredBytes), [0x0B, 0])
    XCTAssertEqual(Array(M600PacketBuilder.flashCountQuery.transferredBytes), [0x0D, 0])
    XCTAssertEqual(Array(M600PacketBuilder.connectionQuery.transferredBytes), [0x0E, 0, 0])
    XCTAssertEqual(Array(M600PacketBuilder.stealthQuery.transferredBytes), [0x0A, 0, 0])
    XCTAssertEqual(M600PacketBuilder.factoryRestoreBegin.transferLength, 64)
    XCTAssertEqual(M600PacketBuilder.factoryRestoreConfirm.transferLength, 64)
  }

  @MainActor
  func testApplyVerifiesProfileBeforeActivatingAndVerifyingLighting() async throws {
    let transport = RecordingTransport(flashCount: 500)
    let controller = M600DeviceController(transport: transport, wait: { _ in })
    transport.connect()
    for _ in 0..<5 { await Task.yield() }
    transport.sentReports.removeAll()

    await controller.apply(M600Profile())

    XCTAssertNil(controller.lastError)
    XCTAssertEqual(controller.flashCount, 516)
    XCTAssertEqual(controller.lastSuccess, "Applied profile and lighting · flash #516")
    XCTAssertEqual(
      transport.sentReports.map { $0.bytes[0] },
      [1, 1, 1] + Array(repeating: 2, count: 11) + [13, 5, 13, 37, 13]
    )
  }

  @MainActor
  func testApplyRejectsAnUnconfirmedCommitBeforeSendingLighting() async throws {
    let transport = RecordingTransport(flashCount: 700, ignoredWriteCommands: [0x05])
    let controller = M600DeviceController(transport: transport, wait: { _ in })
    transport.connect()
    for _ in 0..<5 { await Task.yield() }
    transport.sentReports.removeAll()

    await controller.apply(M600Profile())

    XCTAssertNil(controller.lastSuccess)
    XCTAssertEqual(
      controller.lastError,
      "The mouse answered, but its onboard flash counter remained at 714 (previously 714). The profile was not committed."
    )
    XCTAssertEqual(
      transport.sentReports.map { $0.bytes[0] },
      [1, 1, 1] + Array(repeating: 2, count: 11) + [13, 5, 13]
    )
  }

  @MainActor
  func testApplyReportsAnUnconfirmedLightingUpdate() async throws {
    let transport = RecordingTransport(flashCount: 900, ignoredWriteCommands: [0x25])
    let controller = M600DeviceController(transport: transport, wait: { _ in })
    transport.connect()
    for _ in 0..<5 { await Task.yield() }
    transport.sentReports.removeAll()

    await controller.apply(M600Profile())

    XCTAssertNil(controller.lastSuccess)
    XCTAssertEqual(
      controller.lastError,
      "The profile was committed, but the mouse did not accept the lighting update (flash counter remained at 915, previously 915)."
    )
    XCTAssertEqual(
      transport.sentReports.map { $0.bytes[0] },
      [1, 1, 1] + Array(repeating: 2, count: 11) + [13, 5, 13, 37, 13]
    )
  }

  func testMacroEncodingAndProgrammingPackets() throws {
    var profile = M600Profile()
    let buttonIndex = profile.buttonBindings.firstIndex(where: { $0.button == .dpi })!
    profile.buttonBindings[buttonIndex].action = .macro
    profile.buttonBindings[buttonIndex].macro.steps = [
      .keyDown(usage: 0x04),
      .delay(milliseconds: 250),
      .keyUp(usage: 0x04),
    ]
    let encoded = try M600ProfileCodec.encode(profile)
    let body = try XCTUnwrap(encoded.macrosByDeviceOffset[M600Button.dpi.rawValue])
    XCTAssertEqual(Array(body.prefix(30)), Array(repeating: 0, count: 30))
    XCTAssertEqual(Array(body.dropFirst(30)), [2, 4, 1, 0, 250, 3, 4])

    let steps = M600PacketBuilder.macroProgrammingSteps(
      macroID: M600Button.dpi.macroID,
      body: body,
      deviceOffset: M600Button.dpi.rawValue
    )
    XCTAssertEqual(Array(steps[0].report.bytes.prefix(2)), [0xFB, 8])
    XCTAssertEqual(Array(steps[1].report.bytes.prefix(4)), [0xFE, 8, 0, 37])
    XCTAssertEqual(Array(steps[2].report.bytes.prefix(7)), [0xFD, 8, 0, 1, 0, 1, 37])
    XCTAssertEqual(
      Array(steps.last!.report.bytes.prefix(8)),
      [0x02, 0, 9, 0xF2, 8, 0, 0, 0]
    )
    XCTAssertTrue(steps.allSatisfy { $0.report.transferLength == 64 })
  }

  func testKeyPressActionCompilesToMinimalMacroAndPreservesEditableMacro() throws {
    var profile = M600Profile()
    let buttonIndex = profile.buttonBindings.firstIndex(where: { $0.button == .dpi })!
    let editableMacro = MacroDefinition(
      name: "Keep Me",
      steps: [.keyDown(usage: 0x05), .keyUp(usage: 0x05)]
    )
    profile.buttonBindings[buttonIndex].macro = editableMacro
    profile.buttonBindings[buttonIndex].assignKeyPress(usage: 0x04)

    let binding = profile.buttonBindings[buttonIndex]
    XCTAssertEqual(binding.action, .keyPress)
    XCTAssertEqual(binding.selectedActionDisplayName, "Press A")
    XCTAssertEqual(binding.macro, editableMacro)
    XCTAssertEqual(
      binding.programmedMacroSteps,
      [.keyDown(usage: 0x04), .keyUp(usage: 0x04)]
    )

    let encoded = try M600ProfileCodec.encode(profile)
    XCTAssertEqual(
      encoded.keyMatrices[M600Button.dpi.rawValue],
      [0xF2, M600Button.dpi.macroID, 0, 0, 0]
    )
    XCTAssertEqual(
      encoded.macrosByDeviceOffset[M600Button.dpi.rawValue],
      Array(repeating: 0, count: 30) + [0x02, 0x04, 0x03, 0x04]
    )

    var restoredBinding = binding
    restoredBinding.assignAction(.macro)
    XCTAssertNil(restoredBinding.keyPressUsage)
    XCTAssertEqual(restoredBinding.macro, editableMacro)
  }

  func testExplicitTwoStepMacroRemainsMacro() {
    let binding = ButtonBinding(
      button: .dpi,
      action: .macro,
      macro: MacroDefinition(
        name: "One key macro",
        steps: [.keyDown(usage: 0x04), .keyUp(usage: 0x04)]
      )
    )

    XCTAssertEqual(binding.action, .macro)
    XCTAssertEqual(binding.selectedActionDisplayName, "Macro")
    XCTAssertNil(binding.keyPressUsage)
  }

  func testKeyPressActionRequiresASelectedKey() {
    var profile = M600Profile()
    let buttonIndex = profile.buttonBindings.firstIndex(where: { $0.button == .dpi })!
    profile.buttonBindings[buttonIndex].action = .keyPress

    XCTAssertThrowsError(try M600ProfileCodec.encode(profile)) { error in
      XCTAssertEqual(error as? M600ProfileError, .keyPressHasNoKey(.dpi))
    }
  }

  func testRecordedClickQwertzMacroSpansTwoNativePacedChunks() {
    let recordedSteps: [MacroStep] = [
      .mouseDown(button: .left),
      .delay(milliseconds: 388),
      .mouseUp(button: .left),
      .delay(milliseconds: 1_263),
      .keyDown(usage: 0x14),
      .delay(milliseconds: 86),
      .keyUp(usage: 0x14),
      .delay(milliseconds: 463),
      .keyDown(usage: 0x1A),
      .delay(milliseconds: 79),
      .keyUp(usage: 0x1A),
      .delay(milliseconds: 442),
      .keyDown(usage: 0x08),
      .delay(milliseconds: 78),
      .keyUp(usage: 0x08),
      .delay(milliseconds: 344),
      .keyDown(usage: 0x15),
      .delay(milliseconds: 78),
      .keyUp(usage: 0x15),
      .delay(milliseconds: 296),
      .keyDown(usage: 0x17),
      .delay(milliseconds: 83),
      .keyUp(usage: 0x17),
      .delay(milliseconds: 260),
      .keyDown(usage: 0x1C),
      .delay(milliseconds: 72),
      .keyUp(usage: 0x1C),
    ]
    let body =
      Array(repeating: UInt8(0), count: 30)
      + M600ProfileCodec.encodeMacroBody(recordedSteps)
    XCTAssertEqual(body.count, 97)
    XCTAssertEqual(
      Array(body[30..<57]),
      [
        0x04, 0x01, 0x01, 0x01, 0x84, 0x05, 0x01, 0x01, 0x04, 0xEF,
        0x02, 0x14, 0x01, 0x00, 0x56, 0x03, 0x14, 0x01, 0x01, 0xCF,
        0x02, 0x1A, 0x01, 0x00, 0x4F, 0x03, 0x1A,
      ]
    )

    let programmingSteps = M600PacketBuilder.macroProgrammingSteps(
      macroID: M600Button.dpi.macroID,
      body: body,
      deviceOffset: M600Button.dpi.rawValue
    )
    XCTAssertEqual(programmingSteps.count, 5)
    XCTAssertEqual(
      programmingSteps.map(\.delayAfterMilliseconds),
      [200, 150, 200, 200, 100]
    )
    XCTAssertEqual(Array(programmingSteps[1].report.bytes.prefix(4)), [0xFE, 8, 0, 97])
    XCTAssertEqual(
      Array(programmingSteps[2].report.bytes.prefix(7)),
      [0xFD, 8, 0, 1, 0, 2, 57]
    )
    XCTAssertEqual(Array(programmingSteps[2].report.bytes[7..<64]), Array(body[0..<57]))
    XCTAssertEqual(
      Array(programmingSteps[3].report.bytes.prefix(7)),
      [0xFD, 8, 0, 2, 0, 2, 40]
    )
    XCTAssertEqual(Array(programmingSteps[3].report.bytes[7..<47]), Array(body[57..<97]))
    XCTAssertEqual(
      Array(programmingSteps[3].report.bytes[47..<64]),
      Array(repeating: 0, count: 17)
    )
  }

  func testInputReportParsing() {
    XCTAssertEqual(M600InputReportParser.parse([0x0A, 0, 1]), .stealth(enabled: true))
    XCTAssertEqual(M600InputReportParser.parse([0x0A, 1, 0]), .stealth(enabled: false))
    XCTAssertEqual(
      M600InputReportParser.parse([0x0B, 0, 0x34, 0x12, 87]),
      .battery(voltageMillivolts: 0x1234, rawPercentage: 87)
    )
    XCTAssertEqual(
      M600InputReportParser.parse([0x0D, 0, 0x11, 0x22, 0x33]),
      .flashCount(0x332211)
    )
    XCTAssertEqual(
      M600InputReportParser.parse([0x0E, 0, 1]),
      .wirelessConnection(true)
    )
  }

  func testProfileStoreRoundTrip() throws {
    let temporary = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
      .appendingPathComponent("profiles.json")
    let store = ProfileStore(fileURL: temporary)
    let profile = M600Profile(name: "Stored")
    try store.save(StoredProfiles(selectedProfileID: profile.id, profiles: [profile]))
    let loaded = try store.load()
    XCTAssertEqual(loaded.selectedProfileID, profile.id)
    XCTAssertEqual(loaded.profiles, [profile])
    XCTAssertEqual(loaded.schemaVersion, StoredProfiles.currentSchemaVersion)
    try? FileManager.default.removeItem(at: temporary.deletingLastPathComponent())
  }

  func testProfileStorePersistsDedicatedKeyPressIntent() throws {
    let temporary = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
      .appendingPathComponent("profiles.json")
    let store = ProfileStore(fileURL: temporary)
    var profile = M600Profile(name: "Key Press")
    let buttonIndex = profile.buttonBindings.firstIndex(where: { $0.button == .dpi })!
    profile.buttonBindings[buttonIndex].assignKeyPress(usage: 0x2C)
    try store.save(StoredProfiles(selectedProfileID: profile.id, profiles: [profile]))

    let loaded = try store.load()
    let binding = try XCTUnwrap(
      loaded.profiles[0].buttonBindings.first(where: { $0.button == .dpi })
    )
    XCTAssertEqual(binding.action, .keyPress)
    XCTAssertEqual(binding.keyPressUsage, 0x2C)
    XCTAssertEqual(binding.selectedActionDisplayName, "Press Space")
    XCTAssertEqual(loaded.schemaVersion, StoredProfiles.currentSchemaVersion)
    try? FileManager.default.removeItem(at: temporary.deletingLastPathComponent())
  }

  func testProfileStoreMigratesLegacyRightAndMiddleButtonOffsets() throws {
    let temporary = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
      .appendingPathComponent("profiles.json")
    let store = ProfileStore(fileURL: temporary)
    var profile = M600Profile(name: "Legacy")
    let rightIndex = profile.buttonBindings.firstIndex(where: { $0.button == .right })!
    profile.buttonBindings[rightIndex].action = .volumeDown
    try store.save(StoredProfiles(selectedProfileID: profile.id, profiles: [profile]))

    var root = try XCTUnwrap(
      JSONSerialization.jsonObject(with: Data(contentsOf: temporary)) as? [String: Any]
    )
    root.removeValue(forKey: "schemaVersion")
    var profiles = try XCTUnwrap(root["profiles"] as? [[String: Any]])
    var bindings = try XCTUnwrap(profiles[0]["buttonBindings"] as? [[String: Any]])
    for index in bindings.indices {
      if bindings[index]["button"] as? Int == 1 {
        bindings[index]["button"] = 2
      } else if bindings[index]["button"] as? Int == 2 {
        bindings[index]["button"] = 1
      }
    }
    profiles[0]["buttonBindings"] = bindings
    root["profiles"] = profiles
    try JSONSerialization.data(withJSONObject: root).write(to: temporary, options: .atomic)

    let migrated = try store.load()
    let migratedRight = try XCTUnwrap(
      migrated.profiles[0].buttonBindings.first(where: { $0.button == .right })
    )
    let migratedMiddle = try XCTUnwrap(
      migrated.profiles[0].buttonBindings.first(where: { $0.button == .middle })
    )
    XCTAssertEqual(migratedRight.action, .volumeDown)
    XCTAssertEqual(migratedMiddle.action, .middleClick)
    XCTAssertEqual(migrated.schemaVersion, StoredProfiles.currentSchemaVersion)
    try? FileManager.default.removeItem(at: temporary.deletingLastPathComponent())
  }

  func testProfileStoreMigratesSchemaTwoMacroMouseButtons() throws {
    let temporary = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
      .appendingPathComponent("profiles.json")
    let store = ProfileStore(fileURL: temporary)
    var profile = M600Profile(name: "Schema 2")
    let dpiIndex = profile.buttonBindings.firstIndex(where: { $0.button == .dpi })!
    profile.buttonBindings[dpiIndex].action = .macro
    profile.buttonBindings[dpiIndex].macro.steps = [
      .mouseDown(button: .right), .mouseUp(button: .right),
    ]
    try store.save(StoredProfiles(selectedProfileID: profile.id, profiles: [profile]))

    var root = try XCTUnwrap(
      JSONSerialization.jsonObject(with: Data(contentsOf: temporary)) as? [String: Any]
    )
    root["schemaVersion"] = 2
    var profiles = try XCTUnwrap(root["profiles"] as? [[String: Any]])
    var bindings = try XCTUnwrap(profiles[0]["buttonBindings"] as? [[String: Any]])
    let storedDPIIndex = try XCTUnwrap(
      bindings.firstIndex(where: { $0["button"] as? Int == M600Button.dpi.rawValue })
    )
    var macro = try XCTUnwrap(bindings[storedDPIIndex]["macro"] as? [String: Any])
    var steps = try XCTUnwrap(macro["steps"] as? [[String: Any]])
    for index in steps.indices {
      for eventName in ["mouseDown", "mouseUp"] {
        if var event = steps[index][eventName] as? [String: Any] {
          event["button"] = 3
          steps[index][eventName] = event
        }
      }
    }
    macro["steps"] = steps
    bindings[storedDPIIndex]["macro"] = macro
    profiles[0]["buttonBindings"] = bindings
    root["profiles"] = profiles
    try JSONSerialization.data(withJSONObject: root).write(to: temporary, options: .atomic)

    let migrated = try store.load()
    let migratedDPI = try XCTUnwrap(
      migrated.profiles[0].buttonBindings.first(where: { $0.button == .dpi })
    )
    XCTAssertEqual(
      migratedDPI.macro.steps,
      [.mouseDown(button: .right), .mouseUp(button: .right)]
    )
    XCTAssertEqual(migrated.schemaVersion, StoredProfiles.currentSchemaVersion)
    try? FileManager.default.removeItem(at: temporary.deletingLastPathComponent())
  }
}

@MainActor
private final class RecordingTransport: M600ReportTransport {
  var onConnectionChange: ((Bool, String?) -> Void)?
  var onInputReport: ((M600InputReport) -> Void)?
  var onError: ((Error) -> Void)?
  var sentReports: [M600OutputReport] = []

  private var flashCount: UInt32
  private let ignoredWriteCommands: Set<UInt8>

  init(flashCount: UInt32, ignoredWriteCommands: Set<UInt8> = []) {
    self.flashCount = flashCount
    self.ignoredWriteCommands = ignoredWriteCommands
  }

  func start() throws {}

  func connect() {
    onConnectionChange?(true, "Test M600")
  }

  func send(_ report: M600OutputReport) throws {
    sentReports.append(report)
    switch report.bytes[0] {
    case let command
    where [UInt8(0x01), 0x02, 0x05, 0x25].contains(command)
      && !ignoredWriteCommands.contains(command):
      flashCount += 1
    case 0x0A:
      onInputReport?(.stealth(enabled: false))
    case 0x0B:
      onInputReport?(.battery(voltageMillivolts: 4_200, rawPercentage: 100))
    case 0x0D:
      onInputReport?(.flashCount(flashCount))
    case 0x0E:
      onInputReport?(.wirelessConnection(false))
    default:
      break
    }
  }
}
