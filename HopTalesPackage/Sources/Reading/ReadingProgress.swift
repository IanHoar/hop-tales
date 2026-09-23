import Content

extension Reading.State {
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
