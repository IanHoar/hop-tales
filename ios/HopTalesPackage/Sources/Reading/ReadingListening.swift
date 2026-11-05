import ComposableArchitecture
import Content
import Dependencies
import DesignSystem
import SpeechRecognition
import SwiftUI
import World

public struct IdleTimer: Sendable {
  public var keepAwake: @Sendable (Bool) -> Void

  public init(keepAwake: @escaping @Sendable (Bool) -> Void) {
    self.keepAwake = keepAwake
  }
}

extension IdleTimer: DependencyKey {
  public static let liveValue = IdleTimer { awake in
    MainActor.assumeIsolated { UIApplication.shared.isIdleTimerDisabled = awake }
  }
  public static let testValue = IdleTimer { _ in }
}

public struct TryingItOn: FeatureEventKey {
  public let friend: Friend

  public init(friend: Friend) {
    self.friend = friend
  }
}

extension Reading {
  public static let settleAfterSpeaking = Duration.milliseconds(300)
  public static let offerHelpAfter = Duration.seconds(6)
  public static let relistenAfterEnd = Duration.milliseconds(150)
  public static let relistenAfterFailure = Duration.seconds(1)

  static func hasBeenQuiet(since heardAt: Date, now: Date) -> Bool {
    now.timeIntervalSince(heardAt) >= offerHelpAfter / .seconds(1)
  }
}

extension Reading {
  func persist(_ state: State) {
    var progress = progressStore.load()
    progress.stars += state.stars - savedStars
    progress.completedSentences[state.story.id] = max(
      progress.completedSentences[state.story.id] ?? 0,
      state.sentenceIndex
    )
    progress.wordsRead[state.story.id] = max(
      progress.wordsRead[state.story.id] ?? 0,
      state.wordsCompleted
    )
    progressStore.save(progress)
    savedStars = state.stars
  }

  func log(
    _ tokens: [String], isFinal: Bool, outcome: SpeechLogEntry.Outcome, in state: State
  ) {
    speechLog.record(
      SpeechLogEntry(
        story: state.story.id,
        sentence: state.sentenceIndex,
        word: state.currentWord?.text ?? "",
        heard: tokens,
        isFinal: isFinal,
        outcome: outcome,
        level: noiseLevel
      )
    )
  }
}

extension Reading.State {
  public var currentWord: Word? {
    sentence?.words[safe: wordIndex]
  }

  public var nextWord: Word? {
    sentence?.words[safe: wordIndex + 1]
  }

  public var sentence: Sentence? {
    story.sentences[safe: sentenceIndex]
  }

  public var worldProgress: Double {
    Double(wordsCompleted) * Story.stepPerWord
  }

  public var wordsCompleted: Int {
    story.sentences.prefix(sentenceIndex).reduce(0) { $0 + $1.words.count } + wordIndex
  }
}
