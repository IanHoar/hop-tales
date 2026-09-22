import ComposableArchitecture2
import Content
import DesignSystem
import SwiftUI

public struct HomeView: View {
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
    HomeView(store: Store(initialState: Home.State()) { Home() })
  }
}
