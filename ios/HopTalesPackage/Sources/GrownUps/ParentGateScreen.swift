import ComposableArchitecture2
import DesignSystem
import SwiftUI

@Feature public struct ParentGate {
  public init() {}

  public struct State: Identifiable {
    public var id = "parent-gate"
    public var seed: UInt64
    public var round = 0
    public var entry = ""

    public init(seed: UInt64) {
      self.seed = seed
    }

    public var question: GateQuestion {
      GateQuestion.drawn(seed: seed, round: round)
    }

    var canAnswer: Bool { !entry.isEmpty }
  }

  public enum Action {
    case answerTapped
    case closeTapped
    case deleteTapped
    case digitTapped(Int)
    case passed
  }

  public var body: some Feature {
    Update { state, action in
      switch action {
      case .answerTapped:
        guard state.canAnswer else { break }
        if state.question.accepts(state.entry) {
          store.addTask { try store.send(.passed) }
        } else {
          state.round += 1
          state.entry = ""
        }

      case .deleteTapped:
        if !state.entry.isEmpty { state.entry.removeLast() }

      case let .digitTapped(digit):
        guard (0...9).contains(digit), state.entry.count < GateQuestion.answerDigits else { break }
        state.entry.append(String(digit))

      case .closeTapped, .passed:
        break
      }
    }
  }
}

public struct ParentGateScreen: View {
  let store: StoreOf<ParentGate>

  public init(store: StoreOf<ParentGate>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      header
      ScrollView {
        VStack(spacing: 18) {
          Text("Ask a grown-up to answer this.")
            .font(Typography.ui(16, weight: .medium))
            .foregroundStyle(Paper.muted)
            .multilineTextAlignment(.center)
          Text(store.question.words)
            .font(Typography.ui(26, weight: .bold, relativeTo: .title))
            .foregroundStyle(Paper.ink)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
          answer
          Text("Here's a new one.")
            .font(Typography.ui(15, weight: .medium))
            .foregroundStyle(Paper.muted)
            .opacity(store.round > 0 ? 1 : 0)
            .accessibilityHidden(store.round == 0)
          keypad
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 24)
        .frame(maxWidth: 420)
        .frame(maxWidth: .infinity)
      }
    }
    .background(Paper.page.ignoresSafeArea())
    .onChange(of: store.round) {
      AccessibilityNotification.Announcement("Here's a new one. \(store.question.words)").post()
    }
  }

  private var header: some View {
    HStack(spacing: 12) {
      PaperLabel(seed: 11) {
        Text("For grown-ups")
          .font(Typography.display(22))
          .foregroundStyle(Paper.ink)
          .padding(.horizontal, 16)
          .padding(.vertical, 8)
      }
      .rotationEffect(.degrees(-2))
      .accessibilityAddTraits(.isHeader)
      Spacer()
      Button("Close") { store.send(.closeTapped) }
        .font(Typography.display(17))
        .foregroundStyle(Paper.ink)
        .padding(.horizontal, 16)
        .frame(height: 40)
        .paperChip(Capsule(), rim: 3)
        .buttonStyle(.plain)
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 12)
  }

  private var answer: some View {
    Text(store.entry.isEmpty ? "?" : store.entry)
      .font(Typography.ui(36, weight: .bold, relativeTo: .largeTitle))
      .foregroundStyle(store.entry.isEmpty ? Paper.muted.opacity(0.5) : Paper.ink)
      .monospacedDigit()
      .frame(minWidth: 120, minHeight: 68)
      .paperChoice(isSelected: false)
      .frame(width: 150)
      .accessibilityElement(children: .ignore)
      .accessibilityLabel("Your answer")
      .accessibilityValue(store.entry.isEmpty ? "Empty" : store.entry)
  }

  private var keypad: some View {
    Grid(horizontalSpacing: 12, verticalSpacing: 12) {
      ForEach([[1, 2, 3], [4, 5, 6], [7, 8, 9]], id: \.self) { row in
        GridRow {
          ForEach(row, id: \.self) { digit in
            key(Text("\(digit)"), label: "\(digit)") { store.send(.digitTapped(digit)) }
          }
        }
      }
      GridRow {
        key(Image(systemName: "delete.left"), label: "Delete") { store.send(.deleteTapped) }
        key(Text("0"), label: "0") { store.send(.digitTapped(0)) }
        Button { store.send(.answerTapped) } label: {
          Image(systemName: "checkmark")
            .font(.system(size: 24, weight: .bold))
            .foregroundStyle(Paper.onRed)
            .frame(maxWidth: .infinity, minHeight: 60)
            .paperChip(
              RoundedRectangle(cornerRadius: 18, style: .continuous), fill: Paper.red, rim: 3
            )
        }
        .buttonStyle(.plain)
        .opacity(store.canAnswer ? 1 : 0.5)
        .disabled(!store.canAnswer)
        .accessibilityLabel("Check answer")
      }
    }
  }

  private func key(
    _ face: some View,
    label: String,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      face
        .font(Typography.ui(28, weight: .semibold, relativeTo: .title))
        .foregroundStyle(Paper.ink)
        .frame(maxWidth: .infinity, minHeight: 60)
        .paperChip(RoundedRectangle(cornerRadius: 18, style: .continuous), rim: 3)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(label)
  }
}

#if DEBUG
struct ParentGatePreview: View {
  var entry = ""
  var round = 0

  var body: some View {
    ParentGateScreen(store: Store(initialState: state) { ParentGate() })
      .frame(width: Metrics.phone.reference.width, height: Metrics.phone.reference.height)
  }

  private var state: ParentGate.State {
    var state = ParentGate.State(seed: 1)
    state.entry = entry
    state.round = round
    return state
  }
}

#Preview("Gate") { ParentGatePreview() }
#Preview("Gate, a new question") { ParentGatePreview(entry: "4", round: 1) }
#endif
