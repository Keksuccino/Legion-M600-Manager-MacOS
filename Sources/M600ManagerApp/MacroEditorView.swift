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
      header
      Divider()
      HStack(spacing: 0) {
        sequencePane
        Divider()
        controlsPane
      }
    }
    .frame(minWidth: 920, minHeight: 620)
    .onReceive(recorder.$steps) { steps in
      guard recorder.isRecording else { return }
      macro.steps = steps
    }
    .onDisappear { recorder.stop() }
  }

  private var header: some View {
    HStack(spacing: 20) {
      VStack(alignment: .leading, spacing: 4) {
        Text("Macro for \(buttonName)")
          .font(.title2.bold())
        Text("Record or assemble the exact input sequence this button should play.")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
      Spacer()
      Button("Done") {
        if recorder.isRecording { stopRecording() }
        dismiss()
      }
      .buttonStyle(.borderedProminent)
      .controlSize(.large)
      .keyboardShortcut(.defaultAction)
    }
    .padding(.horizontal, 24)
    .padding(.vertical, 18)
  }

  private var sequencePane: some View {
    VStack(spacing: 0) {
      HStack(spacing: 10) {
        Text("Event sequence")
          .font(.headline)
        Text(stepCountLabel)
          .font(.caption)
          .foregroundStyle(.secondary)
        Spacer()
        Button("Clear", role: .destructive, action: clearSteps)
          .disabled(macro.steps.isEmpty)
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 14)

      Divider()

      ScrollViewReader { scrollProxy in
        List {
          ForEach(Array(macro.steps.enumerated()), id: \.offset) { index, step in
            MacroStepRow(
              index: index,
              step: step,
              deletionDisabled: recorder.isRecording
            ) {
              guard macro.steps.indices.contains(index) else { return }
              macro.steps.remove(at: index)
            }
            .id(index)
          }
          .onMove { source, destination in
            guard !recorder.isRecording else { return }
            macro.steps.move(fromOffsets: source, toOffset: destination)
          }
          .onDelete { offsets in
            guard !recorder.isRecording else { return }
            macro.steps.remove(atOffsets: offsets)
          }
        }
        .listStyle(.inset)
        .overlay {
          if macro.steps.isEmpty {
            ContentUnavailableView(
              "No events yet",
              systemImage: "waveform",
              description: Text("Start recording or add an input with the controls on the right.")
            )
          }
        }
        .onChange(of: macro.steps.count) { _, count in
          guard recorder.isRecording, count > 0 else { return }
          withAnimation(.easeOut(duration: 0.16)) {
            scrollProxy.scrollTo(count - 1, anchor: .bottom)
          }
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var controlsPane: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        recordingControls

        Text("Add events manually")
          .font(.headline)
          .padding(.top, 2)

        delayControls
        keyControls
        mouseControls
      }
      .padding(20)
    }
    .frame(width: 320)
    .background(Color(nsColor: .controlBackgroundColor).opacity(0.38))
  }

  private var recordingControls: some View {
    MacroControlCard(title: "Recording", systemImage: "waveform.circle") {
      HStack(spacing: 8) {
        Circle()
          .fill(recorder.isRecording ? Color.red : Color.secondary.opacity(0.5))
          .frame(width: 8, height: 8)
        Text(recorder.isRecording ? "Recording" : "Ready")
          .font(.subheadline.weight(.semibold))
        Spacer()
        Text(stepCountLabel)
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      if let warning = recorder.permissionWarning {
        Label(warning, systemImage: "exclamationmark.triangle.fill")
          .font(.caption)
          .foregroundStyle(.orange)
          .fixedSize(horizontal: false, vertical: true)
      }

      if recorder.isRecording {
        MacroInputCaptureView(capture: recorder.captureLocalEvent)
        Text(
          "Events appear in the sequence immediately. New input is appended to existing events."
        )
        .font(.caption)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
        Button("Stop Recording", systemImage: "stop.fill", action: stopRecording)
          .buttonStyle(.borderedProminent)
          .tint(.red)
          .controlSize(.large)
          .frame(maxWidth: .infinity)
      } else {
        Text(
          "Record without leaving the manager. Keyboard input works anywhere in this window; use the capture area for mouse input."
        )
        .font(.caption)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
        Button("Start Recording", systemImage: "record.circle") {
          recorder.start(existingSteps: macro.steps)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .frame(maxWidth: .infinity)
      }
    }
  }

  private var delayControls: some View {
    MacroControlCard(title: "Wait", systemImage: "clock") {
      Stepper(value: $delayMilliseconds, in: 1...Int(UInt16.max)) {
        HStack {
          Text("Duration")
          Spacer()
          Text("\(delayMilliseconds) ms")
            .monospacedDigit()
            .foregroundStyle(.secondary)
        }
      }
      Button("Add Wait", systemImage: "plus") {
        macro.steps.append(.delay(milliseconds: UInt16(delayMilliseconds)))
      }
      .frame(maxWidth: .infinity)
    }
    .disabled(recorder.isRecording)
  }

  private var keyControls: some View {
    MacroControlCard(title: "Keyboard", systemImage: "keyboard") {
      Picker("Key", selection: $selectedKeyUsage) {
        ForEach(HIDKeyNames.common, id: \.usage) { key in
          Text(key.name).tag(key.usage)
        }
      }
      Button("Add Key Press", systemImage: "plus") {
        macro.steps.append(.keyDown(usage: selectedKeyUsage))
        macro.steps.append(.keyUp(usage: selectedKeyUsage))
      }
      .frame(maxWidth: .infinity)
    }
    .disabled(recorder.isRecording)
  }

  private var mouseControls: some View {
    MacroControlCard(title: "Mouse", systemImage: "computermouse") {
      Picker("Button", selection: $selectedMouseButton) {
        ForEach(MacroMouseButton.allCases) { button in
          Text(button.displayName).tag(button)
        }
      }
      Button("Add Click", systemImage: "plus") {
        macro.steps.append(.mouseDown(button: selectedMouseButton))
        macro.steps.append(.mouseUp(button: selectedMouseButton))
      }
      .frame(maxWidth: .infinity)
      HStack {
        Button("Wheel Up", systemImage: "arrow.up") {
          macro.steps.append(.wheelUp)
        }
        Button("Wheel Down", systemImage: "arrow.down") {
          macro.steps.append(.wheelDown)
        }
      }
    }
    .disabled(recorder.isRecording)
  }

  private var stepCountLabel: String {
    "\(macro.steps.count) \(macro.steps.count == 1 ? "event" : "events")"
  }

  private func clearSteps() {
    if recorder.isRecording {
      recorder.clear()
    } else {
      macro.steps.removeAll()
    }
  }

  private func stopRecording() {
    recorder.stop()
    macro.steps = recorder.steps
  }
}

private struct MacroControlCard<Content: View>: View {
  let title: String
  let systemImage: String
  let content: Content

  init(
    title: String,
    systemImage: String,
    @ViewBuilder content: () -> Content
  ) {
    self.title = title
    self.systemImage = systemImage
    self.content = content()
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Label(title, systemImage: systemImage)
        .font(.headline)
      content
    }
    .padding(14)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.quaternary.opacity(0.7), in: RoundedRectangle(cornerRadius: 10))
  }
}

private struct MacroStepRow: View {
  let index: Int
  let step: MacroStep
  let deletionDisabled: Bool
  let delete: () -> Void

  var body: some View {
    HStack(spacing: 12) {
      Text("\(index + 1)")
        .font(.caption.monospacedDigit())
        .foregroundStyle(.tertiary)
        .frame(width: 28, alignment: .trailing)

      Image(systemName: step.iconName)
        .foregroundStyle(step.iconColor)
        .frame(width: 22)

      Text(step.displayName)
        .lineLimit(1)

      Spacer(minLength: 16)

      MacroDeleteButton(disabled: deletionDisabled, action: delete)
    }
    .padding(.vertical, 5)
  }
}

private struct MacroDeleteButton: View {
  let disabled: Bool
  let action: () -> Void

  @State private var isHovering = false

  var body: some View {
    Button(action: action) {
      Image(systemName: "trash")
        .foregroundStyle(isHovering && !disabled ? Color.red : Color.secondary)
        .frame(width: 28, height: 28)
        .background(
          isHovering && !disabled ? Color.red.opacity(0.12) : Color.clear,
          in: RoundedRectangle(cornerRadius: 6, style: .continuous)
        )
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .disabled(disabled)
    .help(disabled ? "Stop recording before removing events" : "Remove event")
    .pointerStyle(disabled ? nil : .link)
    .onHover { hovering in
      isHovering = hovering
    }
    .onChange(of: disabled) {
      guard disabled, isHovering else { return }
      isHovering = false
    }
    .accessibilityLabel("Remove event from macro")
  }
}

extension MacroStep {
  fileprivate var iconName: String {
    switch self {
    case .delay: return "clock"
    case .keyDown: return "arrow.down.to.line.compact"
    case .keyUp: return "arrow.up.to.line.compact"
    case .mouseDown: return "computermouse.fill"
    case .mouseUp: return "computermouse"
    case .wheelUp: return "arrow.up.circle"
    case .wheelDown: return "arrow.down.circle"
    }
  }

  fileprivate var iconColor: Color {
    switch self {
    case .delay: return .secondary
    case .keyDown, .mouseDown: return .accentColor
    case .keyUp, .mouseUp: return .secondary
    case .wheelUp, .wheelDown: return .purple
    }
  }
}
