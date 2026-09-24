import CoreGraphics

struct MeadowStar: Equatable {
  let asset: String
  let centre: CGPoint
  let width: CGFloat
}

enum MeadowStars {
  static let aspect: CGFloat = 239 / 244

  static func field(for layout: MeadowLayout) -> [MeadowStar] {
    let size = layout.size
    guard size.width > 0, size.height > 0 else { return [] }
    var random = SeededRandom(seed: 42)
    let columns = max(5, Int(size.width / (80 * layout.k)))
    let rows = 3
    let band = (top: size.height * 0.04, bottom: size.height * 0.4)
    let cell = CGSize(
      width: size.width / CGFloat(columns),
      height: (band.bottom - band.top) / CGFloat(rows)
    )
    let moon = layout.moonCentre
    let moonReach = max(layout.moonSize.width, layout.moonSize.height) * 0.6
    var stars: [MeadowStar] = []
    for row in 0..<rows {
      for column in 0..<columns {
        let width = 244 * CGFloat.random(in: 0.07...0.12, using: &random) * layout.k
        let jitter = CGPoint(
          x: CGFloat.random(in: 0...1, using: &random),
          y: CGFloat.random(in: 0...1, using: &random)
        )
        let skip = CGFloat.random(in: 0...1, using: &random) < 0.2
        let inset = width / 2 + 4 * layout.k
        let centre = CGPoint(
          x: CGFloat(column) * cell.width + inset + jitter.x * max(0, cell.width - 2 * inset),
          y: band.top + CGFloat(row) * cell.height + inset
            + jitter.y * max(0, cell.height - 2 * inset)
        )
        let clearOfMoon = hypot(centre.x - moon.x, centre.y - moon.y) > moonReach + width / 2
        guard !skip, clearOfMoon else { continue }
        let asset = "sky-star-\(stars.count % 3 + 1)"
        stars.append(MeadowStar(asset: asset, centre: centre, width: width))
      }
    }
    return stars
  }
}
