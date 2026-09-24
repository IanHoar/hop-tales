import Content
import DesignSystem
import SwiftUI
import World

struct StoryThumbnail: View {
  let mood: Mood
  var cornerRadius: CGFloat = 18
  var height: CGFloat = 62

  var body: some View {
    Image(uiImage: MeadowPostcard.image(mood: mood, size: CGSize(width: 390, height: 520)))
      .resizable()
      .scaledToFill()
      .frame(
        minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .bottom
      )
      .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
      .accessibilityHidden(true)
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
        StoryThumbnail(mood: standing.story.mood, cornerRadius: 14)
          .frame(width: 62, height: 62)
          .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
              .strokeBorder(Palette.outline, lineWidth: 3)
          }
        VStack(alignment: .leading, spacing: 2) {
          Text(standing.story.title)
            .font(Typography.display(21))
            .foregroundStyle(Palette.ink)
          Text(standing.subtitle)
            .font(Typography.ui(14, weight: .medium))
            .foregroundStyle(Palette.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        badge
      }
      .padding(.horizontal, 12)
      .frame(height: 88)
      .bevel(
        Palette.paper,
        lip: Palette.parchmentLip,
        shape: RoundedRectangle(cornerRadius: 24, style: .continuous),
        border: 3,
        drop: 4
      )
      .background {
        if standing.isCurrent {
          RoundedRectangle(cornerRadius: 28, style: .continuous)
            .strokeBorder(Palette.gold, lineWidth: 4)
            .padding(-5)
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
        .font(.system(size: 16, weight: .black))
        .foregroundStyle(Palette.outline)
        .frame(width: 38, height: 38)
        .bevel(Palette.done, lip: Palette.doneShade, shape: Circle(), border: 3, drop: 3)
    case .inProgress:
      Coin(size: 34)
    case .unread:
      Text("NEW")
        .font(Typography.display(14))
        .tracking(0.8)
        .foregroundStyle(Palette.onTeal)
        .padding(.horizontal, 12)
        .frame(height: 30)
        .bevel(Palette.newBadge, lip: Palette.newBadgeShade, shape: Capsule(), border: 3, drop: 3)
    }
  }
}

struct KeepGoingCard: View {
  let standing: StoryStanding
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      VStack(spacing: 0) {
        StoryThumbnail(mood: standing.story.mood, cornerRadius: 0, height: 124)
          .frame(height: 124)
        Rectangle().fill(Palette.outline).frame(height: 4)
        HStack(spacing: 14) {
          VStack(alignment: .leading, spacing: 4) {
            Text(heading)
              .font(Typography.caps(12))
              .tracking(12 * 0.14)
              .foregroundStyle(Palette.muted)
            Text(standing.story.title)
              .font(Typography.display(24))
              .foregroundStyle(Palette.ink)
            MiniTrail(done: completedCount, total: total)
              .padding(.top, 4)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          Image(systemName: "play.fill")
            .font(.system(size: 22, weight: .black))
            .foregroundStyle(Palette.outline)
            .frame(width: 62, height: 62)
            .bevel(Palette.gold, lip: Palette.goldShade, shape: Circle(), border: 3, drop: 5)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
      }
      .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
      .bevel(
        Palette.paper,
        lip: Palette.parchmentLip,
        shape: RoundedRectangle(cornerRadius: 28, style: .continuous),
        border: 4,
        drop: 6
      )
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
}

struct MiniTrail: View {
  let done: Int
  let total: Int

  var body: some View {
    ZStack(alignment: .leading) {
      Capsule().fill(Palette.track).frame(height: 8)
        .overlay(Capsule().strokeBorder(Palette.outline, lineWidth: 2))
      HStack(spacing: 0) {
        ForEach(0..<total, id: \.self) { index in
          node(index)
          if index < total - 1 { Spacer(minLength: 0) }
        }
      }
    }
    .frame(width: 190, height: 26)
    .accessibilityHidden(true)
  }

  @ViewBuilder
  private func node(_ index: Int) -> some View {
    if index < done {
      Circle().fill(Palette.gold)
        .overlay(Circle().strokeBorder(Palette.outline, lineWidth: 2.5))
        .frame(width: 16, height: 16)
    } else if index == done {
      Circle().fill(Palette.parchment)
        .overlay(Circle().fill(Palette.ball).padding(5))
        .overlay(Circle().strokeBorder(Palette.outline, lineWidth: 2.5))
        .frame(width: 22, height: 22)
    } else {
      Circle().fill(Palette.stone)
        .overlay(Circle().strokeBorder(Palette.outline, lineWidth: 2.5))
        .frame(width: 14, height: 14)
    }
  }
}
