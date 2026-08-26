import M600Core
import SwiftUI

struct MacroEditorView: View {
  @Binding var macro: MacroDefinition
  let buttonName: String

  @Environment(\.dismiss) private var dismiss
  @StateObject private var recorder = MacroRecorder()
  @State private var selectedKeyUsage: UInt8 = 0x04
  @State private var selectedMouseButton = MacroMouseButton.left
  @State private var delayMilliseconds = 100

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        VStack(alignment: .leading) {
          Text("Macro for \(buttonName)").font(.title2.bold())
          TextField("Macro name", text: $macro.name).textFieldStyle(.roundedBorder)
        }
        Spacer()
        Button("Done") {
          if recorder.isRecording { stopRecording() }
          dismiss()
        }
        .keyboardShortcut(.defaultAction)
      }
      .padding()

      if let warning = recorder.permissionWarning {
        Label(warning, systemImage: "exclamationmark.triangle")
          .font(.caption)
          .foregroundStyle(.orange)
          .padding(.horizontal)
          .padding(.bottom, 8)
      }

      List {
        ForEach(Array(macro.steps.enumerated()), id: \.offset) { index, step in
          HStack {
            Text("\(index + 1)").foregroundStyle(.secondary).frame(width: 28, alignment: .trailing)
            Text(step.displayName)
            Spacer()
            Button(role: .destructive) {
              macro.steps.remove(at: index)
            } label: {
              Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
          }
        }
        .onMove { source, destination in
          macro.steps.move(fromOffsets: source, toOffset: destination)
        }
        .onDelete { offsets in macro.steps.remove(atOffsets: offsets) }
      }
      .overlay {
        if macro.steps.isEmpty {
          ContentUnavailableView(
            "No macro steps",
            systemImage: "record.circle",
            description: Text("Record input outside this app or add steps below.")
          )
        }
      }

      Divider()
      VStack(spacing: 10) {
        HStack {
          if recorder.isRecording {
            Button("Stop Recording", systemImage: "stop.fill", action: stopRecording)
              .buttonStyle(.borderedProminent)
              .tint(.red)
            Text("Use the keyboard or mouse in another app, then return here to stop.")
              .font(.caption)
              .foregroundStyle(.secondary)
          } else {
            Button("Record", systemImage: "record.circle") {
              recorder.start(existingSteps: macro.steps)
            }
          }
          Spacer()
          Button("Clear", role: .destructive) { macro.steps.removeAll() }
            .disabled(macro.steps.isEmpty)
        }
        HStack {
          Stepper("\(delayMilliseconds) ms", value: $delayMilliseconds, in: 1...65_535)
            .frame(width: 160)
          Button("Add Delay") {
            macro.steps.append(.delay(milliseconds: UInt16(delayMilliseconds)))
          }
          Divider().frame(height: 22)
          Picker("Key", selection: $selectedKeyUsage) {
            ForEach(HIDKeyNames.common, id: \.usage) { key in
              Text(key.name).tag(key.usage)
            }
          }
          .frame(width: 150)
          Button("Add Key Press") {
            macro.steps.append(.keyDown(usage: selectedKeyUsage))
            macro.steps.append(.keyUp(usage: selectedKeyUsage))
          }
        }
        HStack {
          Picker("Mouse button", selection: $selectedMouseButton) {
            ForEach(MacroMouseButton.allCases) { button in
              Text(button.displayName).tag(button)
            }
          }
          .frame(width: 180)
          Button("Add Click") {
            macro.steps.append(.mouseDown(button: selectedMouseButton))
            macro.steps.append(.mouseUp(button: selectedMouseButton))
          }
          Button("Wheel Up") { macro.steps.append(.wheelUp) }
          Button("Wheel Down") { macro.steps.append(.wheelDown) }
          Spacer()
        }
      }
      .padding()
    }
    .frame(minWidth: 720, minHeight: 560)
    .onDisappear { recorder.stop() }
  }

  private func stopRecording() {
    recorder.stop()
    macro.steps = recorder.steps
  }
}
