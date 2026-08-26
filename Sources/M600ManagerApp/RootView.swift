import M600Core
import SwiftUI

struct RootView: View {
  @ObservedObject var model: AppModel

  var body: some View {
    NavigationSplitView {
      List(selection: $model.selectedProfileID) {
        Section("Local profiles") {
          ForEach(model.profiles) { profile in
            ProfileSidebarRow(
              profile: profile,
              canDelete: model.profiles.count > 1,
              edit: { model.selectProfile(profile.id) },
              rename: { model.renameProfile(profile.id, to: $0) },
              duplicate: { model.duplicateProfile(profile.id) },
              delete: { model.deleteProfile(profile.id) },
              setIcon: { model.setProfileIcon(profile.id, to: $0) },
              setColor: { model.setProfileColor(profile.id, to: $0) }
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
          save: model.save
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
}
