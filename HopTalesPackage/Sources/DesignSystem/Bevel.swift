import SwiftUI

public struct Bevel<S: InsettableShape>: ViewModifier {
  let fill: Color
  let lip: Color
  let shape: S
  let border: CGFloat
  let drop: CGFloat
  var lipHeight: CGFloat?
  var highlightInset: CGFloat = 16
  var pressed = false

  public init(
    fill: Color,
    lip: Color,
    shape: S,
    border: CGFloat = 3,
    drop: CGFloat = 4,
    lipHeight: CGFloat? = nil,
    highlightInset: CGFloat = 16,
    pressed: Bool = false
  ) {
    self.fill = fill
    self.lip = lip
    self.shape = shape
    self.border = border
    self.drop = drop
    self.lipHeight = lipHeight
    self.highlightInset = highlightInset
    self.pressed = pressed
  }

  private var currentDrop: CGFloat { pressed ? 1 : drop }

  public func body(content: Content) -> some View {
    content
      .background {
        shape.fill(fill)
          .overlay(alignment: .bottom) {
            Rectangle()
              .fill(lip)
              .frame(height: lipHeight ?? drop + 2)
          }
          .overlay(alignment: .top) {
            Capsule()
              .fill(Palette.highlight)
              .frame(height: 3)
              .padding(.horizontal, highlightInset)
              .padding(.top, border + 2)
          }
          .clipShape(shape)
      }
      .overlay { shape.strokeBorder(Palette.outline, lineWidth: border) }
      .background { shape.fill(Palette.outline).offset(y: currentDrop) }
      .offset(y: pressed ? drop - 1 : 0)
  }
}

extension View {
  public func bevel<S: InsettableShape>(
    _ fill: Color,
    lip: Color,
    shape: S,
    border: CGFloat = 3,
    drop: CGFloat = 4,
    lipHeight: CGFloat? = nil,
    pressed: Bool = false
  ) -> some View {
    modifier(
      Bevel(
        fill: fill,
        lip: lip,
        shape: shape,
        border: border,
        drop: drop,
        lipHeight: lipHeight,
        pressed: pressed
      )
    )
  }

  public func parchmentBevel<S: InsettableShape>(
    _ shape: S,
    border: CGFloat = 3,
    drop: CGFloat = 4,
    pressed: Bool = false
  ) -> some View {
    bevel(
      Palette.parchment,
      lip: Palette.parchmentLip,
      shape: shape,
      border: border,
      drop: drop,
      pressed: pressed
    )
  }
}

public struct InkButtonStyle: ButtonStyle {
  public enum Kind {
    case primary
    case secondary
    case tertiary
  }

  let kind: Kind
  var height: CGFloat = 58

  public init(_ kind: Kind, height: CGFloat = 58) {
    self.kind = kind
    self.height = height
  }

  public func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(Typography.display(19))
      .tracking(19 * 0.03)
      .foregroundStyle(label)
      .padding(.horizontal, 22)
      .frame(minHeight: height)
      .bevel(
        fill,
        lip: lip,
        shape: Capsule(style: .circular),
        drop: 5,
        pressed: configuration.isPressed
      )
      .animation(
        configuration.isPressed
          ? .easeOut(duration: 0.08)
          : .spring(response: 0.25, dampingFraction: 0.6),
        value: configuration.isPressed
      )
  }

  private var fill: Color {
    switch kind {
    case .primary: Palette.gold
    case .secondary: Palette.teal
    case .tertiary: Palette.parchment
    }
  }

  private var lip: Color {
    switch kind {
    case .primary: Palette.goldShade
    case .secondary: Palette.tealShade
    case .tertiary: Palette.parchmentLip
    }
  }

  private var label: Color {
    switch kind {
    case .primary: Palette.onAccent
    case .secondary: Palette.onTeal
    case .tertiary: Palette.ink
    }
  }
}

extension ButtonStyle where Self == InkButtonStyle {
  public static func ink(_ kind: InkButtonStyle.Kind, height: CGFloat = 58) -> InkButtonStyle {
    InkButtonStyle(kind, height: height)
  }
}

public struct Coin: View {
  let size: CGFloat

  public init(size: CGFloat) {
    self.size = size
  }

  public var body: some View {
    ZStack {
      Circle().fill(Palette.goldShade)
      Circle().fill(Palette.gold).padding(.bottom, size * 0.1)
      Star()
        .fill(Palette.goldLight)
        .overlay(Star().stroke(Palette.goldShade, lineWidth: size * 0.04))
        .padding(size * 0.26)
    }
    .overlay(Circle().strokeBorder(Palette.outline, lineWidth: max(2, size * 0.08)))
    .frame(width: size, height: size)
    .accessibilityHidden(true)
  }
}

#Preview("Ink kit") {
  VStack(spacing: 24) {
    Button("Start reading") {}.buttonStyle(.ink(.primary))
    Button("Play on the TV") {}.buttonStyle(.ink(.secondary))
    Button("Not now") {}.buttonStyle(.ink(.tertiary))
    HStack(spacing: 10) {
      Coin(size: 38)
      Text("12").font(Typography.display(22)).foregroundStyle(Palette.ink)
    }
    .padding(.leading, 7)
    .padding(.trailing, 16)
    .frame(height: 52)
    .parchmentBevel(Capsule())
  }
  .padding(40)
  .frame(maxWidth: .infinity, maxHeight: .infinity)
  .background(Palette.page)
}
