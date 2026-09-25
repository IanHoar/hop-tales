import ComposableArchitecture2
import Content
import SwiftUI

#if DEBUG
struct ReadingScreenPreview: View {
  enum Moment {
    case start
    case midPage
    case end
    case bigStoryReady
    case newFriend
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
      state.bigWords = [WordRef(sentence: 0, word: 2), WordRef(sentence: 0, word: 4)]
    case .end, .bigStoryReady, .newFriend:
      state.sentenceIndex = story.sentences.count
      state.stars = 42
      state.completed = .story(stars: 42)
      state.journeyMoments = [
        .tally(steps: 41, total: 412, goal: 500, bigWords: 3, next: .frog)
      ]
      if moment == .bigStoryReady { state.journeyMoments.append(.bigStoryReady(.frog)) }
      if moment == .newFriend { state.journeyMoments.append(.newFriend(.frog, via: .bigStory)) }
    }
    return state
  }
}

#Preview("Start") { ReadingScreenPreview() }
#Preview("Mid page") { ReadingScreenPreview(moment: .midPage) }
#Preview("End") { ReadingScreenPreview(moment: .end) }
#Preview("Big story ready") { ReadingScreenPreview(moment: .bigStoryReady) }
#Preview("New friend") { ReadingScreenPreview(moment: .newFriend) }
#endif
