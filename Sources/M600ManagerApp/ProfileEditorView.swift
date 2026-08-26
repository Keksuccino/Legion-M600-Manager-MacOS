import M600Core
import SwiftUI

struct ProfileEditorView: View {
  @Binding var profile: M600Profile
  @ObservedObject var device: M600DeviceController
  let save: () -> Void

  @State private var selectedTab = EditorTab.performance
  @State private var showFactoryRestoreConfirmation = false

  enum EditorTab: Hashable {
    case performance
    case buttons
    case lighting
    case device
  }

  var body: some View {
    VStack(spacing: 0) {
      DeviceHeaderView(device: device) {
        save()
        Task { await device.apply(profile) }
      }
      Divider()
      TabView(selection: $selectedTab) {
        PerformanceView(profile: $profile)
          .tabItem { Label("Performance", systemImage: "speedometer") }
          .tag(EditorTab.performance)
        ButtonAssignmentsView(bindings: $profile.buttonBindings)
          .tabItem { Label("Buttons", systemImage: "button.programmable") }
          .tag(EditorTab.buttons)
        LightingView(zones: $profile.lightingZones, stealthModeActive: device.stealthModeActive)
          .tabItem { Label("Lighting", systemImage: "lightbulb.led") }
          .tag(EditorTab.lighting)
        DeviceSettingsView(
          device: device,
          showFactoryRestoreConfirmation: $showFactoryRestoreConfirmation
        )
        .tabItem { Label("Device", systemImage: "gearshape") }
        .tag(EditorTab.device)
      }
      .padding(.horizontal, 18)
    }
    .toolbar {
      ToolbarItem(placement: .principal) {
        TextField("Profile name", text: $profile.name)
          .textFieldStyle(.plain)
          .font(.headline)
          .multilineTextAlignment(.center)
          .frame(width: 260)
      }
    }
    .onChange(of: profile) {
      device.clearApplyConfirmation()
      save()
    }
    .alert(
      "Mouse communication error",
      isPresented: Binding(
        get: { device.lastError != nil },
        set: { if !$0 { device.clearError() } }
      )
    ) {
      Button("OK") { device.clearError() }
    } message: {
      Text(device.lastError ?? "Unknown error")
    }
    .confirmationDialog(
      "Restore factory settings?",
      isPresented: $showFactoryRestoreConfirmation,
      titleVisibility: .visible
    ) {
      Button("Restore Mouse", role: .destructive) {
        Task { await device.restoreFactorySettings() }
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("This replaces the configuration stored in the mouse. Your local profiles are kept.")
    }
  }
}

private struct DeviceHeaderView: View {
  @ObservedObject var device: M600DeviceController
  let apply: () -> Void

  var body: some View {
    HStack(spacing: 14) {
      Image(systemName: device.isConnected ? "computermouse.fill" : "computermouse")
        .font(.system(size: 30))
        .foregroundStyle(device.isConnected ? Color.accentColor : .secondary)
      VStack(alignment: .leading, spacing: 2) {
        Text(device.productName).font(.headline)
        Text(
          device.isConnected ? "Connected · Configuration interface ready" : "Mouse not connected"
        )
        .font(.caption)
        .foregroundStyle(.secondary)
        if let success = device.lastSuccess {
          Label(success, systemImage: "checkmark.circle.fill")
            .font(.caption)
            .foregroundStyle(.green)
        }
      }
      Spacer()
      if let battery = device.batteryPercentage {
        Label("\(battery)%", systemImage: batteryIcon(battery))
          .help(device.batteryVoltageMillivolts.map { "Reported voltage: \($0) mV" } ?? "Battery")
      }
      Button {
        Task { await device.refreshReadOnlyStatus() }
      } label: {
        Image(systemName: "arrow.clockwise")
      }
      .help("Refresh battery and device status")
      .disabled(!device.isConnected || device.isBusy)
      Button(action: apply) {
        if device.isBusy {
          ProgressView().controlSize(.small)
          Text(device.operationDescription ?? "Applying")
        } else {
          Text("Apply to Mouse")
        }
      }
      .buttonStyle(.borderedProminent)
      .disabled(!device.isConnected || device.isBusy)
    }
    .padding(18)
  }

  private func batteryIcon(_ value: Int) -> String {
    switch value {
    case 76...: return "battery.100percent"
    case 51...: return "battery.75percent"
    case 26...: return "battery.50percent"
    case 6...: return "battery.25percent"
    default: return "battery.0percent"
    }
  }
}
