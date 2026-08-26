import M600Core
import SwiftUI

struct ProfileColorOption: Identifiable {
  let name: String
  let color: M600Core.RGBColor

  var id: String { name }
}

enum ProfileColorCatalog {
  static let options: [ProfileColorOption] = [
    option("Legion Blue", 0, 180, 255),
    option("Sky", 55, 145, 255),
    option("Indigo", 94, 92, 230),
    option("Purple", 175, 82, 222),
    option("Magenta", 225, 70, 170),
    option("Pink", 255, 85, 130),
    option("Red", 245, 75, 75),
    option("Orange", 255, 145, 45),
    option("Amber", 245, 190, 45),
    option("Yellow", 240, 220, 55),
    option("Lime", 155, 210, 55),
    option("Green", 55, 195, 100),
    option("Mint", 50, 205, 165),
    option("Teal", 45, 190, 205),
    option("Cyan", 45, 210, 235),
    option("Slate", 105, 125, 150),
    option("Silver", 180, 185, 195),
    option("White", 240, 240, 245),
  ]

  private static func option(
    _ name: String,
    _ red: UInt8,
    _ green: UInt8,
    _ blue: UInt8
  ) -> ProfileColorOption {
    ProfileColorOption(
      name: name,
      color: M600Core.RGBColor(red: red, green: green, blue: blue)
    )
  }
}

struct ProfileColorPicker: View {
  @Binding var selection: M600Core.RGBColor

  @State private var isPresented = false
  @State private var isHovered = false

  private let columns = Array(repeating: GridItem(.fixed(30), spacing: 10), count: 6)

  var body: some View {
    Button {
      isPresented.toggle()
    } label: {
      ZStack {
        Circle()
          .fill(selection.swiftUIColor)
        Circle()
          .strokeBorder(Color.primary.opacity(0.28), lineWidth: 1)
      }
      .frame(width: 18, height: 18)
      .frame(width: 28, height: 26)
      .background(
        isHovered ? Color.primary.opacity(0.08) : Color.clear,
        in: RoundedRectangle(cornerRadius: 7, style: .continuous)
      )
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .onHover { isHovered = $0 }
    .help("Choose profile color")
    .accessibilityLabel("Profile color")
    .popover(isPresented: $isPresented, arrowEdge: .bottom) {
      pickerContent
    }
  }

  private var pickerContent: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("Choose Profile Color")
        .font(.headline)

      LazyVGrid(columns: columns, spacing: 10) {
        ForEach(ProfileColorCatalog.options) { option in
          presetButton(option)
        }
      }

      Divider()

      ColorPicker(
        "Custom Color",
        selection: $selection.swiftUIColor,
        supportsOpacity: false
      )
    }
    .padding(16)
    .frame(width: 258)
  }

  private func presetButton(_ option: ProfileColorOption) -> some View {
    let isSelected = option.color == selection

    return Button {
      selection = option.color
    } label: {
      ZStack {
        Circle()
          .fill(option.color.swiftUIColor)
        Circle()
          .strokeBorder(Color.primary.opacity(0.22), lineWidth: 1)
        if isSelected {
          Circle()
            .strokeBorder(Color.primary, lineWidth: 2)
            .padding(3)
        }
      }
      .frame(width: 30, height: 30)
      .contentShape(Circle())
    }
    .buttonStyle(.plain)
    .help(option.name)
    .accessibilityLabel(option.name)
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }
}
