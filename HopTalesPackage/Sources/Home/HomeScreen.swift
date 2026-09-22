import ComposableArchitecture2
import Content
import DesignSystem
import SwiftUI

@Feature public struct Home {
  public init() {}

  public struct State {
    var progress = Content.Progress()
    var stories = StoryLibrary.all
    public init() {}
  }

  public enum Action {
    case storyTapped(Story)
  }

  public var body: some Feature {
    Update { _, _ in }
  }
}

public struct HomeScreen: View {
  let store: StoreOf<Home>

  public init(store: StoreOf<Home>) {
    self.store = store
  }

  public var body: some View {
    List {
      Section {
        ForEach(store.stories) { story in
          Button {
            store.send(.storyTapped(story))
          } label: {
            VStack(alignment: .leading, spacing: 4) {
              Text(story.title)
                .font(Typography.ui(19))
                .foregroundStyle(Palette.ink)
              Text("\(story.sentences.count) SENTENCES")
                .font(Typography.caps(11))
                .tracking(1.76)
                .foregroundStyle(Palette.chipText)
            }
            .padding(.vertical, 6)
          }
        }
      } header: {
        Text("Stories")
          .font(Typography.caps(11))
          .tracking(1.76)
      }
    }
    .navigationTitle("Hello")
  }
}

#Preview {
  NavigationStack {
    HomeScreen(store: Store(initialState: Home.State()) { Home() })
  }
}
