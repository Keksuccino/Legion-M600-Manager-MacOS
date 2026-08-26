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
    XCTAssertEqual(Array(encoded.bytes[42..<47]), [0x91, 0, 0, 0, 0])
    XCTAssertEqual(
      Array(encoded.bytes[118..<130]),
      [3, 100, 0, 10, 20, 30, 0, 0, 0, 0, 0, 0]
    )
    XCTAssertEqual(
      Array(encoded.bytes[130..<142]),
      [2, 100, 0, 2, 3, 0, 40, 50, 60, 70, 80, 90]
    )
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

  func testInputReportParsing() {
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
    try? FileManager.default.removeItem(at: temporary.deletingLastPathComponent())
  }
}
