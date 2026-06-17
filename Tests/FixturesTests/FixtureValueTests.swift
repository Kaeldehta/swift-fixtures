import Fixtures
import Testing

@Fixture
struct Profile {
  @FixtureValue("someone@example.com") let email: String
  @FixtureValue(18) let age: Int
  let name: String
}

@Suite
struct FixtureValueTests {
  @Test func usesCustomDefault() {
    let profile = Profile.fixture()
    #expect(profile.email == "someone@example.com")
    #expect(profile.age == 18)
    #expect(profile.name == "")
  }

  @Test func customDefaultIsStillOverridable() {
    let profile = Profile.fixture(email: "other@example.com")
    #expect(profile.email == "other@example.com")
    #expect(profile.age == 18)
  }
}
