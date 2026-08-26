import M600Core
import SwiftUI

struct ProfileSidebarRow: View {
  let profile: M600Profile
  let canDelete: Bool
  let edit: () -> Void
  let rename: (String) -> Void
  let duplicate: () -> Void
  let delete: () -> Void
  let setIcon: (String) -> Void
  let setColor: (M600Core.RGBColor) -> Void

  @State private var isRenaming = false
  @State private var renameDraft = ""
  @State private var isCustomColorPickerPresented = false
  @FocusState private var isRenameFieldFocused: Bool

  var body: some View {
    HStack(spacing: 7) {
      Image(systemName: ProfileIconCatalog.resolvedIconName(profile.resolvedIconName))
        .foregroundStyle(profile.resolvedProfileColor.swiftUIColor)
        .frame(width: 17)

      if isRenaming {
        TextField("Profile name", text: $renameDraft)
          .textFieldStyle(.plain)
          .focused($isRenameFieldFocused)
          .onSubmit(commitRename)
          .onChange(of: isRenameFieldFocused) { wasFocused, isFocused in
            if wasFocused, !isFocused, isRenaming {
              commitRename()
            }
          }
      } else {
        Text(profile.name)
          .lineLimit(1)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .contentShape(Rectangle())
    .accessibilityLabel(profile.name)
    .contextMenu {
      Button("Edit", systemImage: "pencil", action: edit)
      Button("Rename", systemImage: "text.cursor", action: beginRename)
      Button("Duplicate", systemImage: "plus.square.on.square", action: duplicate)

      Divider()

      Menu("Change Icon", systemImage: "square.grid.3x3") {
        ForEach(ProfileIconCatalog.options) { option in
          Button {
            setIcon(option.systemName)
          } label: {
            Label(option.name, systemImage: option.systemName)
          }
        }
      }

      Menu("Change Color", systemImage: "paintpalette") {
        ForEach(ProfileColorCatalog.options) { option in
          Button {
            setColor(option.color)
          } label: {
            Label(option.name, systemImage: "circle.fill")
          }
          .tint(option.color.swiftUIColor)
        }

        Divider()

        Button("Custom Color…", systemImage: "eyedropper") {
          isCustomColorPickerPresented = true
        }
      }

      Divider()

      Button("Delete", systemImage: "trash", role: .destructive, action: delete)
        .disabled(!canDelete)
    }
    .popover(isPresented: $isCustomColorPickerPresented, arrowEdge: .leading) {
      VStack(alignment: .leading, spacing: 14) {
        Text("Custom Profile Color")
          .font(.headline)

        ColorPicker(
          "Color",
          selection: customColorBinding,
          supportsOpacity: false
        )

        HStack {
          Spacer()
          Button("Done") {
            isCustomColorPickerPresented = false
          }
          .keyboardShortcut(.defaultAction)
        }
      }
      .padding(16)
      .frame(width: 250)
    }
  }

  private var customColorBinding: Binding<Color> {
    Binding(
      get: { profile.resolvedProfileColor.swiftUIColor },
      set: { color in
        guard let converted = M600Core.RGBColor(swiftUIColor: color) else { return }
        setColor(converted)
      }
    )
  }

  private func beginRename() {
    renameDraft = profile.name
    isRenaming = true
    Task { @MainActor in
      isRenameFieldFocused = true
    }
  }

  private func commitRename() {
    guard isRenaming else { return }
    isRenaming = false
    isRenameFieldFocused = false
    if renameDraft != profile.name {
      rename(renameDraft)
    }
  }
}
