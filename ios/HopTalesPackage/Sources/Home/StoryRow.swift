import Content
import DesignSystem
import SwiftUI
import World

struct StoryThumbnail: View {
  nonisolated static let size = CGSize(width: 390, height: 520)

  let mood: Mood
  var cornerRadius: CGFloat = 18
  var height: CGFloat = 62
  @State private var postcard: UIImage?

  init(mood: Mood, cornerRadius: CGFloat = 18, height: CGFloat = 62) {
    self.mood = mood
    self.cornerRadius = cornerRadius
    self.height = height
    _postcard = State(initialValue: MeadowPostcard.cached(mood: mood, size: Self.size))
  }

  var body: some View {
    ZStack(alignment: .bottom) {
      Color(uiColor: MeadowPostcard.ground(for: mood))
      if let postcard {
        Image(uiImage: postcard)
          .resizable()
          .scaledToFill()
          .transition(.opacity)
      }
    }
    .frame(
      minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .bottom
    )
    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    .accessibilityHidden(true)
    .task(id: mood) {
      let image = await MeadowPostcard.rendered(mood: mood, size: Self.size)
      withAnimation(.easeOut(duration: 0.2)) { postcard = image }
    }
  }
}

struct StoryRow: View {
  let standing: StoryStanding
  var isLocked = false
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
    .accessibilityLabel(accessibilityLabel)
    .accessibilityAddTraits(.isButton)
  }

  private var accessibilityLabel: String {
    let label = "\(standing.story.title). \(standing.subtitle)"
    return isLocked ? "\(label). Locked, part of Hop Tales Plus" : label
  }

  private var rowShape: RoundedRectangle {
    RoundedRectangle(cornerRadius: 16, style: .continuous)
  }

  @ViewBuilder
  private var badge: some View {
    if isLocked {
      PadlockSticker(size: 30)
    } else {
      progressBadge
    }
  }

  @ViewBuilder
  private var progressBadge: some View {
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
        .foregroundStyle(Paper.redInk)
        .padding(.trailing, 4)
    }
  }
}

struct LevelRow: View {
  enum Standing: Equatable {
    case locked
    case ready(Story)
    case ahead
  }

  let friend: Friend
  let standing: Standing
  let action: () -> Void

  private var title: String { "Level \(friend.level) with \(friend.name)" }
  private var words: String { friend.examples.joined(separator: ", ") }

  var body: some View {
    Button(action: action) {
      HStack(spacing: 12) {
        FriendSticker(friend, height: 46)
          .frame(width: 50, height: 50)
          .opacity(standing == .ahead ? 0.6 : 1)
        VStack(alignment: .leading, spacing: 1) {
          Text(title)
            .font(Typography.display(17))
            .foregroundStyle(Paper.ink)
          if case .ready = standing {
            Text("\(friend.name)'s big story is ready")
              .font(Typography.ui(13, weight: .semibold))
              .foregroundStyle(Paper.redInk)
          } else {
            Text("Words like \(Text(words).font(Typography.word(15)).foregroundStyle(Paper.ink))")
              .font(Typography.ui(13, weight: .medium))
              .foregroundStyle(Paper.muted)
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        trailing
      }
      .padding(.horizontal, 10)
      .padding(.vertical, 8)
      .background(Paper.shade, in: rowShape)
      .contentShape(rowShape)
    }
    .buttonStyle(.plain)
    .disabled(standing == .ahead)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(accessibilityLabel)
    .accessibilityAddTraits(standing == .ahead ? [] : .isButton)
  }

  @ViewBuilder private var trailing: some View {
    switch standing {
    case .locked:
      PadlockSticker(size: 30)
    case .ready:
      Image(systemName: "play.fill")
        .font(.system(size: 14, weight: .bold))
        .foregroundStyle(Paper.onRed)
        .frame(width: 36, height: 36)
        .paperChip(Circle(), fill: Paper.red)
    case .ahead:
      EmptyView()
    }
  }

  private var accessibilityLabel: String {
    switch standing {
    case .locked: "\(title). Words like \(words). Locked, part of Hop Tales Plus"
    case .ready: "\(title). \(friend.name)'s big story is ready"
    case .ahead: "\(title). Words like \(words). Read your stories to get there"
    }
  }

  private var rowShape: RoundedRectangle {
    RoundedRectangle(cornerRadius: 16, style: .continuous)
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
