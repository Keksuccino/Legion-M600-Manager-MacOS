import AppKit
import M600Core
import SwiftUI

extension M600Core.RGBColor {
  var swiftUIColor: Color {
    Color(
      red: Double(red) / 255,
      green: Double(green) / 255,
      blue: Double(blue) / 255
    )
  }

  init?(swiftUIColor: Color) {
    guard let converted = NSColor(swiftUIColor).usingColorSpace(.deviceRGB) else { return nil }
    self.init(
      red: UInt8(clamping: Int((converted.redComponent * 255).rounded())),
      green: UInt8(clamping: Int((converted.greenComponent * 255).rounded())),
      blue: UInt8(clamping: Int((converted.blueComponent * 255).rounded()))
    )
  }
}

extension Binding where Value == M600Core.RGBColor {
  var swiftUIColor: Binding<Color> {
    Binding<Color>(
      get: { wrappedValue.swiftUIColor },
      set: { color in
        guard let converted = M600Core.RGBColor(swiftUIColor: color) else { return }
        wrappedValue = converted
      }
    )
  }
}
