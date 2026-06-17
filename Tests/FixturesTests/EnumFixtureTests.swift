import Fixtures
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

@Fixture
enum Connection: Equatable {
  case connected(host: String)
  @FixtureCase case disconnected
}

@Suite
struct EnumFixtureTests {
  @Test func usesFirstCase() {
    #expect(Direction.fixture == .north)
  }

  @Test func defaultsAssociatedValues() {
    guard case .active(let code, let label) = Status.fixture else {
      Issue.record("expected .active")
      return
    }
    #expect(code == 0)
    #expect(label == "")
  }

  @Test func fixtureCaseMarkerOverridesFirstCase() {
    #expect(Connection.fixture == .disconnected)
  }
}

extension Direction: Equatable {}
