import Content
import DesignSystem
import SwiftUI

enum WordDisplayState: Equatable {
  case completed
  case current
  case next
  case recognised
  case upcoming

  init(offsetFromCurrent offset: Int, isRecognised: Bool = false) {
    if isRecognised {
      self = .recognised
      return
    }
    switch offset {
    case ..<0: self = .completed
    case 0: self = .current
    case 1: self = .next
    default: self = .upcoming
    }
  }

  var foreground: Color {
    switch self {
    case .completed, .current, .recognised: Paper.ink
    case .next, .upcoming: Paper.muted
    }
  }

  var isWashed: Bool { self == .completed || self == .recognised }
}

struct WordRow: View {
  let words: [Word]
  let currentIndex: Int
  var recognisedIndex: Int?
  var isSpeaking = false
  let geometry: ReadingGeometry

  var body: some View {
    WordRowLayout(currentIndex: currentIndex, spacing: geometry.wordGap) {
      ForEach(Array(words.enumerated()), id: \.offset) { index, word in
        WordLabel(
          word: word,
          state: WordDisplayState(
            offsetFromCurrent: index - currentIndex,
            isRecognised: index == recognisedIndex
          ),
          currentSize: currentSize,
          isPulsing: isSpeaking && index == currentIndex,
          geometry: geometry
        )
      }
    }
    .animation(Motion.recognised, value: recognisedIndex)
  }

  var currentSize: CGFloat {
    WordRow.currentSize(words: words, currentIndex: currentIndex, geometry: geometry)
  }

  static func hopDistance(
    words: [Word],
    from start: Int,
    to target: Int,
    geometry: ReadingGeometry
  ) -> CGFloat {
    guard let from = words[safe: start], target > start, words.indices.contains(target) else {
      return 0
    }
    let launch =
      Typography.width(of: from.text, size: geometry.recognisedWordSize)
      + geometry.scaled(12) * 2
    let between = words[(start + 1)..<target].reduce(0) {
      $0 + Typography.width(of: $1.text, size: geometry.sideWordSize) + geometry.wordGap
    }
    let landing = Typography.width(of: words[target].text, size: geometry.sideWordSize)
    return launch / 2 + geometry.wordGap + between + landing / 2
  }

  static func currentSize(
    words: [Word],
    currentIndex: Int,
    geometry: ReadingGeometry
  ) -> CGFloat {
    guard let current = words[safe: currentIndex]?.text else { return geometry.currentWordSize }

    let neighbours = [words[safe: currentIndex - 1], words[safe: currentIndex + 1]]
      .compactMap(\.self)
      .map { Typography.width(of: $0.text, size: geometry.sideWordSize) }
    let budget =
      geometry.cardSize.width
      - neighbours.reduce(0, +)
      - CGFloat(neighbours.count) * geometry.wordGap

    let maximum = geometry.currentWordSize
    let minimum = maximum / 2
    var size = maximum
    while size > minimum {
      let width = Typography.width(of: current, size: size, tracking: Typography.wordTracking(size))
      guard width > budget else { break }
      size -= 1
    }
    return size
  }
}

struct WordLabel: View {
  let word: Word
  let state: WordDisplayState
  let currentSize: CGFloat
  var isPulsing = false
  let geometry: ReadingGeometry

  var body: some View {
    Text(word.text)
      .font(Typography.word(size))
      .tracking(state == .current ? Typography.wordTracking(size) : 0)
      .foregroundStyle(state.foreground)
      .lineLimit(1)
      .fixedSize()
      .padding(.horizontal, horizontalPadding)
      .background { wash }
      .scaleEffect(isPulsing ? 1.08 : 1)
      .animation(.easeInOut(duration: 0.28).repeatCount(3, autoreverses: true), value: isPulsing)
  }

  @ViewBuilder
  private var wash: some View {
    if state.isWashed {
      WashHighlight()
        .padding(.horizontal, -size * 0.24)
        .padding(.top, size * 0.14)
        .padding(.bottom, -size * 0.04)
        .transition(.opacity)
    }
  }

  private var horizontalPadding: CGFloat {
    state == .recognised ? geometry.scaled(12) : 0
  }

  private var size: CGFloat {
    switch state {
    case .current: currentSize
    case .recognised: geometry.recognisedWordSize
    default: geometry.sideWordSize
    }
  }
}

struct WordRowLayout: Layout {
  var currentIndex: Int
  var spacing: CGFloat

  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
    let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
    let width = sizes.reduce(0) { $0 + $1.width } + CGFloat(max(0, sizes.count - 1)) * spacing
    return CGSize(
      width: proposal.width ?? width,
      height: sizes.map(\.height).max() ?? 0
    )
  }

  func placeSubviews(
    in bounds: CGRect,
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout Void
  ) {
    let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
    guard !sizes.isEmpty else { return }

    let index = min(max(currentIndex, 0), sizes.count - 1)
    let widthBeforeCurrent = sizes[..<index].reduce(0) { $0 + $1.width + spacing }
    var x = bounds.midX - sizes[index].width / 2 - widthBeforeCurrent

    for (subview, size) in zip(subviews, sizes) {
      subview.place(
        at: CGPoint(x: x, y: bounds.midY),
        anchor: .leading,
        proposal: ProposedViewSize(size)
      )
      x += size.width + spacing
    }
  }
}
