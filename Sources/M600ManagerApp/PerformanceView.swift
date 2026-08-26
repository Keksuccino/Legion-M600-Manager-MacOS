import M600Core
import SwiftUI

struct PerformanceView: View {
  @Binding var profile: M600Profile

  var body: some View {
    Form {
      Section("DPI stages") {
        Picker("Enabled stages", selection: $profile.enabledDPIStageCount) {
          ForEach(1...4, id: \.self) { Text("\($0)").tag($0) }
        }
        .pickerStyle(.segmented)

        Picker("Active stage", selection: $profile.activeDPIStage) {
          ForEach(0..<profile.enabledDPIStageCount, id: \.self) { index in
            Text("Stage \(index + 1)").tag(index)
          }
        }

        ForEach(0..<4, id: \.self) { index in
          DPIStageRow(stageNumber: index + 1, stage: $profile.dpiStages[index])
            .disabled(index >= profile.enabledDPIStageCount)
        }
      }

      Section("Report rate") {
        Picker("Polling rate", selection: $profile.pollingRate) {
          ForEach(PollingRate.allCases) { rate in
            Text(rate.displayName).tag(rate)
          }
        }
        .pickerStyle(.segmented)
        Text(
          "In the mouse's low-power wireless mode, its hardware switch limits polling to 125 Hz."
        )
        .font(.caption)
        .foregroundStyle(.secondary)
      }
    }
    .formStyle(.grouped)
    .onChange(of: profile.enabledDPIStageCount) {
      profile.activeDPIStage = min(profile.activeDPIStage, profile.enabledDPIStageCount - 1)
      profile.defaultDPIStage = min(profile.defaultDPIStage, profile.enabledDPIStageCount - 1)
    }
  }
}

private struct DPIStageRow: View {
  let stageNumber: Int
  @Binding var stage: DPIStage

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text("Stage \(stageNumber)").font(.headline)
        Spacer()
        Toggle("Lock X/Y", isOn: $stage.lockXY)
          .toggleStyle(.checkbox)
          .onChange(of: stage.lockXY) {
            if stage.lockXY { stage.y = stage.x }
          }
      }
      DPIControl(label: "X", value: $stage.x)
        .onChange(of: stage.x) {
          if stage.lockXY { stage.y = stage.x }
        }
      if !stage.lockXY {
        DPIControl(label: "Y", value: $stage.y)
      }
    }
    .padding(.vertical, 4)
  }
}

private struct DPIControl: View {
  let label: String
  @Binding var value: Int

  var body: some View {
    HStack {
      Text(label).frame(width: 16)
      Slider(
        value: Binding(
          get: { Double(value) },
          set: { value = Int($0 / 100) * 100 }
        ),
        in: 100...16_000
      )
      TextField("DPI", value: $value, format: .number)
        .frame(width: 74)
        .multilineTextAlignment(.trailing)
        .onSubmit { value = min(16_000, max(100, (value / 100) * 100)) }
      Text("DPI").foregroundStyle(.secondary)
    }
  }
}
