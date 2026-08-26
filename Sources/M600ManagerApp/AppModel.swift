import Combine
import Foundation
import M600Core

@MainActor
final class AppModel: ObservableObject {
  @Published var profiles: [M600Profile]
  @Published var selectedProfileID: UUID?
  @Published var persistenceError: String?

  let device: M600DeviceController
  private let store: ProfileStore

  init(
    store: ProfileStore = ProfileStore(),
    device: M600DeviceController? = nil
  ) {
    self.store = store
    self.device = device ?? M600DeviceController()
    do {
      let stored = try store.load()
      profiles = stored.profiles
      selectedProfileID = stored.selectedProfileID ?? stored.profiles.first?.id
    } catch {
      let profile = M600Profile()
      profiles = [profile]
      selectedProfileID = profile.id
      persistenceError = error.localizedDescription
    }
  }

  var selectedIndex: Int? {
    guard let selectedProfileID else { return nil }
    return profiles.firstIndex(where: { $0.id == selectedProfileID })
  }

  func addProfile() {
    let number = profiles.count + 1
    let profile = M600Profile(name: "Profile \(number)")
    profiles.append(profile)
    selectedProfileID = profile.id
    save()
  }

  func selectProfile(_ id: UUID) {
    guard profiles.contains(where: { $0.id == id }) else { return }
    selectedProfileID = id
    save()
  }

  func duplicateProfile(_ id: UUID) {
    guard let index = profiles.firstIndex(where: { $0.id == id }) else { return }
    var duplicate = profiles[index]
    duplicate.id = UUID()
    duplicate.name = "\(duplicate.name) Copy"
    profiles.append(duplicate)
    selectedProfileID = duplicate.id
    save()
  }

  func deleteProfile(_ id: UUID) {
    guard profiles.count > 1,
      let index = profiles.firstIndex(where: { $0.id == id })
    else { return }

    let deletedSelectedProfile = selectedProfileID == id
    profiles.remove(at: index)
    if deletedSelectedProfile {
      selectedProfileID = profiles[min(index, profiles.count - 1)].id
    }
    save()
  }

  func renameProfile(_ id: UUID, to name: String) {
    updateProfile(id) { $0.name = name }
  }

  func setProfileIcon(_ id: UUID, to iconName: String) {
    updateProfile(id) {
      $0.iconName = ProfileIconCatalog.resolvedIconName(iconName)
    }
  }

  func setProfileColor(_ id: UUID, to color: M600Core.RGBColor) {
    updateProfile(id) { $0.profileColor = color }
  }

  private func updateProfile(
    _ id: UUID,
    mutation: (inout M600Profile) -> Void
  ) {
    guard let index = profiles.firstIndex(where: { $0.id == id }) else { return }
    mutation(&profiles[index])
    save()
  }

  func save() {
    do {
      try store.save(StoredProfiles(selectedProfileID: selectedProfileID, profiles: profiles))
      persistenceError = nil
    } catch {
      persistenceError = error.localizedDescription
    }
  }
}
