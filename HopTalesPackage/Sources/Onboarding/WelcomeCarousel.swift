import Content
import DesignSystem
import SwiftUI
import World

struct WelcomeCarousel: View {
  let getStarted: () -> Void
  @State private var slide = 0

  static let slides: [(title: String, detail: String)] = [
    (
      "Reading, out loud",
      "Your child reads each word aloud, and the ball hops to the next one the moment "
        + "they say it."
    ),
    (
      "A world that grows with every word",
      "Each word read moves the story along, from a sunny meadow to a castle and a friendly dragon."
    ),
    (
      "Private by design",
      "Listening happens on this device. Nothing is recorded or sent anywhere, and there "
        + "are no ads."
    )
  ]

  var body: some View {
    VStack(spacing: 0) {
      TabView(selection: $slide) {
        ForEach(Self.slides.indices, id: \.self) { index in
          VStack(spacing: 32) {
            art(for: index)
              .frame(maxWidth: .infinity)
              .frame(height: 300)
            PageTitle(title: Self.slides[index].title, detail: Self.slides[index].detail)
            Spacer(minLength: 0)
          }
          .padding(.horizontal, 24)
          .padding(.top, 24)
          .frame(maxWidth: 560)
          .tag(index)
        }
      }
      .tabViewStyle(.page(indexDisplayMode: .never))
      SlideDots(count: Self.slides.count, current: slide)
        .padding(.bottom, 24)
      PrimaryButton(title: "Get started", action: getStarted)
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }
    .background(Palette.page.ignoresSafeArea())
    .toolbar(.hidden, for: .navigationBar)
  }

  @ViewBuilder
  private func art(for index: Int) -> some View {
    switch index {
    case 0: HopArt()
    case 1: WorldArt()
    default: PrivacyArt()
    }
  }
}

struct SlideDots: View {
  let count: Int
  let current: Int

  var body: some View {
    HStack(spacing: 8) {
      ForEach(0..<count, id: \.self) { index in
        Capsule()
          .fill(index == current ? Palette.amber : Palette.trackBg)
          .frame(width: index == current ? 22 : 8, height: 8)
      }
    }
    .animation(.easeInOut(duration: 0.2), value: current)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Page \(current + 1) of \(count)")
  }
}

struct HopArt: View {
  var body: some View {
    ZStack {
      Color.clear
        .parchmentBevel(RoundedRectangle(cornerRadius: 32, style: .continuous), border: 4, drop: 6)
      VStack(spacing: 18) {
        Circle()
          .fill(
            RadialGradient(
              colors: [Palette.ballHi, Palette.ball, Palette.ballLo],
              center: UnitPoint(x: 0.35, y: 0.3),
              startRadius: 0,
              endRadius: 40
            )
          )
          .frame(width: 48, height: 48)
        HStack(alignment: .firstTextBaseline, spacing: 14) {
          Text("The")
            .font(Typography.word(22))
            .foregroundStyle(Palette.pillText)
            .padding(.horizontal, 9)
            .padding(.vertical, 3)
            .bevel(
              Palette.goldLight,
              lip: Palette.gold,
              shape: RoundedRectangle(cornerRadius: 12, style: .continuous),
              border: 2.5,
              drop: 3
            )
          Text("cat")
            .font(Typography.word(64))
            .foregroundStyle(Palette.ink)
          Text("sat")
            .font(Typography.word(22))
            .foregroundStyle(Palette.muted)
        }
      }
    }
    .accessibilityHidden(true)
  }
}

struct WorldArt: View {
  var body: some View {
    WorldView(progress: 700, mood: Mood(sky: .golden, weather: .clouds))
      .clipShape(.rect(cornerRadius: 32, style: .continuous))
      .overlay {
        RoundedRectangle(cornerRadius: 32, style: .continuous)
          .strokeBorder(Palette.outline, lineWidth: 4)
      }
      .allowsHitTesting(false)
      .accessibilityHidden(true)
  }
}

struct PrivacyArt: View {
  var body: some View {
    ZStack {
      Color.clear
        .parchmentBevel(RoundedRectangle(cornerRadius: 32, style: .continuous), border: 4, drop: 6)
      HStack(spacing: 22) {
        badge("iphone")
        badge("lock.fill")
        badge("hand.raised.fill")
      }
    }
    .accessibilityHidden(true)
  }

  private func badge(_ symbol: String) -> some View {
    Image(systemName: symbol)
      .font(.system(size: 34, weight: .semibold))
      .foregroundStyle(Palette.onTeal)
      .frame(width: 84, height: 84)
      .bevel(Palette.teal, lip: Palette.tealShade, shape: Circle(), border: 3, drop: 4)
  }
}
