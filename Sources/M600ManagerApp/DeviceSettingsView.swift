import M600Core
import SwiftUI

struct DeviceSettingsView: View {
  @ObservedObject var device: M600DeviceController
  @Binding var showFactoryRestoreConfirmation: Bool

  var body: some View {
    Form {
      Section("Hardware status") {
        LabeledContent("Configuration interface") {
          Text(device.isConnected ? "Connected" : "Disconnected")
            .foregroundStyle(device.isConnected ? .green : .secondary)
        }
        LabeledContent("Battery") {
          if let battery = device.batteryPercentage { Text("\(battery)%") } else { Text("—") }
        }
        LabeledContent("Battery voltage") {
          if let voltage = device.batteryVoltageMillivolts {
            Text("\(voltage) mV")
          } else {
            Text("—")
          }
        }
        LabeledContent("Onboard flash counter") {
          if let count = device.flashCount { Text("\(count)") } else { Text("—") }
        }
        LabeledContent("2.4 GHz link") {
          if let active = device.wirelessConnectionActive {
            Text(active ? "Active" : "Inactive")
          } else {
            Text("—")
          }
        }
        Button("Refresh Status") { Task { await device.refreshReadOnlyStatus() } }
          .disabled(!device.isConnected || device.isBusy)
      }

      Section("Onboard configuration") {
        Text(
          "Apply writes the selected local profile to the mouse. The setting remains available when the app is closed and applies to wired and 2.4 GHz operation."
        )
        .font(.caption)
        .foregroundStyle(.secondary)
        Button("Restore Mouse Factory Settings…", role: .destructive) {
          showFactoryRestoreConfirmation = true
        }
        .disabled(!device.isConnected || device.isBusy)
      }

      Section("Safety") {
        Label(
          "Firmware update and receiver pairing commands are intentionally excluded. They use separate signed firmware paths and are not needed for configuration.",
          systemImage: "checkmark.shield"
        )
        .font(.caption)
        .foregroundStyle(.secondary)
      }
    }
    .formStyle(.grouped)
  }
}
