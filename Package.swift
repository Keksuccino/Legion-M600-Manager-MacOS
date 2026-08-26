// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "LegionM600Manager",
  platforms: [.macOS(.v26)],
  products: [
    .library(name: "M600Core", targets: ["M600Core"]),
    .executable(name: "M600 Manager", targets: ["M600ManagerApp"]),
    .executable(name: "m600ctl", targets: ["M600CLI"]),
  ],
  targets: [
    .target(
      name: "M600Core",
      linkerSettings: [.linkedFramework("IOKit")]
    ),
    .executableTarget(
      name: "M600ManagerApp",
      dependencies: ["M600Core"],
      linkerSettings: [
        .linkedFramework("AppKit"),
        .linkedFramework("ApplicationServices"),
      ]
    ),
    .executableTarget(name: "M600CLI", dependencies: ["M600Core"]),
    .testTarget(name: "M600CoreTests", dependencies: ["M600Core"]),
  ],
  swiftLanguageModes: [.v5]
)
