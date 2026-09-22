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
    case .completed: Palette.pillText
    case .current: Palette.ink
    case .next: Palette.muted
    case .recognised: Palette.flashText
    case .upcoming: Palette.faint
    }
  }

  var isPill: Bool { self == .completed || self == .recognised }
}

struct WordRow: View {
  let words: [Word]
  let currentIndex: Int
  var recognisedIndex: Int?
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
          geometry: geometry
        )
      }
    }
    .animation(Motion.recognised, value: currentIndex)
    .animation(Motion.recognised, value: recognisedIndex)
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
      .padding(.horizontal, horizontalPadding)
      .padding(.vertical, verticalPadding)
      .background { pill }
  }

  @ViewBuilder
  private var pill: some View {
    switch state {
    case .completed:
      RoundedRectangle(cornerRadius: geometry.scaled(10), style: .continuous)
        .fill(Palette.pillBg)
    case .recognised:
      RoundedRectangle(cornerRadius: geometry.scaled(14), style: .continuous)
        .fill(Palette.amber)
        .overlay {
          RoundedRectangle(cornerRadius: geometry.scaled(14), style: .continuous)
            .strokeBorder(Palette.amber.opacity(0.28), lineWidth: geometry.scaled(5))
            .padding(-geometry.scaled(5))
        }
    default:
      EmptyView()
    }
  }

  private var horizontalPadding: CGFloat {
    switch state {
    case .completed: Self.pillPadding(geometry).width
    case .recognised: geometry.scaled(12)
    default: 0
    }
  }

  private var verticalPadding: CGFloat {
    switch state {
    case .completed: Self.pillPadding(geometry).height
    case .recognised: geometry.scaled(4)
    default: 0
    }
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
