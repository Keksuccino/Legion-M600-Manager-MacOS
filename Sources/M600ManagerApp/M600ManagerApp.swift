import SwiftUI

@main
struct M600ManagerApp: App {
  @StateObject private var model = AppModel()

  var body: some Scene {
    WindowGroup("Legion M600 Manager") {
      RootView(model: model)
        .frame(minWidth: 920, minHeight: 640)
    }
    .windowStyle(.titleBar)
    .defaultSize(width: 1080, height: 760)
  }
}
