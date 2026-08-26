import M600Core
import SwiftUI

struct ProfileSidebarRow: View {
  let profile: M600Profile
  let canDelete: Bool
  let rename: (String) -> Void
  let duplicate: () -> Void
  let delete: () -> Void
  let showIconPicker: () -> Void
  let showColorPicker: () -> Void

  @State private var isRenaming = false
  @State private var renameDraft = ""
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
      Button("Rename", systemImage: "text.cursor", action: beginRename)
      Button("Duplicate", systemImage: "plus.square.on.square", action: duplicate)

      Divider()

      Button("Change Icon", systemImage: "square.grid.3x3", action: showIconPicker)
      Button("Change Color", systemImage: "paintpalette", action: showColorPicker)

      Divider()

      Button("Delete", systemImage: "trash", role: .destructive, action: delete)
        .disabled(!canDelete)
    }
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
