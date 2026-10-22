import Content

extension Reading.State {
  public struct Recognised: Equatable, Sendable {
    public var count: Int
    public var sentenceIndex: Int
    public var stars: Int
    public var wordIndex: Int
  }

  public enum Completed: Equatable, Sendable {
    case sentence(index: Int)
    case story(stars: Int)
  }
}

extension Reading.State {
  public var tally: JourneyMoment? {
    journeyMoments.first {
      if case .tally = $0 { return true }
      return false
    }
  }

  public var collectedTreat: (treat: CollectedTreat, trail: Int)? {
    for moment in journeyMoments {
      if case let .treat(treat, trail) = moment { return (treat, trail) }
    }
    return nil
  }

  public var callout: JourneyMoment? {
    journeyMoments.first(where: \.isCallout)
  }

  mutating func dismissCallout() {
    guard let index = journeyMoments.firstIndex(where: \.isCallout) else { return }
    journeyMoments.remove(at: index)
  }

  mutating func advance(by count: Int) {
    guard let sentence else { return }
    let read = min(count, sentence.words.count - wordIndex)
    guard read > 0 else { return }

    stars += read
    wordIndex += read

    guard wordIndex >= sentence.words.count else { return }
    if !usedHelp { stars += 5 }
    let finished = sentenceIndex
    sentenceIndex += 1
    wordIndex = 0
    usedHelp = false
    completionCount += 1
    if sentenceIndex >= story.sentences.count {
      stars += 20
      completed = .story(stars: stars)
    } else {
      completed = .sentence(index: finished)
    }
  }
}

extension Reading {
  func finish(_ state: inout State) {
    var progress = progressStore.load()
    let helped = wordsHelped.intersection(wordsRead).count
    let helpRate = wordsRead.isEmpty ? 0 : Double(helped) / Double(wordsRead.count)
    let collected = state.treat.flatMap { treat in
      wordsRead.contains(treat.word)
        ? CollectedTreat(
          friend: treat.friend,
          isTrail: treat.isTrail,
          isGolden: !treat.isTrail && helpRate <= Levels.goldenHelpRate
        )
        : nil
    }
    let result = StoryResult(
      storyID: state.story.id,
      wordsRead: wordsRead.count,
      bigWordsRead: wordsRead.intersection(state.bigWords).count,
      helpedWords: helped,
      treat: collected
    )
    var moments = progress.journey.record(result)
    if let collected { moments += progress.collect(collected) }
    state.journeyMoments = progress.celebrateLevelOne(
      after: state.story, in: moments, isPlus: state.isPlus, locksStories: state.locksStories
    )
    progressStore.save(progress)
  }
}

extension Array {
  subscript(safe index: Int) -> Element? {
    indices.contains(index) ? self[index] : nil
  }
}

extension Reading.State {
  var wordCardLabel: String {
    guard let word = currentWord?.text else { return "Reading" }
    return "Current word: \(word). Say it out loud."
  }
}
