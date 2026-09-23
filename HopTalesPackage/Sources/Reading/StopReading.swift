import DesignSystem
import SwiftUI

struct StopReading: View {
  let keepReading: () -> Void
  let stop: () -> Void

  var body: some View {
    ZStack {
      Palette.duskRoot.opacity(0.55)
        .ignoresSafeArea()
        .onTapGesture(perform: keepReading)
        .accessibilityHidden(true)
      VStack(spacing: 18) {
        Text("Stop reading?")
          .font(Typography.display(30))
          .foregroundStyle(Palette.ink)
          .accessibilityAddTraits(.isHeader)
        Text("You can come back to this story any time.")
          .font(Typography.ui(16))
          .foregroundStyle(Palette.muted)
          .multilineTextAlignment(.center)
        Button(action: keepReading) {
          Label("Keep reading", systemImage: "book.fill")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.ink(.primary))
        .padding(.top, 4)
        Button(action: stop) {
          Label("Stop", systemImage: "house.fill")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.ink(.secondary))
      }
      .padding(28)
      .frame(maxWidth: 330)
      .bevel(
        Palette.parchment,
        lip: Palette.parchmentLip,
        shape: RoundedRectangle(cornerRadius: 32, style: .continuous),
        border: 4,
        drop: 6,
        lipHeight: 9
      )
      .shadow(color: Color(hex: 0x0C0A1E, opacity: 0.32), radius: 17, x: 0, y: 22)
    }
    .accessibilityElement(children: .contain)
  }
}

#if DEBUG
struct StopReadingPreview: View {
  var body: some View {
    ZStack {
      Color(hex: 0x8FCB6B)
      StopReading {} stop: {}
    }
    .frame(width: Metrics.phone.reference.width, height: Metrics.phone.reference.height)
  }
}

#Preview { StopReadingPreview() }
#endif
