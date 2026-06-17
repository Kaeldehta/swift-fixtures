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

// A struct with a custom initializer whose parameters differ from its stored properties:
// `@Fixture` mirrors the initializer instead of the (suppressed) memberwise init.
@Fixture
struct Member {
  let id: Int
  let displayName: String
  @FixtureValue("anonymous") let handle: String

  init(id: Int, displayName: String = "guest", handle: String) {
    self.id = id
    self.displayName = displayName
    self.handle = handle
  }
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

  @Test func customInitDrivesFactory() {
    let member = Member.fixture()
    #expect(member.id == 0)  // no init default → `.fixture`
    #expect(member.displayName == "guest")  // init default is kept
    #expect(member.handle == "anonymous")  // @FixtureValue applies by passthrough

    let overridden = Member.fixture(id: 7, displayName: "Bob")
    #expect(overridden.id == 7)
    #expect(overridden.displayName == "Bob")
    #expect(overridden.handle == "anonymous")
  }
}
