import ComposableArchitecture2
import Content
import SwiftUI

#if DEBUG
struct ReadingScreenPreview: View {
  enum Moment: Equatable {
    case at(sentence: Int, word: Int)
    case start
    case midPage
    case nearTheEnd
    case end
    case bigStoryReady
    case newFriend
    case basketFull
    case triedItOn
  }

  var story = StoryLibrary.all[0]
  var moment = Moment.start
  var friend: Friend?
  var soundButtons = false

  var body: some View {
    NavigationStack {
      ReadingScreen(store: Store(initialState: state) {
        Reading().dependency(ProfileStore(
          load: { Profile(soundButtons: soundButtons) }, save: { _ in }
        ))
      })
    }
  }

  private var state: Reading.State {
    var state = Reading.State(story: story, friend: friend ?? story.friend)
    state.soundButtons = soundButtons
    switch moment {
    case let .at(sentence, word):
      state.sentenceIndex = sentence
      state.wordIndex = word
    case .start:
      break
    case .midPage:
      state.wordIndex = 3
      state.stars = 3
      state.bigWords = [WordRef(sentence: 0, word: 2), WordRef(sentence: 0, word: 4)]
    case .nearTheEnd:
      state.sentenceIndex = story.sentences.count - 1
      state.treat = StoryTreat(
        word: WordRef(sentence: story.sentences.count - 1, word: 1), friend: .hare, isTrail: false
      )
    case .end, .bigStoryReady, .newFriend, .basketFull, .triedItOn:
      state.sentenceIndex = story.sentences.count
      state.stars = 42
      state.completed = .story(stars: 42)
      state.journeyMoments = [
        .tally(steps: 41, total: 412, goal: 500, bigWords: 3, next: .frog),
        .treat(CollectedTreat(friend: .hare, isTrail: false, isGolden: true), trail: 0)
      ]
      if moment == .bigStoryReady { state.journeyMoments.append(.bigStoryReady(.frog)) }
      if moment == .newFriend { state.journeyMoments.append(.newFriend(.frog, via: .bigStory)) }
      if moment == .basketFull || moment == .triedItOn {
        state.journeyMoments.append(.basketFull(.hare, number: 1))
      }
      state.hasTriedItOn = moment == .triedItOn
    }
    return state
  }
}

#Preview("Start") { ReadingScreenPreview() }
#Preview("Bob") { ReadingScreenPreview(moment: .midPage, friend: .bunny) }
#Preview("Mid page") { ReadingScreenPreview(moment: .midPage) }
#Preview("End") { ReadingScreenPreview(moment: .end) }
#Preview("Big story ready") { ReadingScreenPreview(moment: .bigStoryReady) }
#Preview("New friend") { ReadingScreenPreview(moment: .newFriend) }
#endif
