import M600Core
import SwiftUI

struct RootView: View {
  @ObservedObject var model: AppModel
  @State private var presentedProfileAppearancePicker: ProfileAppearancePicker?

  var body: some View {
    NavigationSplitView {
      List(selection: $model.selectedProfileID) {
        Section("Local profiles") {
          ForEach(model.profiles) { profile in
            ProfileSidebarRow(
              profile: profile,
              canDelete: model.profiles.count > 1,
              rename: { model.renameProfile(profile.id, to: $0) },
              duplicate: { model.duplicateProfile(profile.id) },
              delete: { model.deleteProfile(profile.id) },
              showIconPicker: { showAppearancePicker(.icon, for: profile.id) },
              showColorPicker: { showAppearancePicker(.color, for: profile.id) }
            )
            .tag(profile.id)
          }
        }
      }
      .navigationTitle("M600")
      .toolbar {
        ToolbarItem {
          Button(action: model.addProfile) {
            Label("New Profile", systemImage: "plus")
          }
        }
      }
      .navigationSplitViewColumnWidth(min: 210, ideal: 240)
    } detail: {
      if let index = model.selectedIndex {
        ProfileEditorView(
          profile: $model.profiles[index],
          device: model.device,
          save: model.save,
          presentedAppearancePicker: $presentedProfileAppearancePicker
        )
        .id(model.profiles[index].id)
      } else {
        ContentUnavailableView("Select a profile", systemImage: "computermouse")
      }
    }
    .alert(
      "Could not save profiles",
      isPresented: Binding(
        get: { model.persistenceError != nil },
        set: { if !$0 { model.persistenceError = nil } }
      )
    ) {
      Button("OK") { model.persistenceError = nil }
    } message: {
      Text(model.persistenceError ?? "Unknown error")
    }
    .onChange(of: model.selectedProfileID) { model.save() }
  }

  private func showAppearancePicker(
    _ picker: ProfileAppearancePicker,
    for profileID: UUID
  ) {
    model.selectProfile(profileID)

    // A context-menu action dismisses its menu automatically. Deferring presentation by one
    // main-actor turn gives AppKit time to remove that menu before SwiftUI attaches the toolbar
    // popover, avoiding an intermittent no-op when the target profile was not already selected.
    Task { @MainActor in
      await Task.yield()
      presentedProfileAppearancePicker = picker
    }
  }
}
