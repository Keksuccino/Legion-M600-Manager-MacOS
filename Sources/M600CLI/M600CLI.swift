import Foundation
import M600Core

@main
struct M600CLI {
  @MainActor
  static func main() async {
    let command = CommandLine.arguments.dropFirst().first ?? "info"
    guard ["info", "battery", "flash-count", "stealth", "help"].contains(command) else {
      print("Unknown command: \(command)\n")
      usage()
      exit(2)
    }
    if command == "help" {
      usage()
      return
    }

    let controller = M600DeviceController()
    for _ in 0..<30 where !controller.isConnected {
      try? await Task.sleep(nanoseconds: 100_000_000)
    }
    guard controller.isConnected else {
      fputs("M600 configuration interface not found (VID 17EF, PID 60E5).\n", stderr)
      exit(1)
    }

    await controller.refreshReadOnlyStatus()
    try? await Task.sleep(nanoseconds: 350_000_000)
    if let error = controller.lastError {
      fputs("HID query failed: \(error)\n", stderr)
      exit(1)
    }

    switch command {
    case "battery":
      if let battery = controller.batteryPercentage {
        print("\(battery)%")
      } else {
        fputs("No battery response received.\n", stderr)
        exit(1)
      }
    case "flash-count":
      if let count = controller.flashCount {
        print(count)
      } else {
        fputs("No flash-counter response received.\n", stderr)
        exit(1)
      }
    case "stealth":
      if let enabled = controller.stealthModeActive {
        print(enabled ? "on" : "off")
      } else {
        fputs("No stealth-mode response received.\n", stderr)
        exit(1)
      }
    default:
      print("Device: \(controller.productName)")
      print("VID:PID: 17EF:60E5")
      print("Configuration interface: connected")
      print("Battery: \(controller.batteryPercentage.map { "\($0)%" } ?? "no response")")
      print("Voltage: \(controller.batteryVoltageMillivolts.map { "\($0) mV" } ?? "no response")")
      print("Flash count: \(controller.flashCount.map(String.init) ?? "no response")")
      print(
        "2.4 GHz link: \(controller.wirelessConnectionActive.map { $0 ? "active" : "inactive" } ?? "no response")"
      )
      print(
        "Stealth mode: \(controller.stealthModeActive.map { $0 ? "on (lighting suppressed)" : "off" } ?? "no response")"
      )
    }
  }

  private static func usage() {
    print(
      """
      Usage: m600ctl [info|battery|flash-count|stealth|help]

      Read-only diagnostics for a connected Lenovo Legion M600.
      Profile writes are intentionally available only through the macOS app.
      """)
  }
}
