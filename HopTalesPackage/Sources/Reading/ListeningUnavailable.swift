import DesignSystem
import SpeechRecognition
import SwiftUI

struct ListeningUnavailable: View {
  let authorization: SpeechClient.Authorization
  let action: () -> Void

  var body: some View {
    ZStack {
      Palette.duskRoot.opacity(0.55)
        .ignoresSafeArea()
      VStack(spacing: 16) {
        Image(systemName: authorization == .denied ? "mic.slash" : "iphone.slash")
          .font(.system(size: 44, weight: .light))
          .foregroundStyle(Palette.muted)
        Text(headline)
          .font(Typography.ui(24))
          .foregroundStyle(Palette.ink)
          .multilineTextAlignment(.center)
        Text(explanation)
          .font(Typography.ui(16))
          .foregroundStyle(Palette.muted)
          .multilineTextAlignment(.center)
        Button(action: action) {
          Text("Back to stories")
            .font(Typography.ui(17))
            .foregroundStyle(Palette.cream)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(Palette.ink, in: .capsule)
        }
        .padding(.top, 6)
      }
      .padding(28)
      .frame(maxWidth: 330)
      .background {
        RoundedRectangle(cornerRadius: 34, style: .continuous)
          .fill(Palette.cream)
          .shadow(color: Palette.ink.opacity(0.3), radius: 30, x: 0, y: 16)
      }
    }
  }

  private var headline: String {
    authorization == .denied ? "The microphone is off" : "This device can’t listen yet"
  }

  private var explanation: String {
    switch authorization {
    case .denied:
      """
      Hop Tales listens so it can hear you read. A grown-up can turn the microphone \
      back on in Settings.
      """
    default:
      """
      Hop Tales listens on the device itself, and this one doesn’t support that. \
      You can still read along together.
      """
    }
  }
}

#if DEBUG
struct ListeningUnavailablePreview: View {
  let authorization: SpeechClient.Authorization

  var body: some View {
    ZStack {
      Color(hex: 0x8FCB6B)
      ListeningUnavailable(authorization: authorization) {}
    }
    .frame(width: Metrics.phone.reference.width, height: Metrics.phone.reference.height)
  }
}

#Preview("Denied") { ListeningUnavailablePreview(authorization: .denied) }
#Preview("Unsupported") { ListeningUnavailablePreview(authorization: .unsupported) }
#endif
