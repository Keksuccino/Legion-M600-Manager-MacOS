import AppKit
import M600Core
import SwiftUI

struct LightingView: View {
  @Binding var zones: [LightingZone]
  let stealthModeActive: Bool?

  var body: some View {
    Form {
      Section {
        Text("The M600 stores two independent 12-byte lighting programs in every profile.")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      if stealthModeActive == true {
        Section {
          Label(
            "The mouse's hardware stealth mode is on, so both LEDs stay off even when a lighting profile is applied. Press the dedicated light/stealth button on the mouse to turn lighting back on.",
            systemImage: "lightbulb.slash.fill"
          )
          .foregroundStyle(.orange)
        }
      }
      LightingZoneView(name: "Zone 1 · Scroll wheel", zone: $zones[0])
      LightingZoneView(name: "Zone 2 · Legion logo", zone: $zones[1])
    }
    .formStyle(.grouped)
  }
}

private struct LightingZoneView: View {
  let name: String
  @Binding var zone: LightingZone

  var body: some View {
    Section(name) {
      Picker("Effect", selection: $zone.effect) {
        ForEach(LightingEffect.allCases) { effect in
          Text(effect.displayName).tag(effect)
        }
      }
      if zone.effect == .staticColor || zone.effect == .breathing {
        ColorPicker(
          "Primary color", selection: colorBinding($zone.primaryColor), supportsOpacity: false)
      }
      if zone.effect == .breathing {
        ColorPicker(
          "Secondary color", selection: colorBinding($zone.secondaryColor), supportsOpacity: false)
        Text(
          "Black uses Lenovo's single-color breathing mode; another color alternates between both colors."
        )
        .font(.caption)
        .foregroundStyle(.secondary)
      }
    }
  }

  private func colorBinding(_ rgb: Binding<M600Core.RGBColor>) -> Binding<Color> {
    Binding(
      get: {
        Color(
          red: Double(rgb.wrappedValue.red) / 255,
          green: Double(rgb.wrappedValue.green) / 255,
          blue: Double(rgb.wrappedValue.blue) / 255)
      },
      set: { color in
        guard let converted = NSColor(color).usingColorSpace(.deviceRGB) else { return }
        rgb.wrappedValue = M600Core.RGBColor(
          red: UInt8(clamping: Int((converted.redComponent * 255).rounded())),
          green: UInt8(clamping: Int((converted.greenComponent * 255).rounded())),
          blue: UInt8(clamping: Int((converted.blueComponent * 255).rounded()))
        )
      }
    )
  }
}
