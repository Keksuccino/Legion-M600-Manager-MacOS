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
            ButtonActionMenu(binding: $binding)
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

private struct ButtonActionMenu: View {
  @Binding var binding: ButtonBinding

  var body: some View {
    Menu {
      ForEach(ButtonActionKind.allCases) { action in
        if action == .keyPress {
          keyPressMenu
        } else {
          Button {
            binding.assignAction(action)
          } label: {
            actionLabel(action)
          }
        }
      }
    } label: {
      Text(binding.selectedActionDisplayName)
        .lineLimit(1)
        .frame(width: 210, alignment: .leading)
    }
  }

  private var keyPressMenu: some View {
    Menu {
      ForEach(HIDKeyNames.common, id: \.usage) { key in
        Button {
          binding.assignKeyPress(usage: key.usage)
        } label: {
          if binding.action == .keyPress, binding.keyPressUsage == key.usage {
            Label(key.name, systemImage: "checkmark")
          } else {
            Text(key.name)
          }
        }
      }
    } label: {
      if binding.action == .keyPress {
        Label(ButtonActionKind.keyPress.displayName, systemImage: "checkmark")
      } else {
        Text(ButtonActionKind.keyPress.displayName)
      }
    }
  }

  @ViewBuilder
  private func actionLabel(_ action: ButtonActionKind) -> some View {
    if binding.action == action {
      Label(action.displayName, systemImage: "checkmark")
    } else {
      Text(action.displayName)
    }
  }
}
