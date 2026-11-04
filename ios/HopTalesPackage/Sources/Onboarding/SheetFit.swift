import SwiftUI

struct SheetFit: Layout {
  let fill: CGFloat

  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    guard subviews.count == 2 else { return .zero }
    let width = proposal.width ?? subviews[1].sizeThatFits(.unspecified).width
    let natural = subviews[1].sizeThatFits(ProposedViewSize(width: width, height: nil)).height
    let wanted = max(fill, natural)
    return CGSize(width: width, height: min(proposal.height ?? wanted, wanted))
  }

  func placeSubviews(
    in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()
  ) {
    let size = ProposedViewSize(width: bounds.width, height: bounds.height)
    for subview in subviews {
      subview.place(at: bounds.origin, proposal: size)
    }
  }
}
