import Foundation
import Mockable
import Testing

@Mockable
struct Team {
  let id: Int
  let name: String
}

@Mockable
struct User {
  let id: Int
  let name: String
  let isAdmin: Bool
  let avatar: URL?
  let team: Team
  let tags: [String]
}

@Suite
struct MockableTests {
  @Test func defaults() {
    let user = User.mock()
    #expect(user.id == 0)
    #expect(user.name == "")
    #expect(user.isAdmin == false)
    #expect(user.avatar == nil)
    #expect(user.tags.isEmpty)
    // Nested @Mockable composes via `.mock`.
    #expect(user.team.id == 0)
    #expect(user.team.name == "")
  }

  @Test func overrideOnlyWhatYouNeed() {
    let user = User.mock(name: "Blob", isAdmin: true)
    #expect(user.name == "Blob")
    #expect(user.isAdmin == true)
    // Everything else stays at its default.
    #expect(user.id == 0)
    #expect(user.avatar == nil)
  }

  @Test func mockableConformance() {
    // The macro synthesizes `static var mock`, satisfying `Mockable`.
    func makeMock<T: Mockable>(_: T.Type) -> T { .mock }
    let team = makeMock(Team.self)
    #expect(team.name == "")
  }
}
