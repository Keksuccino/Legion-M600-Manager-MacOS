import M600Core
import SwiftUI

struct ButtonAssignmentsView: View {
  @Binding var bindings: [ButtonBinding]
  @State private var editingButton: M600Button?

  var body: some View {
    Form {
      Section("Programmable buttons") {
        ForEach($bindings) { $binding in
          HStack {
            Text(binding.button.displayName)
            Spacer()
            Picker("Action", selection: $binding.action) {
              ForEach(ButtonActionKind.allCases) { action in
                Text(action.displayName).tag(action)
              }
            }
            .labelsHidden()
            .frame(width: 210)
            if binding.action == .macro {
              Button("Edit…") { editingButton = binding.button }
            }
          }
          .padding(.vertical, 2)
        }
      }
      Section {
        Label(
          "At least one button must remain assigned to Left click. The app validates this before writing.",
          systemImage: "hand.point.up.left"
        )
        .font(.caption)
        .foregroundStyle(.secondary)
      }
    }
    .formStyle(.grouped)
    .sheet(item: $editingButton) { button in
      if let index = bindings.firstIndex(where: { $0.button == button }) {
        MacroEditorView(macro: $bindings[index].macro, buttonName: button.displayName)
      }
    }
  }
}
