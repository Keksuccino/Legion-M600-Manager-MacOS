import M600Core
import SwiftUI

struct LightingView: View {
  @Binding var zones: [LightingZone]
  let stealthModeActive: Bool?

  var body: some View {
    Form {
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
          "Primary color", selection: $zone.primaryColor.swiftUIColor, supportsOpacity: false)
      }
      if zone.effect == .breathing {
        ColorPicker(
          "Secondary color", selection: $zone.secondaryColor.swiftUIColor, supportsOpacity: false)
        Text(
          "Black uses Lenovo's single-color breathing mode; another color alternates between both colors."
        )
        .font(.caption)
        .foregroundStyle(.secondary)
      }
    }
  }
}
