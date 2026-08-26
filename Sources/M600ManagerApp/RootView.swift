import M600Core
import SwiftUI

struct RootView: View {
  @ObservedObject var model: AppModel

  var body: some View {
    NavigationSplitView {
      List(selection: $model.selectedProfileID) {
        Section("Local profiles") {
          ForEach(model.profiles) { profile in
            Label {
              Text(profile.name)
            } icon: {
              Image(
                systemName: ProfileIconCatalog.resolvedIconName(profile.resolvedIconName)
              )
              .foregroundStyle(profile.resolvedProfileColor.swiftUIColor)
            }
            .accessibilityLabel(profile.name)
            .tag(profile.id)
          }
        }
      }
      .navigationTitle("M600")
      .toolbar {
        ToolbarItemGroup {
          Button(action: model.addProfile) {
            Label("New Profile", systemImage: "plus")
          }
          Menu {
            Button("Duplicate Profile", action: model.duplicateSelectedProfile)
            Button("Delete Profile", role: .destructive, action: model.deleteSelectedProfile)
              .disabled(model.profiles.count <= 1)
          } label: {
            Label("Profile Actions", systemImage: "ellipsis.circle")
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
