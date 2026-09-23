import ComposableArchitecture2
import Dependencies
import DesignSystem
import SwiftUI

@Feature public struct ParentGate {
  public init() {}

  public struct State {
    public var question: GateQuestion
    public var entry = ""
    public var missed = 0

    public init(question: GateQuestion) {
      self.question = question
    }
  }

  public enum Action {
    case cancelTapped
    case deleteTapped
    case digitTapped(Int)
    case unlocked
  }

  @Dependency(GateQuestions.self) var questions

  public var body: some Feature {
    Update { state, action in
      switch action {
      case .cancelTapped, .unlocked:
        break

      case .deleteTapped:
        state.entry = String(state.entry.dropLast())

      case let .digitTapped(digit):
        guard state.entry.count < state.question.digits else { break }
        state.entry += String(digit)
        guard state.entry.count == state.question.digits else { break }
        if Int(state.entry) == state.question.answer {
          store.addTask { try store.send(.unlocked) }
        } else {
          state.missed += 1
          state.entry = ""
          state.question = questions.next()
        }
      }
    }
  }
}

public struct ParentGateScreen: View {
  let store: StoreOf<ParentGate>

  public init(store: StoreOf<ParentGate>) {
    self.store = store
  }

  static let keys: [[Int?]] = [[1, 2, 3], [4, 5, 6], [7, 8, 9], [nil, 0, -1]]

  public var body: some View {
    VStack(spacing: 22) {
      HStack {
        Spacer()
        Button("Cancel") { store.send(.cancelTapped) }
          .font(Typography.ui(17))
          .foregroundStyle(Palette.ink)
      }
      VStack(spacing: 10) {
        Text("Grown-ups only")
          .font(Typography.display(32))
          .foregroundStyle(Palette.ink)
          .accessibilityAddTraits(.isHeader)
        Text(store.question.prompt)
          .font(Typography.ui(20))
          .foregroundStyle(Palette.ink)
          .multilineTextAlignment(.center)
          .fixedSize(horizontal: false, vertical: true)
        Text(store.missed > 0 ? "Not quite. Here's another one." : "Answer to open settings.")
          .font(Typography.ui(15))
          .foregroundStyle(Palette.muted)
      }
      entry
      keypad
      Spacer(minLength: 0)
    }
    .padding(.horizontal, 24)
    .padding(.top, 16)
    .frame(maxWidth: 420)
    .frame(maxWidth: .infinity)
    .background(Palette.page.ignoresSafeArea())
  }

  private var entry: some View {
    HStack(spacing: 12) {
      ForEach(0..<store.question.digits, id: \.self) { index in
        let characters = Array(store.entry)
        Text(index < characters.count ? String(characters[index]) : " ")
          .font(Typography.display(34))
          .foregroundStyle(Palette.ink)
          .frame(width: 58, height: 68)
          .bevel(
            Palette.paper,
            lip: Palette.parchmentLip,
            shape: RoundedRectangle(cornerRadius: 18, style: .continuous),
            border: 3,
            drop: 4
          )
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(store.entry.isEmpty ? "No answer yet" : "Answer: \(store.entry)")
  }

  private var keypad: some View {
    VStack(spacing: 12) {
      ForEach(Self.keys.indices, id: \.self) { row in
        HStack(spacing: 12) {
          ForEach(Self.keys[row].indices, id: \.self) { column in
            key(Self.keys[row][column])
          }
        }
      }
    }
  }

  @ViewBuilder
  private func key(_ value: Int?) -> some View {
    switch value {
    case nil:
      Color.clear.frame(width: 76, height: 64)
    case -1:
      Button { store.send(.deleteTapped) } label: {
        Image(systemName: "delete.left.fill")
          .font(.system(size: 22, weight: .bold))
      }
      .buttonStyle(KeyStyle())
      .accessibilityLabel("Delete")
    case let digit?:
      Button { store.send(.digitTapped(digit)) } label: {
        Text(String(digit))
          .font(Typography.display(28))
      }
      .buttonStyle(KeyStyle())
    }
  }
}

struct KeyStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .foregroundStyle(Palette.ink)
      .frame(width: 76, height: 64)
      .bevel(
        Palette.parchment,
        lip: Palette.parchmentLip,
        shape: RoundedRectangle(cornerRadius: 20, style: .continuous),
        drop: 5,
        pressed: configuration.isPressed
      )
      .contentShape(.rect(cornerRadius: 20))
      .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
  }
}
