import M600Core
import XCTest

@testable import M600ManagerApp

@MainActor
final class AppModelProfileActionsTests: XCTestCase {
  func testDuplicateTargetsRequestedProfileAndSelectsTheCopy() throws {
    var workProfile = M600Profile(name: "Work")
    workProfile.iconName = "terminal"
    workProfile.profileColor = M600Core.RGBColor(red: 12, green: 34, blue: 56)
    let defaultProfile = M600Profile(name: "Default")
    let (model, directory) = try makeModel(
      profiles: [defaultProfile, workProfile],
      selectedProfileID: defaultProfile.id
    )
    defer { try? FileManager.default.removeItem(at: directory) }

    model.duplicateProfile(workProfile.id)

    XCTAssertEqual(model.profiles.count, 3)
    let duplicate = try XCTUnwrap(model.profiles.last)
    XCTAssertNotEqual(duplicate.id, workProfile.id)
    XCTAssertEqual(duplicate.name, "Work Copy")
    XCTAssertEqual(duplicate.iconName, workProfile.iconName)
    XCTAssertEqual(duplicate.profileColor, workProfile.profileColor)
    XCTAssertEqual(model.selectedProfileID, duplicate.id)
  }

  func testRowActionsRenameAndDeleteOnlyTheRequestedProfile() throws {
    let first = M600Profile(name: "First")
    let second = M600Profile(name: "Second")
    let third = M600Profile(name: "Third")
    let (model, directory) = try makeModel(
      profiles: [first, second, third],
      selectedProfileID: second.id
    )
    defer { try? FileManager.default.removeItem(at: directory) }

    model.selectProfile(first.id)
    XCTAssertEqual(model.selectedProfileID, first.id)
    model.selectProfile(second.id)

    model.renameProfile(first.id, to: "Renamed")

    XCTAssertEqual(model.profiles[0].name, "Renamed")
    XCTAssertEqual(model.profiles[1].name, "Second")

    model.deleteProfile(first.id)
    XCTAssertEqual(model.profiles.map(\.id), [second.id, third.id])
    XCTAssertEqual(model.selectedProfileID, second.id)

    model.deleteProfile(second.id)
    XCTAssertEqual(model.profiles.map(\.id), [third.id])
    XCTAssertEqual(model.selectedProfileID, third.id)

    model.deleteProfile(third.id)
    XCTAssertEqual(model.profiles.map(\.id), [third.id])

    let persisted = try ProfileStore(
      fileURL: directory.appendingPathComponent("profiles.json")
    ).load()
    XCTAssertEqual(persisted.profiles.map(\.id), [third.id])
    XCTAssertEqual(persisted.selectedProfileID, third.id)
  }

  private func makeModel(
    profiles: [M600Profile],
    selectedProfileID: UUID
  ) throws -> (AppModel, URL) {
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let store = ProfileStore(fileURL: directory.appendingPathComponent("profiles.json"))
    try store.save(StoredProfiles(selectedProfileID: selectedProfileID, profiles: profiles))
    let device = M600DeviceController(transport: InactiveReportTransport())
    return (AppModel(store: store, device: device), directory)
  }
}

private final class InactiveReportTransport: M600ReportTransport {
  var onConnectionChange: ((Bool, String?) -> Void)?
  var onInputReport: ((M600InputReport) -> Void)?
  var onError: ((Error) -> Void)?

  func start() throws {}

  func send(_: M600OutputReport) throws {
    XCTFail("Inactive test transport unexpectedly received a report")
  }
}
