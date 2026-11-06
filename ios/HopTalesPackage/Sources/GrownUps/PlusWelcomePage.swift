import Content
import DesignSystem
import SwiftUI
import World

struct PlusWelcomePage: View {
  let welcome: PlusWelcome?
  let send: (Paywall.Action) -> Void

  var body: some View {
    VStack(spacing: 14) {
      IdleFriend(welcome?.friend ?? PaywallScene.friend, look: nil, height: 130)
        .shadow(color: Paper.shadow, radius: 5, y: 4)
        .padding(.top, 8)
        .accessibilityHidden(true)
      Text("Welcome to Hop Tales Plus!")
        .font(Typography.display(28))
        .foregroundStyle(Paper.ink)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityAddTraits(.isHeader)
      Text(line)
        .font(Typography.ui(17, weight: .medium))
        .foregroundStyle(Paper.muted)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
      if let welcome {
        Button(readTitle(welcome)) { send(.readTapped) }
          .buttonStyle(.paper)
          .padding(.top, 6)
        Button("Back to stories") { send(.closeTapped) }
          .buttonStyle(.paperQuiet)
      } else {
        Button("Back to stories") { send(.closeTapped) }
          .buttonStyle(.paper)
          .padding(.top, 6)
      }
    }
  }

  private var line: String {
    guard let welcome else { return "Every story and every level is open now." }
    let friend = welcome.friend
    if welcome.meetsFriend {
      return "\(friend.name) has a big story waiting for you. "
        + "Read it to reach Level \(friend.level)."
    }
    if welcome.story.friend == friend {
      return "Every story is open now. Up next: \(welcome.story.title)."
    }
    return "Every level is open now. Read the rest of your stories and \(friend.name) "
      + "will be waiting at Level \(friend.level)."
  }

  private func readTitle(_ welcome: PlusWelcome) -> String {
    welcome.meetsFriend ? "Meet \(welcome.friend.name)" : "Read \(welcome.story.title)"
  }
}
