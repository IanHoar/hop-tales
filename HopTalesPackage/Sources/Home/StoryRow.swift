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

struct StoryRow: View {
  let standing: StoryStanding
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 12) {
        StoryThumbnail(mood: standing.story.mood, cornerRadius: 11)
          .frame(width: 50, height: 50)
          .overlay {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
              .strokeBorder(Paper.rim, lineWidth: 3)
          }
        VStack(alignment: .leading, spacing: 1) {
          Text(standing.story.title)
            .font(Typography.display(17))
            .foregroundStyle(Paper.ink)
          Text(standing.subtitle)
            .font(Typography.ui(13, weight: .medium))
            .foregroundStyle(Paper.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        badge
      }
      .padding(.horizontal, 10)
      .padding(.vertical, 8)
      .background(Paper.rim.opacity(0.55), in: rowShape)
      .contentShape(rowShape)
    }
    .buttonStyle(.plain)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(standing.story.title). \(standing.subtitle)")
    .accessibilityAddTraits(.isButton)
  }

  private var rowShape: RoundedRectangle {
    RoundedRectangle(cornerRadius: 16, style: .continuous)
  }

  @ViewBuilder
  private var badge: some View {
    switch standing.standing {
    case .finished:
      Image(systemName: "checkmark.circle.fill")
        .font(.system(size: 24))
        .foregroundStyle(Paper.onRed, Paper.sageDeep)
        .accessibilityHidden(true)
    case .inProgress:
      StarBadge(size: 22)
    case .unread:
      Text("New")
        .font(Typography.ui(13))
        .foregroundStyle(Paper.red)
        .padding(.trailing, 4)
    }
  }
}

struct KeepGoingCard: View {
  let standing: StoryStanding
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 12) {
        StoryThumbnail(mood: standing.story.mood, cornerRadius: 12)
          .frame(width: 62, height: 62)
        VStack(alignment: .leading, spacing: 2) {
          Text(heading)
            .font(Typography.caps(12))
            .tracking(12 * 0.06)
            .textCase(.uppercase)
            .foregroundStyle(Paper.muted)
          Text(standing.story.title)
            .font(Typography.display(19))
            .foregroundStyle(Paper.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
          Text(meta)
            .font(Typography.ui(13, weight: .medium))
            .foregroundStyle(Paper.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        Image(systemName: "play.fill")
          .font(.system(size: 17, weight: .bold))
          .foregroundStyle(Paper.onRed)
          .frame(width: 46, height: 46)
          .paperChip(Circle(), fill: Paper.red)
      }
      .padding(12)
      .background(Paper.rim, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
      .shadow(color: Paper.shadow.opacity(0.55), radius: 3, y: 2)
      .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
    .buttonStyle(.plain)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(heading). \(standing.story.title). \(meta).")
    .accessibilityAddTraits(.isButton)
  }

  private var heading: String {
    standing.isCurrent ? "Keep reading" : "Start here"
  }

  private var total: Int { standing.story.sentences.count }

  private var meta: String {
    guard case .inProgress(let remaining) = standing.standing else { return "Your next story" }
    return "Sentence \(total - remaining + 1) of \(total)"
  }
}
