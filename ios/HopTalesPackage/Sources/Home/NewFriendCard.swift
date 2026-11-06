import Content
import DesignSystem
import SwiftUI
import World

struct NewFriendCard: View {
  let friend: Friend
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 12) {
        FriendSticker(friend, height: 58)
          .frame(width: 62, height: 62)
        VStack(alignment: .leading, spacing: 2) {
          Text("A new friend")
            .font(Typography.caps(12))
            .tracking(12 * 0.06)
            .textCase(.uppercase)
            .foregroundStyle(Paper.redInk)
          Text("Meet \(friend.name)")
            .font(Typography.display(19))
            .foregroundStyle(Paper.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
          Text("Read \(friend.name)'s big story to reach Level \(friend.level)")
            .font(Typography.ui(13, weight: .medium))
            .foregroundStyle(Paper.muted)
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        Image(systemName: "play.fill")
          .font(.system(size: 17, weight: .bold))
          .foregroundStyle(Paper.onRed)
          .frame(width: 46, height: 46)
          .paperChip(Circle(), fill: Paper.red)
      }
      .padding(12)
      .background(Paper.rim, in: shape)
      .overlay(shape.strokeBorder(Paper.red, lineWidth: 3))
      .shadow(color: Paper.shadow.opacity(0.55), radius: 3, y: 2)
      .contentShape(shape)
    }
    .buttonStyle(.plain)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(
      "A new friend. Meet \(friend.name). "
        + "Read \(friend.name)'s big story to reach Level \(friend.level)."
    )
    .accessibilityAddTraits(.isButton)
  }

  private var shape: RoundedRectangle {
    RoundedRectangle(cornerRadius: 20, style: .continuous)
  }
}

extension HomeScreen {
  @ViewBuilder var nextCard: some View {
    if let keepGoing = store.keepGoing {
      if let newFriend = store.state.newFriend, keepGoing.story.isBigStory {
        NewFriendCard(friend: newFriend) { store.send(.storyTapped(keepGoing.story)) }
      } else {
        KeepGoingCard(standing: keepGoing) { store.send(.storyTapped(keepGoing.story)) }
      }
    }
  }

  @ViewBuilder var waitingFriend: some View {
    if let newFriend = store.state.newFriend, let story = store.state.bigStoryWaiting {
      WaitingFriend(friend: newFriend) { store.send(.storyTapped(story)) }
        .offset(x: 118)
    }
  }
}

struct WaitingFriend: View {
  let friend: Friend
  let action: () -> Void
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var bobbing = false

  var body: some View {
    Button(action: action) {
      VStack(spacing: 4) {
        Text("New!")
          .font(Typography.ui(13, weight: .bold))
          .foregroundStyle(Paper.onRed)
          .padding(.horizontal, 10)
          .padding(.vertical, 4)
          .background(Paper.red, in: Capsule())
          .offset(y: bobbing ? -4 : 0)
        IdleFriend(friend, look: nil, height: 104)
          .shadow(color: Paper.shadow, radius: 5, y: 3)
      }
    }
    .buttonStyle(.plain)
    .accessibilityLabel("\(friend.name) is waiting with a big story")
    .onAppear {
      guard !reduceMotion else { return }
      withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { bobbing = true }
    }
  }
}
