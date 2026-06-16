// Only compiled/run when the `Tagged` trait is enabled (e.g. `swift test --traits Tagged`).
#if Tagged
  import Mockable
  import Tagged
  import Testing

  @Mockable
  struct Account {
    typealias ID = Tagged<Account, Int>
    let id: ID
    let name: String
  }

  @Suite
  struct TaggedMockTests {
    @Test func taggedDefaultsViaRawValue() {
      let account = Account.mock()
      // Tagged<_, Int>.mock wraps Int.mock (0).
      #expect(account.id.rawValue == 0)
      #expect(account.name == "")
    }

    @Test func overrideTagged() {
      let account = Account.mock(id: 42)
      #expect(account.id.rawValue == 42)
    }
  }
#endif
