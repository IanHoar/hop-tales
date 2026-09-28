extension Reading {
  public static let noisyAbove: Double = -42
  public static let quietBelow: Double = -50
  public static let noisyAfterTicks = 8

  func hear(_ level: Double, in state: inout State) {
    noiseLevel = level
    guard !state.isSpeaking else { return }
    ticksSinceMatch += 1
    if level < Reading.quietBelow {
      state.isNoisy = false
    } else if level >= Reading.noisyAbove, heardSinceMatch,
      ticksSinceMatch >= Reading.noisyAfterTicks {
      state.isNoisy = true
    }
  }

  func missed(_ tokens: [String]) {
    if !tokens.isEmpty { heardSinceMatch = true }
  }

  func matched(_ state: inout State) {
    ticksSinceMatch = 0
    heardSinceMatch = false
    state.isNoisy = false
  }
}
