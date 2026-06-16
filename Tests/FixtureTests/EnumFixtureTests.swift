import Fixture
import Testing

@Fixture
enum Direction {
  case north
  case south
}

@Fixture
enum Status {
  case active(code: Int, label: String)
  case banned
}

@Suite
struct EnumFixtureTests {
  @Test func usesFirstCase() {
    #expect(Direction.fixture == .north)
  }

  @Test func defaultsAssociatedValues() {
    guard case let .active(code, label) = Status.fixture else {
      Issue.record("expected .active")
      return
    }
    #expect(code == 0)
    #expect(label == "")
  }
}

extension Direction: Equatable {}
