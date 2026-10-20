import DesignSystem
import SwiftUI

#if DEBUG
struct MicPillPreview: View {
  enum Variant {
    case listening
    case heard
  }

  let variant: Variant

  init(_ variant: Variant) {
    self.variant = variant
  }

  var body: some View {
    let geometry = ReadingGeometry(size: Metrics.phone.reference)
    ZStack {
      Color(hex: 0x8FCB6B)
      MicPill(heardToken: variant == .heard ? "sat" : nil, geometry: geometry, animatesBars: false)
    }
    .frame(width: Metrics.phone.reference.width, height: 120)
  }
}

#Preview("Listening") { MicPillPreview(.listening) }
#Preview("Heard") { MicPillPreview(.heard) }
#endif
