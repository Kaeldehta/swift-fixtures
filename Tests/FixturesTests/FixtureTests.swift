import Fixtures
import Foundation
import Testing

@Fixture
struct Team {
  let id: Int
  let name: String
}

@Fixture
struct User {
  let id: Int
  let name: String
  let isAdmin: Bool
  let avatar: URL?
  let team: Team
  let tags: [String]
}

@Suite
struct FixtureTests {
  @Test func defaults() {
    let user = User.fixture()
    #expect(user.id == 0)
    #expect(user.name == "")
    #expect(user.isAdmin == false)
    #expect(user.avatar == nil)
    #expect(user.tags.isEmpty)
    // Nested @Fixture composes via `.fixture`.
    #expect(user.team.id == 0)
    #expect(user.team.name == "")
  }

  @Test func overrideOnlyWhatYouNeed() {
    let user = User.fixture(name: "Alice", isAdmin: true)
    #expect(user.name == "Alice")
    #expect(user.isAdmin == true)
    // Everything else stays at its default.
    #expect(user.id == 0)
    #expect(user.avatar == nil)
  }

  @Test func fixtureConformance() {
    // The macro synthesizes `static var fixture`, satisfying `Fixture`.
    func makeFixture<T: Fixture>(_: T.Type) -> T { .fixture }
    let team = makeFixture(Team.self)
    #expect(team.name == "")
  }
}
