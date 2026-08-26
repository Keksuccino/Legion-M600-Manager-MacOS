import M600Core
import SwiftUI

enum ProfileIconCategory: String, CaseIterable, Identifiable {
  case generic = "Generic"
  case gaming = "Gaming"
  case music = "Music"
  case coding = "Coding"
  case office = "Office"
  case creative = "Image & Art"
  case communication = "Chatting"
  case streaming = "Streaming & Recording"
  case nature = "Flowers & Nature"
  case cleaning = "Cleaning & Home"

  var id: Self { self }
}

struct ProfileIconOption: Identifiable, Hashable {
  let systemName: String
  let name: String
  let category: ProfileIconCategory

  var id: String { systemName }
}

enum ProfileIconCatalog {
  static let options: [ProfileIconOption] = [
    option("computermouse", "Mouse", .generic),
    option("keyboard", "Keyboard", .generic),
    option("laptopcomputer", "Laptop", .generic),
    option("desktopcomputer", "Desktop Computer", .generic),
    option("gearshape", "Settings", .generic),

    option("gamecontroller", "Game Controller", .gaming),
    option("dice", "Dice", .gaming),
    option("puzzlepiece", "Puzzle", .gaming),
    option("trophy", "Trophy", .gaming),
    option("scope", "Scope", .gaming),

    option("music.note", "Music", .music),
    option("headphones", "Headphones", .music),
    option("hifispeaker", "Speaker", .music),
    option("waveform", "Audio Waveform", .music),
    option("radio", "Radio", .music),

    option("terminal", "Terminal", .coding),
    option("chevron.left.forwardslash.chevron.right", "Source Code", .coding),
    option("curlybraces", "Code Braces", .coding),
    option("hammer", "Build", .coding),
    option("wrench.and.screwdriver", "Development Tools", .coding),

    option("doc.text", "Document", .office),
    option("folder", "Folder", .office),
    option("calendar", "Calendar", .office),
    option("chart.bar", "Chart", .office),
    option("tablecells", "Spreadsheet", .office),

    option("photo", "Photo", .creative),
    option("camera", "Camera", .creative),
    option("paintpalette", "Paint Palette", .creative),
    option("paintbrush", "Paint Brush", .creative),
    option("crop", "Image Editing", .creative),

    option("message", "Message", .communication),
    option("bubble.left.and.bubble.right", "Conversation", .communication),
    option("phone", "Phone", .communication),
    option("envelope", "Email", .communication),
    option("person.2", "Team", .communication),

    option("play.rectangle", "Streaming", .streaming),
    option("video", "Video", .streaming),
    option("dot.radiowaves.left.and.right", "Broadcast", .streaming),
    option("record.circle", "Recording", .streaming),
    option("mic", "Microphone", .streaming),

    option("camera.macro", "Flower", .nature),
    option("leaf", "Leaf", .nature),
    option("tree", "Tree", .nature),
    option("sun.max", "Sun", .nature),
    option("drop", "Water", .nature),

    option("bubbles.and.sparkles", "Cleaning", .cleaning),
    option("washer", "Washing Machine", .cleaning),
    option("dishwasher", "Dishwasher", .cleaning),
    option("sparkles", "Clean", .cleaning),
    option("house", "Home", .cleaning),
  ]

  static func options(in category: ProfileIconCategory) -> [ProfileIconOption] {
    options.filter { $0.category == category }
  }

  static func resolvedIconName(_ systemName: String) -> String {
    options.contains(where: { $0.systemName == systemName })
      ? systemName
      : M600Profile.defaultIconName
  }

  private static func option(
    _ systemName: String,
    _ name: String,
    _ category: ProfileIconCategory
  ) -> ProfileIconOption {
    ProfileIconOption(systemName: systemName, name: name, category: category)
  }
}

struct ProfileIconPicker: View {
  @Binding var selection: String
  let tint: Color
  @Binding var isPresented: Bool

  @State private var isHovered = false

  private var columns: [GridItem] {
    Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)
  }

  var body: some View {
    Button {
      isPresented.toggle()
    } label: {
      Image(systemName: ProfileIconCatalog.resolvedIconName(selection))
        .font(.system(size: 15, weight: .semibold))
        .foregroundStyle(tint)
        .frame(width: 28, height: 26)
        .background(
          isHovered ? Color.primary.opacity(0.08) : Color.clear,
          in: RoundedRectangle(cornerRadius: 7, style: .continuous)
        )
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .onHover { isHovered = $0 }
    .help("Choose profile icon")
    .accessibilityLabel("Profile icon")
    .popover(isPresented: $isPresented, arrowEdge: .bottom) {
      pickerContent
    }
  }

  private var pickerContent: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("Choose Profile Icon")
        .font(.headline)

      ScrollView {
        LazyVGrid(columns: columns, spacing: 8) {
          ForEach(ProfileIconCatalog.options) { option in
            iconButton(option)
          }
        }
      }
    }
    .padding(16)
    .frame(width: 310, height: 440)
  }

  private func iconButton(_ option: ProfileIconOption) -> some View {
    Button {
      selection = option.systemName
      isPresented = false
    } label: {
      Image(systemName: option.systemName)
        .font(.system(size: 17, weight: .medium))
        .foregroundStyle(selection == option.systemName ? tint : Color.primary)
        .frame(maxWidth: .infinity, minHeight: 34)
        .background(
          selection == option.systemName ? tint.opacity(0.15) : Color.clear,
          in: RoundedRectangle(cornerRadius: 7, style: .continuous)
        )
        .overlay {
          if selection == option.systemName {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
              .strokeBorder(tint.opacity(0.65))
          }
        }
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .help(option.name)
    .accessibilityLabel(option.name)
  }
}
