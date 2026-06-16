#if Tagged
  import Fixture
  import Tagged
  import Testing

  @Fixture
  struct Account {
    typealias ID = Tagged<Account, Int>
    let id: ID
    let name: String
  }

  @Suite
  struct TaggedFixtureTests {
    @Test func taggedDefaultsViaRawValue() {
      let account = Account.fixture()
      // Tagged<_, Int>.fixture wraps Int.fixture (0).
      #expect(account.id.rawValue == 0)
      #expect(account.name == "")
    }

    @Test func overrideTagged() {
      let account = Account.fixture(id: 42)
      #expect(account.id.rawValue == 42)
    }
  }
#endif
