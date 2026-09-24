import ComposableArchitecture2
import Content
import SwiftUI

#if DEBUG
struct ReadingScreenPreview: View {
  enum Moment {
    case start
    case midPage
    case end
  }

  var story = StoryLibrary.all[0]
  var moment = Moment.start

  var body: some View {
    NavigationStack {
      ReadingScreen(store: Store(initialState: state) { Reading() })
    }
  }

  private var state: Reading.State {
    var state = Reading.State(story: story)
    switch moment {
    case .start:
      break
    case .midPage:
      state.wordIndex = 3
      state.stars = 3
    case .end:
      state.sentenceIndex = story.sentences.count
      state.stars = 42
      state.completed = .story(stars: 42)
    }
    return state
  }
}

#Preview("Start") { ReadingScreenPreview() }
#Preview("Mid page") { ReadingScreenPreview(moment: .midPage) }
#Preview("End") { ReadingScreenPreview(moment: .end) }
#endif
