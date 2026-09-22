import ComposableArchitecture2
import Content
import SwiftUI

#if DEBUG
struct ReadingScreenPreview: View {
  var story = StoryLibrary.all[0]

  var body: some View {
    NavigationStack {
      ReadingScreen(store: Store(initialState: Reading.State(story: story)) { Reading() })
    }
  }
}

#Preview { ReadingScreenPreview() }
#endif
