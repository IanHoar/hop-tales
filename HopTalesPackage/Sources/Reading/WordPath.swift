import Content
import DesignSystem
import SwiftUI
import World

struct WordPath: Equatable {
  static let wordSize: CGFloat = 46
  static let sideScale: CGFloat = 0.7
  static let gap: CGFloat = 64
  static let sentenceGap: CGFloat = 140
  static let focusX: CGFloat = 236
  static let hareX: CGFloat = 96
  static let hareFeetBelowPath: CGFloat = 30
  static let sittingHeight: CGFloat = 124
  static let hoppingHeight: CGFloat = 116
  static let wordApex: CGFloat = 30
  static let sentenceApex: CGFloat = 60
  static let startSign: CGFloat = 80
  static let endSign: CGFloat = 270
  static let overshoot: CGFloat = 200
  static let signHeight: CGFloat = 172
  static let signFeetAbovePath: CGFloat = 40
  static let rise: CGFloat = 0.58
  static let pan: TimeInterval = 0.62
  static let bigWordLift: CGFloat = 1.4
  static let bigWordScale: CGFloat = 1.08
  static let treatBeforeWord: CGFloat = 128
  static let pickupDelay: TimeInterval = 6 / HareMotion.fps
  static let basketHold: TimeInterval = 1.2

  struct Stop: Equatable {
    var target: HopTarget
    var text: String
    var centre: CGFloat
    var width: CGFloat
  }

  let geometry: ReadingGeometry
  let stops: [Stop]
  let style: WorldStyle

  init(sentences: [[Word]], geometry: ReadingGeometry, style: WorldStyle = .meadow) {
    self.geometry = geometry
    self.style = style
    let size = geometry.path(Self.wordSize)
    var stops: [Stop] = []
    for (sentence, words) in sentences.enumerated() {
      for (index, word) in words.enumerated() {
        let width = Typography.width(of: word.text, size: size)
        var centre = geometry.path(Self.focusX)
        if let previous = stops.last {
          let gap = index == 0 ? Self.sentenceGap : Self.gap
          centre = previous.centre + previous.width / 2 + geometry.path(gap) + width / 2
        }
        stops.append(
          Stop(
            target: HopTarget(sentence: sentence, word: index),
            text: word.text,
            centre: centre,
            width: width
          )
        )
      }
    }
    self.stops = stops
  }

  var wordSize: CGFloat { geometry.path(Self.wordSize) }
  var wordHeight: CGFloat { Typography.wordUIFont(wordSize).lineHeight }
  var wordY: CGFloat { geometry.pathCentre + (0.5 - Self.rise) * wordHeight }
  var hareX: CGFloat { geometry.path(Self.hareX) }
  var hareFeetY: CGFloat {
    geometry.pathCentre + geometry.path(style.feetAbovePath.map { -$0 } ?? Self.hareFeetBelowPath)
  }
  var signFeetY: CGFloat { geometry.pathCentre - geometry.path(Self.signFeetAbovePath) }
  var signHeight: CGFloat { geometry.path(Self.signHeight) }

  var startSign: CGFloat { (stops.first?.centre ?? 0) + geometry.path(Self.startSign) }
  var endSign: CGFloat { (stops.last?.centre ?? 0) + geometry.path(Self.endSign) }

  func stop(at target: HopTarget) -> Stop? {
    stops.first { $0.target == target }
  }

  func camera(at target: HopTarget) -> CGFloat {
    if let stop = stop(at: target) {
      return stop.centre - geometry.path(Self.focusX)
    }
    guard let last = stops.last, target.sentence > last.target.sentence else {
      return (stops.first?.centre ?? 0) - geometry.path(Self.focusX)
    }
    return last.centre + geometry.path(Self.overshoot) - geometry.path(Self.focusX)
  }

  func apex(carried: Bool) -> CGFloat {
    geometry.path(carried ? Self.sentenceApex : Self.wordApex)
  }

  func hareHeight(hopping: Bool) -> CGFloat {
    geometry.path(hopping ? Self.hoppingHeight : Self.sittingHeight)
  }

  static func state(of target: HopTarget, at position: HopTarget) -> PathWordState {
    if (target.sentence, target.word) < (position.sentence, position.word) { return .read }
    return target == position ? .current : .upcoming
  }
}

enum PathWordState: Equatable {
  case read
  case current
  case upcoming

  var ink: Color {
    switch self {
    case .read: Color(hex: 0x3B2A20)
    case .current: Color(hex: 0x2E2018)
    case .upcoming: Color(hex: 0x3B2A20, opacity: 0.42)
    }
  }

  var chalk: Color {
    switch self {
    case .read: Color(hex: 0xF4EFE4, opacity: 0.85)
    case .current: Color(hex: 0xFFFDF7)
    case .upcoming: Color(hex: 0xF4EFE4, opacity: 0.45)
    }
  }
}
