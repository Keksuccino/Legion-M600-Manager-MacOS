import AppKit
import M600Core
import XCTest

@testable import M600ManagerApp

@MainActor
final class ProfileAppearanceTests: XCTestCase {
  func testCatalogContainsFiftyUniqueAvailableSymbols() {
    XCTAssertEqual(ProfileIconCatalog.options.count, 50)
    XCTAssertEqual(Set(ProfileIconCatalog.options.map(\.systemName)).count, 50)
    XCTAssertEqual(
      ProfileIconCatalog.resolvedIconName(M600Profile.defaultIconName),
      M600Profile.defaultIconName
    )

    for category in ProfileIconCategory.allCases {
      XCTAssertEqual(ProfileIconCatalog.options(in: category).count, 5)
    }
    for option in ProfileIconCatalog.options {
      XCTAssertNotNil(
        NSImage(systemSymbolName: option.systemName, accessibilityDescription: option.name),
        "Missing SF Symbol: \(option.systemName)"
      )
    }
  }

  func testRGBColorSwiftUIRoundTrip() throws {
    let original = M600Core.RGBColor(red: 12, green: 128, blue: 244)
    let converted = try XCTUnwrap(M600Core.RGBColor(swiftUIColor: original.swiftUIColor))
    XCTAssertEqual(converted, original)
  }
}
