import Content
import DesignSystem
import SwiftUI

struct StoryThumbnail: View {
  let stage: StageTheme
  var cornerRadius: CGFloat = 18

  var body: some View {
    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
      .fill(
        LinearGradient(
          colors: colours,
          startPoint: .top,
          endPoint: .bottom
        )
      )
      .overlay(alignment: .bottom) {
        Hill()
          .fill(ground)
          .frame(height: 22)
      }
      .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
  }

  private var colours: [Color] {
    switch stage {
    case .meadow: [Color(hex: 0x6EC3EE), Color(hex: 0xA9E0F5)]
    case .castle: [Color(hex: 0x3E8FC9), Color(hex: 0xF5C77E)]
    case .dragon: [Color(hex: 0x0F0D2A), Color(hex: 0x5A2B5E)]
    }
  }

  private var ground: Color {
    switch stage {
    case .meadow: Color(hex: 0x8FCB6B)
    case .castle: Color(hex: 0xB98A46)
    case .dragon: Color(hex: 0x241A3D)
    }
  }
}

struct Hill: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
    path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
    path.addQuadCurve(
      to: CGPoint(x: rect.maxX, y: rect.midY),
      control: CGPoint(x: rect.midX, y: rect.minY)
    )
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
    path.closeSubpath()
    return path
  }
}

struct StoryRow: View {
  let standing: StoryStanding
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 14) {
        StoryThumbnail(stage: standing.story.stage)
          .frame(width: 60, height: 60)
        VStack(alignment: .leading, spacing: 2) {
          Text(standing.story.title)
            .font(Typography.ui(18))
            .foregroundStyle(Palette.ink)
          Text(standing.subtitle)
            .font(Typography.ui(14))
            .foregroundStyle(Palette.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        badge
      }
      .padding(.horizontal, 16)
      .frame(height: 92)
      .background {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
          .fill(.white)
          .shadow(color: Palette.ink.opacity(0.07), radius: 0, x: 0, y: 6)
          .shadow(color: Palette.ink.opacity(0.08), radius: 12, x: 0, y: 12)
      }
      .overlay {
        if standing.isCurrent {
          RoundedRectangle(cornerRadius: 26, style: .continuous)
            .strokeBorder(Palette.amber, lineWidth: 3)
        }
      }
    }
    .buttonStyle(.plain)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(standing.story.title). \(standing.subtitle)")
    .accessibilityAddTraits(.isButton)
  }

  @ViewBuilder
  private var badge: some View {
    switch standing.standing {
    case .finished:
      Image(systemName: "checkmark")
        .font(.system(size: 15, weight: .bold))
        .foregroundStyle(Palette.heardText)
        .frame(width: 32, height: 32)
        .background(Palette.heardBg, in: .circle)
    case .inProgress:
      Image(systemName: "chevron.right")
        .font(.system(size: 14, weight: .bold))
        .foregroundStyle(Palette.starText)
        .frame(width: 32, height: 32)
        .background(Palette.creamDeep, in: .circle)
    case .unread:
      Text("NEW")
        .font(Typography.caps(12))
        .tracking(0.96)
        .foregroundStyle(Palette.newBadgeText)
        .padding(.horizontal, 11)
        .frame(height: 28)
        .background(Palette.newBadgeBg, in: .capsule)
    }
  }
}

struct KeepGoingCard: View {
  let standing: StoryStanding
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      VStack(spacing: 0) {
        StoryThumbnail(stage: standing.story.stage, cornerRadius: 0)
          .frame(height: 104)
        HStack(spacing: 14) {
          VStack(alignment: .leading, spacing: 3) {
            Text(heading)
              .font(Typography.caps(10))
              .tracking(1.6)
              .foregroundStyle(Palette.muted)
            Text(standing.story.title)
              .font(Typography.ui(20))
              .foregroundStyle(Palette.ink)
            progress
              .padding(.top, 4)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          playButton
        }
        .padding(.horizontal, 18)
        .frame(height: 80)
        .background(.white)
      }
      .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
      .background {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
          .fill(.white)
          .shadow(color: Palette.ink.opacity(0.10), radius: 0, x: 0, y: 10)
          .shadow(color: Palette.ink.opacity(0.14), radius: 20, x: 0, y: 20)
      }
    }
    .buttonStyle(.plain)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(heading). \(standing.story.title). \(completedCount) of \(total).")
    .accessibilityAddTraits(.isButton)
  }

  private var heading: String {
    standing.isCurrent ? "KEEP GOING" : "START HERE"
  }

  private var total: Int { standing.story.sentences.count }

  private var completedCount: Int {
    if case .inProgress(let remaining) = standing.standing { return total - remaining }
    return standing.standing == .finished ? total : 0
  }

  private var progress: some View {
    HStack(spacing: 8) {
      Capsule()
        .fill(Palette.trackBg)
        .frame(width: 120, height: 7)
        .overlay(alignment: .leading) {
          Capsule()
            .fill(Palette.amber)
            .frame(width: 120 * CGFloat(completedCount) / CGFloat(max(total, 1)), height: 7)
        }
      Text("\(completedCount) of \(total)")
        .font(Typography.ui(13))
        .foregroundStyle(Palette.muted)
    }
  }

  private var playButton: some View {
    Image(systemName: "play.fill")
      .font(.system(size: 20, weight: .bold))
      .foregroundStyle(.white)
      .frame(width: 56, height: 56)
      .background(
        LinearGradient(
          colors: [Color(hex: 0xFFB86A), Color(hex: 0xFF9F45), Palette.amberDeep],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        ),
        in: .circle
      )
      .shadow(color: Color(hex: 0xC4661A), radius: 0, x: 0, y: 4)
  }
}
