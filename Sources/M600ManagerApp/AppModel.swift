import Combine
import Foundation
import M600Core

@MainActor
final class AppModel: ObservableObject {
  @Published var profiles: [M600Profile]
  @Published var selectedProfileID: UUID?
  @Published var persistenceError: String?

  let device = M600DeviceController()
  private let store: ProfileStore

  init(store: ProfileStore = ProfileStore()) {
    self.store = store
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

  func duplicateSelectedProfile() {
    guard let index = selectedIndex else { return }
    var duplicate = profiles[index]
    duplicate.id = UUID()
    duplicate.name = "\(duplicate.name) Copy"
    profiles.append(duplicate)
    selectedProfileID = duplicate.id
    save()
  }

  func deleteSelectedProfile() {
    guard profiles.count > 1, let index = selectedIndex else { return }
    profiles.remove(at: index)
    selectedProfileID = profiles[min(index, profiles.count - 1)].id
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
