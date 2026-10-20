import SwiftUI

public struct Choice: View {
  let title: String
  var detail: String?
  var footnote: String?
  let isSelected: Bool
  let action: () -> Void

  public init(
    title: String,
    detail: String? = nil,
    footnote: String? = nil,
    isSelected: Bool,
    action: @escaping () -> Void
  ) {
    self.title = title
    self.detail = detail
    self.footnote = footnote
    self.isSelected = isSelected
    self.action = action
  }

  public var body: some View {
    Button(action: action) {
      HStack(alignment: .center, spacing: 16) {
        VStack(alignment: .leading, spacing: 6) {
          Text(title)
            .font(Typography.display(20))
            .foregroundStyle(isSelected ? Palette.outline : Palette.ink)
          if let detail {
            Text(detail)
              .font(Typography.ui(15))
              .foregroundStyle(isSelected ? Palette.pillText : Palette.muted)
              .lineSpacing(2)
          }
          if let footnote {
            Label(footnote, systemImage: "book.closed")
              .font(Typography.ui(13))
              .foregroundStyle(isSelected ? Palette.pillText : Palette.faint)
              .padding(.top, 2)
          }
        }
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
        Spacer(minLength: 0)
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
          .font(.system(size: 26))
          .foregroundStyle(isSelected ? Palette.outline : Palette.faint)
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 18)
      .frame(minHeight: 64)
      .bevel(
        isSelected ? Palette.goldLight : Palette.paper,
        lip: isSelected ? Palette.gold : Palette.parchmentLip,
        shape: RoundedRectangle(cornerRadius: 22, style: .continuous),
        border: 3,
        drop: 4
      )
      .contentShape(.rect(cornerRadius: 22))
    }
    .buttonStyle(.plain)
    .animation(.easeInOut(duration: 0.15), value: isSelected)
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }
}
