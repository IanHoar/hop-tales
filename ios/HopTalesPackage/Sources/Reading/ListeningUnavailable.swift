import DesignSystem
import SpeechRecognition
import SwiftUI

struct ListeningUnavailable: View {
  let authorization: SpeechClient.Authorization
  let action: () -> Void

  var body: some View {
    ZStack {
      Paper.night.opacity(0.45)
        .ignoresSafeArea()
        .accessibilityHidden(true)
      VStack(spacing: 14) {
        Image(systemName: authorization == .denied ? "mic.slash" : "iphone.slash")
          .font(.system(size: 44, weight: .light))
          .foregroundStyle(Paper.muted)
          .accessibilityHidden(true)
        PaperLabel(seed: 17) {
          Text(headline)
            .font(Typography.display(26))
            .foregroundStyle(Paper.ink)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
        }
        .rotationEffect(.degrees(-2))
        .accessibilityAddTraits(.isHeader)
        Text(explanation)
          .font(Typography.ui(16, weight: .medium))
          .foregroundStyle(Paper.ink.opacity(0.85))
          .multilineTextAlignment(.center)
          .fixedSize(horizontal: false, vertical: true)
        Button(action: action) {
          Label("Back to stories", systemImage: "house.fill")
        }
        .buttonStyle(.paper)
        .padding(.top, 6)
      }
      .padding(.horizontal, 24)
      .padding(.vertical, 28)
      .frame(maxWidth: 340)
      .background {
        Deckle(seed: 53, jitter: 3, step: 12)
          .fill(Paper.paper)
          .shadow(color: Paper.shadow, radius: 12, y: 8)
      }
      .rotationEffect(.degrees(-1))
      .padding(.horizontal, 24)
    }
    .accessibilityElement(children: .contain)
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
