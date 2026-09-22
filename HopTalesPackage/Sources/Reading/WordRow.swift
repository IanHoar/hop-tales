import Content
import DesignSystem
import SwiftUI

enum WordDisplayState: Equatable {
  case completed
  case current
  case next
  case upcoming

  init(offsetFromCurrent offset: Int) {
    switch offset {
    case ..<0: self = .completed
    case 0: self = .current
    case 1: self = .next
    default: self = .upcoming
    }
  }

  var foreground: Color {
    switch self {
    case .completed: Palette.pillText
    case .current: Palette.ink
    case .next: Palette.muted
    case .upcoming: Palette.faint
    }
  }
}

struct WordRow: View {
  let words: [Word]
  let currentIndex: Int
  let geometry: ReadingGeometry

  var body: some View {
    WordRowLayout(currentIndex: currentIndex, spacing: geometry.wordGap) {
      ForEach(Array(words.enumerated()), id: \.offset) { index, word in
        WordLabel(
          word: word,
          state: WordDisplayState(offsetFromCurrent: index - currentIndex),
          currentSize: currentSize,
          geometry: geometry
        )
      }
    }
  }

  var currentSize: CGFloat {
    WordRow.currentSize(words: words, currentIndex: currentIndex, geometry: geometry)
  }

  static func currentSize(
    words: [Word],
    currentIndex: Int,
    geometry: ReadingGeometry
  ) -> CGFloat {
    guard let current = words[safe: currentIndex]?.text else { return geometry.currentWordSize }

    let neighbours = [words[safe: currentIndex - 1], words[safe: currentIndex + 1]]
      .compactMap(\.self)
      .enumerated()
      .map { index, word -> CGFloat in
        let isCompleted = index == 0 && currentIndex > 0
        let padding = isCompleted ? WordLabel.pillPadding(geometry).width * 2 : 0
        return Typography.width(of: word.text, size: geometry.sideWordSize) + padding
      }
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
  let geometry: ReadingGeometry

  static func pillPadding(_ geometry: ReadingGeometry) -> CGSize {
    CGSize(width: geometry.scaled(9), height: geometry.scaled(3))
  }

  var body: some View {
    Text(word.text)
      .font(Typography.word(size))
      .tracking(state == .current ? Typography.wordTracking(size) : 0)
      .foregroundStyle(state.foreground)
      .lineLimit(1)
      .fixedSize()
      .padding(.horizontal, state == .completed ? Self.pillPadding(geometry).width : 0)
      .padding(.vertical, state == .completed ? Self.pillPadding(geometry).height : 0)
      .background {
        if state == .completed {
          RoundedRectangle(cornerRadius: geometry.scaled(10), style: .continuous)
            .fill(Palette.pillBg)
        }
      }
  }

  private var size: CGFloat {
    state == .current ? currentSize : geometry.sideWordSize
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
