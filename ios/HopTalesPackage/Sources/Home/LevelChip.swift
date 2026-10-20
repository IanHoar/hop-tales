import Content
import DesignSystem
import SwiftUI

struct LevelChip: View {
  let journey: Journey
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 12) {
        Rosette(level: journey.level)
          .frame(width: 40)
        VStack(alignment: .leading, spacing: 5) {
          Text(title)
            .font(Typography.display(16))
            .foregroundStyle(Paper.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
          if journey.nextFriend != nil {
            GeometryReader { proxy in
              ZStack(alignment: .leading) {
                Capsule().fill(Paper.muted.opacity(0.22))
                Capsule()
                  .fill(Paper.wash)
                  .frame(width: proxy.size.width * journey.fill)
              }
            }
            .frame(height: 8)
          }
        }
        Image(systemName: "map")
          .font(.system(size: 17, weight: .semibold))
          .foregroundStyle(Paper.ink)
      }
      .padding(.horizontal, 14)
      .padding(.vertical, 10)
      .paperChip(RoundedRectangle(cornerRadius: 18, style: .continuous), rim: 3)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(title)
    .accessibilityHint("Opens your journey.")
  }

  private var title: String {
    guard let next = journey.nextFriend else {
      return "Level \(journey.level) · \(journey.activeFriend.name)"
    }
    return "Level \(journey.level) · \(Int(journey.steps)) of \(Int(journey.goal)) to \(next.name)"
  }
}
