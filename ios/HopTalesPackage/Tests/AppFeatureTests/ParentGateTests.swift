import ComposableArchitecture
import Testing

@testable import GrownUps

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct ParentGateTests {
  @Test func theQuestionIsATimesTableInWords() {
    let question = GateQuestion(left: 7, right: 8)
    #expect(question.words == "What is seven times eight?")
    #expect(question.answer == 56)
    #expect(question.accepts("56"))
    #expect(!question.accepts("65"))
    #expect(!question.accepts(""))
  }

  @Test func everyDrawStaysInTheTimesTables() {
    for seed in UInt64(0)..<200 {
      for round in 0..<4 {
        let question = GateQuestion.drawn(seed: seed, round: round)
        #expect(GateQuestion.factors.contains(question.left))
        #expect(GateQuestion.factors.contains(question.right))
        #expect(String(question.answer).count <= GateQuestion.answerDigits)
      }
    }
  }

  @Test func aRedrawIsNeverTheSameQuestion() {
    for seed in UInt64(0)..<200 {
      for round in 1..<6 {
        #expect(
          GateQuestion.drawn(seed: seed, round: round)
            != GateQuestion.drawn(seed: seed, round: round - 1)
        )
      }
    }
  }

  @Test func theSameSeedDrawsTheSameQuestionsAsAndroid() {
    let drawn = (0..<4).map { GateQuestion.drawn(seed: 1, round: $0) }
    #expect(drawn == [
      GateQuestion(left: 5, right: 3),
      GateQuestion(left: 4, right: 3),
      GateQuestion(left: 8, right: 5),
      GateQuestion(left: 3, right: 6)
    ])
    #expect(GateQuestion.drawn(seed: 42, round: 0) == GateQuestion(left: 8, right: 8))
  }

  @Test func theRightAnswerContinues() async {
    let store = TestStore(initialState: ParentGate.State(seed: 1)) {
      ParentGate()
    }
    #expect(store.state.question.words == "What is five times three?")
    store.send(.digitTapped(1)) { $0.entry = "1" }
    store.send(.digitTapped(5)) { $0.entry = "15" }
    store.send(.answerTapped)
    await store.receive(\.passed)
  }

  @Test func aWrongAnswerDrawsANewQuestion() async {
    let store = TestStore(initialState: ParentGate.State(seed: 1)) {
      ParentGate()
    }
    store.send(.digitTapped(5)) { $0.entry = "5" }
    store.send(.digitTapped(3)) { $0.entry = "53" }
    store.send(.answerTapped) {
      $0.round = 1
      $0.entry = ""
    }
    #expect(store.state.question.words == "What is four times three?")
    store.send(.digitTapped(1)) { $0.entry = "1" }
    store.send(.digitTapped(2)) { $0.entry = "12" }
    store.send(.answerTapped)
    await store.receive(\.passed)
  }

  @Test func theAnswerHoldsTwoDigitsAndDeletes() {
    let store = TestStore(initialState: ParentGate.State(seed: 1)) {
      ParentGate()
    }
    store.send(.digitTapped(4)) { $0.entry = "4" }
    store.send(.digitTapped(2)) { $0.entry = "42" }
    store.send(.digitTapped(7))
    store.send(.deleteTapped) { $0.entry = "4" }
    store.send(.deleteTapped) { $0.entry = "" }
    store.send(.deleteTapped)
  }

  @Test func anEmptyAnswerIsNotChecked() {
    let store = TestStore(initialState: ParentGate.State(seed: 1)) {
      ParentGate()
    }
    store.send(.answerTapped)
    #expect(store.state.round == 0)
  }
}
