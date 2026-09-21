import ComposableArchitecture2
import Content

/// Home / story select — the `Main` artboard: greeting, "Keep going" card, three story rows,
/// "Play on the TV", parent gear.
///
/// TODO(milestone-5): persistence, "Keep going", parent gate + settings.
@Feature public struct Home {
  public init() {}

  public struct State {
    var progress = Content.Progress()
    var stories = StoryLibrary.all

    public init() {}
  }

  public enum Action {
    case storyTapped(Story)
  }

  public var body: some Feature {
    Update { _, _ in }
  }
}
